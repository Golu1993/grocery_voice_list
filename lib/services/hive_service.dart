import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Local persistence for saved logins and stable profile and device identities.
/// Firebase Auth remains the source of truth for whether a user is signed in.
class HiveService {
  static const _loginSessionBox = 'vocart_login_session';
  static const _activeLoginKey = 'active_login';
  static const _deviceIdentityBox = 'vocart_device_identity';
  static const _profileIdentityBox = 'vocart_profile_identity';
  static const _uuidKey = 'uuid';

  /// Loads the saved login before the app builds its first screen.
  static Future<void> initialize({String? directory}) async {
    if (directory == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(directory);
    }
    await Hive.openBox<String>(_loginSessionBox);
  }

  static String? readProfileUuid({required String authUid}) {
    final box = Hive.box<String>(_loginSessionBox);
    final saved = box.get(_activeLoginKey);
    if (saved == null) return null;

    try {
      final data = jsonDecode(saved);
      if (data is! Map<String, dynamic> || data['authUid'] != authUid) {
        return null;
      }
      final profileUuid = data['profileUuid'];
      return profileUuid is String && profileUuid.isNotEmpty
          ? profileUuid
          : null;
    } on FormatException {
      return null;
    }
  }

  static Future<void> saveLogin({
    required String authUid,
    required String profileUuid,
  }) async {
    if (authUid.isEmpty || profileUuid.isEmpty) {
      throw ArgumentError('A signed-in user and profile UUID are required.');
    }
    final box = await Hive.openBox<String>(_loginSessionBox);
    await box.put(
      _activeLoginKey,
      jsonEncode({'authUid': authUid, 'profileUuid': profileUuid}),
    );
  }

  static Future<void> clearLogin() async {
    final box = await Hive.openBox<String>(_loginSessionBox);
    await box.delete(_activeLoginKey);
  }

  /// Keeps a new profile's document ID stable if a timed-out write is retried.
  static Future<String> getOrCreateProfileUuid(String authUid) async {
    if (authUid.isEmpty) throw ArgumentError.value(authUid, 'authUid');
    final box = await Hive.openBox<String>(_profileIdentityBox);
    final saved = box.get(authUid);
    if (saved != null && saved.isNotEmpty) return saved;

    final uuid = const Uuid().v1();
    await box.put(authUid, uuid);
    return uuid;
  }

  /// Returns the locally persisted UUID v1 for this app installation.
  static Future<String> getOrCreateDeviceUuid() async {
    final box = await Hive.openBox<String>(_deviceIdentityBox);
    final saved = box.get(_uuidKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final uuid = const Uuid().v1();
    await box.put(_uuidKey, uuid);
    return uuid;
  }

  static Future<void> close() => Hive.close();
}
