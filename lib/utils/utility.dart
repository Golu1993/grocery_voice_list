import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Utility {

  static Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version} (${info.buildNumber})";
  }
  static Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse("https://niviclouds.com/");

    await launchUrl(uri);
  }

  static Future<void> shareApp() async {
    const androidUrl =
        'https://play.google.com/store/apps/details?id=com.niviclouds.grocerylistapp';

    const iosUrl = 'https://apps.apple.com/app/id1234567890';

    final appUrl = Platform.isAndroid ? androidUrl : iosUrl;

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
 static Future<void> rateApp() async {
    final review = InAppReview.instance;

    if (await review.isAvailable()) {
      review.requestReview();
    } else {
      review.openStoreListing();
    }
  }
}
