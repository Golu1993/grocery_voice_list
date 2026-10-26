import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/device_details.dart';
import '../models/user_model.dart';
import '../utils/utility.dart';
import 'firestore_query_guard.dart';

/// Shared entry point for the app's Firestore queries.
class FirestoreQuery {
  FirestoreQuery({FirebaseFirestore? firestore, FirestoreQueryGuard? guard})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _guard = guard ?? FirestoreQueryGuard();

  final FirebaseFirestore _firestore;
  final FirestoreQueryGuard _guard;

  /// Stores this installation's device document.
  Future<void> saveDevice({required DeviceDetails device}) async {
    final document = _firestore.collection('devices').doc(device.uuid);
    final existing = await _guard.read(
      () => document.get(const GetOptions(source: Source.server)),
    );
    final details = device.toMap();
    final current = existing.data();
    if (current != null &&
        details.entries.every((entry) => current[entry.key] == entry.value)) {
      return;
    }

    await _guard.write(() => document.set(details, SetOptions(merge: true)));
  }

  /// Updates a device when Firebase rotates its messaging token.
  Future<void> saveFcmToken({
    required String deviceUuid,
    required String fcmToken,
  }) => _guard.write(
    () => _firestore.collection('devices').doc(deviceUuid).set({
      'fcmToken': fcmToken,
    }, SetOptions(merge: true)),
  );

  /// Creates the user profile once and refreshes it on later sign-ins.
  Future<UserModel> saveSignedInUser({required User firebaseUser}) async {
    void ensureSameAccount() {
      if (FirebaseAuth.instance.currentUser?.uid != firebaseUser.uid) {
        throw StateError('The signed-in account changed during profile sync.');
      }
    }

    ensureSameAccount();
    final users = _firestore.collection('users');
    var existing = await _guard.read(
      () => users
          .where('loginId', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server)),
    );

    // Older profiles used authUid. Reuse their application UUID on first sign-in
    // after the schema change instead of creating a second user document.
    if (existing.docs.isEmpty) {
      existing = await _guard.read(
        () => users
            .where('authUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get(const GetOptions(source: Source.server)),
      );
    }

    ensureSameAccount();

    if (existing.docs.isEmpty) {
      final uuid = await Utility.getOrCreateProfileUuid(firebaseUser.uid);
      final user = UserModel.fromFirebaseUser(firebaseUser, uuid: uuid);
      final details = user.toMap()..remove('updateAt');
      await _guard.write(
        () => users.doc(uuid).set({
          ...details,
          'lastSignInAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      return user;
    }

    final document = existing.docs.single;
    await _guard.write(
      () => document.reference.update({
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
      }),
    );
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
  }) => _guard.write(
    () => _firestore.collection('devices').doc(deviceUuid).set({
      'activeUserId': userUuid,
    }, SetOptions(merge: true)),
  );
}
