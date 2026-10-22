import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/device_details.dart';
import '../models/user_model.dart';

/// Shared entry point for the app's Firestore queries.
class FirestoreQuery {
  FirestoreQuery({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stores this installation's device document.
  Future<void> saveDevice({required DeviceDetails device}) async {
    final document = _firestore.collection('devices').doc(device.uuid);
    final existing = await document.get(
      const GetOptions(source: Source.server),
    );
    final details = device.toMap();
    final current = existing.data();
    if (current != null && details.keys.every(current.containsKey)) {
      return;
    }

    await document.set(details, SetOptions(merge: true));
  }

  /// Creates the user profile once and refreshes it on later sign-ins.
  Future<UserModel> saveSignedInUser({required User firebaseUser}) async {
    final users = _firestore.collection('users');
    var existing = await users
        .where('loginId', isEqualTo: firebaseUser.uid)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    // Older profiles used authUid. Reuse their application UUID on first sign-in
    // after the schema change instead of creating a second user document.
    if (existing.docs.isEmpty) {
      existing = await users
          .where('authUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server));
    }

    if (existing.docs.isEmpty) {
      final user = UserModel.fromFirebaseUser(firebaseUser);
      await users.doc(user.uuid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
      });
      return user;
    }

    final document = existing.docs.single;
    await document.reference.update({
      'name': firebaseUser.displayName,
      'email': firebaseUser.email,
      'phoneNo': firebaseUser.phoneNumber,
      'photoUrl': firebaseUser.photoURL,
      'loginProvider': 'google.com',
      'loginId': firebaseUser.uid,
      'devices': FieldValue.delete(),
      'updateAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
      'authUid': FieldValue.delete(),
    });
    final data = document.data();
    return UserModel.fromMap({
      ...data,
      'name': firebaseUser.displayName,
      'email': firebaseUser.email,
      'phoneNo': firebaseUser.phoneNumber,
      'photoUrl': firebaseUser.photoURL,
      'loginProvider': 'google.com',
      'loginId': firebaseUser.uid,
    });
  }

  /// Links this installation to the currently signed-in app user.
  Future<void> setActiveUserId({
    required String deviceUuid,
    required String userUuid,
  }) => _firestore.collection('devices').doc(deviceUuid).set({
    'activeUserId': userUuid,
  }, SetOptions(merge: true));
}
