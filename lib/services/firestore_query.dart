import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/device_details.dart';
import '../models/firestore_order.dart';
import '../models/grocery_item.dart';
import '../models/user_model.dart';

/// Shared entry point for the app's Firestore queries.
class FirestoreQuery {
  FirestoreQuery({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stores this installation's device document.
  Future<void> saveDevice({required DeviceDetails device}) async {
    final documentId = device.uuid;
    await _firestore.collection('devices').doc(documentId).set({
      ...device.toMap(),
    });
  }

  /// Creates the user profile once, then adds this device on later sign-ins.
  Future<UserModel> saveSignedInUser({
    required User firebaseUser,
    required String deviceUuid,
  }) async {
    final users = _firestore.collection('users');
    final existing = await users
        .where('authUid', isEqualTo: firebaseUser.uid)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    if (existing.docs.isEmpty) {
      final user = UserModel.fromFirebaseUser(
        firebaseUser,
        deviceUuid: deviceUuid,
      );
      await users.doc(user.uuid).set({
        ...user.toMap(),
        'authUid': firebaseUser.uid,
      });
      return user;
    }

    final document = existing.docs.single;
    await existing.docs.single.reference.update({
      'devices': FieldValue.arrayUnion([deviceUuid]),
      'lastSignInAt': firebaseUser.metadata.lastSignInTime == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(firebaseUser.metadata.lastSignInTime!),
    });
    final data = document.data();
    final devices =
        (data['devices'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet()
          ..add(deviceUuid);
    return UserModel.fromMap({...data, 'devices': devices.toList()});
  }

  Future<FirestoreOrder> ensureActiveOrder(UserModel user) async {
    final activeUuid = user.activeOrder;
    if (activeUuid != null) {
      final active = await _firestore
          .collection('orders')
          .doc(activeUuid)
          .get();
      if (active.exists) return FirestoreOrder.fromDocument(active);
    }
    return startNewOrder(userUuid: user.uuid);
  }

  Future<FirestoreOrder> startNewOrder({
    required String userUuid,
    String? previousOrderUuid,
  }) async {
    final uuid = const Uuid().v1();
    final order = _firestore.collection('orders').doc(uuid);
    final user = _firestore.collection('users').doc(userUuid);
    final batch = _firestore.batch();
    if (previousOrderUuid != null) {
      batch.update(_firestore.collection('orders').doc(previousOrderUuid), {
        'completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userUuid,
      });
    }
    batch.set(order, {
      'uuid': uuid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': userUuid,
      'updatedBy': userUuid,
      'completed': false,
      'items': <Map<String, dynamic>>[],
    });
    batch.update(user, {
      'orders': FieldValue.arrayUnion([uuid]),
      'activeOrder': uuid,
    });
    await batch.commit();
    return FirestoreOrder(
      uuid: uuid,
      createdBy: userUuid,
      updatedBy: userUuid,
      items: const [],
    );
  }

  Future<FirestoreOrder> getOrder(String uuid) async {
    final order = await _firestore.collection('orders').doc(uuid).get();
    return FirestoreOrder.fromDocument(order);
  }

  Future<List<FirestoreOrder>> getOrders(String userUuid) async {
    final results = await _firestore
        .collection('orders')
        .where('createdBy', isEqualTo: userUuid)
        .get();
    final orders = results.docs.map(FirestoreOrder.fromDocument).toList();
    orders.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return orders;
  }

  Future<void> saveOrderItems({
    required String orderUuid,
    required String userUuid,
    required Iterable<GroceryItem> items,
  }) => _firestore.collection('orders').doc(orderUuid).update({
    'items': FirestoreOrder.encodeItems(items),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': userUuid,
  });

  Future<void> deleteOrder({
    required String orderUuid,
    required String userUuid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('orders').doc(orderUuid));
    batch.update(_firestore.collection('users').doc(userUuid), {
      'orders': FieldValue.arrayRemove([orderUuid]),
    });
    await batch.commit();
  }
}
