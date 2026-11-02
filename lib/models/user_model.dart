import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// A Firestore user profile identified by an app-generated UUID.
class UserModel {
  const UserModel({
    required this.uuid,
    required this.userType,
    this.name,
    this.email,
    this.phoneNo,
    this.loginProvider,
    this.loginId,
    this.isActive,
    this.photoUrl,
    this.createdAt,
    this.updateAt,
    this.lastSignInAt,
  });

  /// App-generated UUID v1, stable across sign-ins for this account.
  final String uuid;
  final String? name;
  final String? email;
  final String? phoneNo;
  final String? loginProvider;
  final String? loginId;
  final bool? isActive;
  final String? photoUrl;
  final String userType;
  final DateTime? createdAt;
  final DateTime? updateAt;
  final DateTime? lastSignInAt;

  factory UserModel.fromFirebaseUser(User user, {String? uuid}) {
    if (user.uid.isEmpty) {
      throw StateError('Firebase Authentication did not provide a user UID.');
    }
    return UserModel(
      uuid: uuid ?? const Uuid().v1(),
      name: user.displayName,
      email: user.email,
      phoneNo: user.phoneNumber,
      loginProvider: 'google.com',
      loginId: user.uid,
      isActive: true,
      photoUrl: user.photoURL,
      userType: 'primary',
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'name': name,
    'email': email,
    'phoneNo': phoneNo,
    'loginProvider': loginProvider,
    'loginId': loginId,
    'isActive': isActive,
    'photoUrl': photoUrl,
    'userType': userType,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'updateAt': updateAt == null ? null : Timestamp.fromDate(updateAt!),
    'lastSignInAt': lastSignInAt == null
        ? null
        : Timestamp.fromDate(lastSignInAt!),
  };

  factory UserModel.fromMap(Map<String, dynamic> data) {
    final uuid = data['uuid'] as String?;
    if (uuid == null || uuid.isEmpty) {
      throw const FormatException('User document is missing its UUID.');
    }
    return UserModel(
      uuid: uuid,
      name: data['name'] as String?,
      email: data['email'] as String?,
      phoneNo: data['phoneNo'] as String?,
      loginProvider: data['loginProvider'] as String?,
      loginId: data['loginId'] as String?,
      isActive: data['isActive'] as bool?,
      photoUrl: data['photoUrl'] as String?,
      userType: data['userType'] as String? ?? 'primary',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updateAt: (data['updateAt'] as Timestamp?)?.toDate(),
      lastSignInAt: (data['lastSignInAt'] as Timestamp?)?.toDate(),
    );
  }
}
