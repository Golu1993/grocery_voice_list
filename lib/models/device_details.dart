import 'package:device_info_plus/device_info_plus.dart';

/// Common device details that can be used without depending on a platform API.
class DeviceDetails {
  const DeviceDetails({
    required this.platform,
    required this.name,
    required this.model,
    required this.deviceId,
    required this.uuid,
    this.fcmToken,
    this.activeUserId,
  });

  final String platform;
  final String name;
  final String model;

  /// Android ID or iOS identifier for vendor.
  final String deviceId;

  /// App-generated UUID v1, persisted across sign-ins.
  final String uuid;
  final String? fcmToken;
  final String? activeUserId;

  factory DeviceDetails.fromDeviceInfo(
    BaseDeviceInfo info, {
    required String deviceId,
    required String uuid,
    String? fcmToken,
    String? activeUserId,
  }) {
    final id = _requireDeviceId(deviceId);
    if (info is AndroidDeviceInfo) {
      return DeviceDetails(
        platform: 'Android',
        name: info.name.isEmpty ? info.model : info.name,
        model: info.model,
        deviceId: id,
        uuid: uuid,
        fcmToken: fcmToken,
        activeUserId: activeUserId,
      );
    }
    if (info is IosDeviceInfo) {
      return DeviceDetails(
        platform: info.systemName,
        name: info.name,
        model: info.modelName,
        deviceId: id,
        uuid: uuid,
        fcmToken: fcmToken,
        activeUserId: activeUserId,
      );
    }
    throw UnsupportedError('Unsupported device platform: ${info.runtimeType}');
  }

  static String _requireDeviceId(String? id) {
    if (id == null || id.trim().isEmpty) {
      throw StateError('A platform device ID is unavailable.');
    }
    return id;
  }

  Map<String, Object?> toMap() => {
    'platform': platform,
    'name': name,
    'model': model,
    'deviceId': deviceId,
    'uuid': uuid,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (activeUserId != null) 'activeUserId': activeUserId,
  };
}
