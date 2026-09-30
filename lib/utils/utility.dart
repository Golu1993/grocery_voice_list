import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/device_details.dart';

class Utility {
  static const _deviceIdentityBox = 'vocart_device_identity';
  static const _uuidKey = 'uuid';

  /// Returns the Android ID or iOS identifier for vendor.
  /// Throws if the platform cannot provide an identifier.
  static Future<String> getDeviceId() async {
    final info = await DeviceInfoPlugin().deviceInfo;
    return _deviceIdFrom(info);
  }

  /// Returns the locally persisted UUID v1 for this app installation.
  static Future<String> getUniqueId() => _getOrCreateUuid();

  /// Returns the current device's common details on supported platforms.
  static Future<DeviceDetails> getDeviceDetails({String? fcmToken}) async {
    final info = await DeviceInfoPlugin().deviceInfo;
    final deviceId = await _deviceIdFrom(info);
    final uuid = await getUniqueId();
    return DeviceDetails.fromDeviceInfo(
      info,
      deviceId: deviceId,
      uuid: uuid,
      fcmToken: fcmToken,
    );
  }

  static Future<String> _getOrCreateUuid() async {
    final box = await Hive.openBox<String>(_deviceIdentityBox);
    final saved = box.get(_uuidKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final uuid = const Uuid().v1();
    await box.put(_uuidKey, uuid);
    return uuid;
  }

  static Future<String> _deviceIdFrom(BaseDeviceInfo info) async {
    if (info is AndroidDeviceInfo) {
      final id = await const AndroidId().getId();
      if (id == null || id.trim().isEmpty) {
        throw StateError('Android ID is unavailable on this device.');
      }
      return id;
    }
    if (info is IosDeviceInfo) {
      final id = info.identifierForVendor;
      if (id == null || id.trim().isEmpty) {
        throw StateError(
          'iOS vendor ID is unavailable. Try again after unlocking the device.',
        );
      }
      return id;
    }
    throw UnsupportedError('Device ID is unavailable on ${info.runtimeType}.');
  }

  static Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse("https://niviclouds.com/");

    await launchUrl(uri);
  }

  static Future<void> shareApp() async {
    const androidUrl =
        'https://play.google.com/store/apps/details?id=com.niviclouds.groceryvoicelist';

    const iosUrl = 'https://apps.apple.com/app/id1234567890';

    final appUrl = Platform.isAndroid ? androidUrl : iosUrl;
    if (Platform.isAndroid) {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '''
Check out this app!
Easily create and manage your grocery lists.
Download it here:
$appUrl
''',
        ),
      );
    }
  }

  static Future<void> rateApp() async {
    final review = InAppReview.instance;

    if (await review.isAvailable()) {
      review.requestReview();
    } else {
      review.openStoreListing();
    }
  }
}
