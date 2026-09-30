import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// A user profile whose orders are stored in separate Firestore documents.
class UserModel {
  const UserModel({
    required this.uuid,
    required this.userType,
    this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.lastSignInAt,
    this.devices = const [],
    this.orders = const [],
    this.activeOrder,
    this.secondaryUsers = const [],
  });

  /// App-generated UUID v1, stable across sign-ins for this account.
  final String uuid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String userType;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final List<String> devices;
  final List<String> orders;
  final String? activeOrder;
  final List<String> secondaryUsers;

  factory UserModel.fromFirebaseUser(User user, {required String deviceUuid}) {
    if (user.uid.isEmpty) {
      throw StateError('Firebase Authentication did not provide a user UID.');
    }
    return UserModel(
      uuid: const Uuid().v1(),
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      userType: 'primary',
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
      devices: [deviceUuid],
    );
  }

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'userType': userType,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'lastSignInAt': lastSignInAt == null
        ? null
        : Timestamp.fromDate(lastSignInAt!),
    'devices': devices,
    'orders': orders,
    'activeOrder': activeOrder,
    'secondaryUsers': secondaryUsers,
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
      photoUrl: data['photoUrl'] as String?,
      userType: data['userType'] as String? ?? 'primary',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSignInAt: (data['lastSignInAt'] as Timestamp?)?.toDate(),
      devices: (data['devices'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      orders: (data['orders'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      activeOrder: data['activeOrder'] as String?,
      secondaryUsers: (data['secondaryUsers'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}
