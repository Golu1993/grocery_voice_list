import 'package:firebase_messaging/firebase_messaging.dart';

/// Access to this installation's Firebase Cloud Messaging token.
///
/// Call after Firebase.initializeApp() has completed.
class FirebaseService {
  FirebaseService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<String?> getFcmToken({bool requestPermission = false}) async {
    if (requestPermission) {
      await _messaging.requestPermission();
    }
    return _messaging.getToken();
  }
}
