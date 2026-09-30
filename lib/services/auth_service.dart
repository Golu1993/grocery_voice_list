import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static bool _googleInitialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Google login is configured for Android only.');
    }
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Firebase did not initialize. Check the Android Firebase setup, then retry.',
      ),
    );
  }

  static Stream<User?> authStateChanges() async* {
    final events = StreamIterator<User?>(
      FirebaseAuth.instance.authStateChanges(),
    );
    try {
      final hasInitialState = await events.moveNext().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException(
          'Could not check your sign-in status. Please retry.',
        ),
      );
      if (!hasInitialState) {
        throw StateError(
          'The sign-in service stopped before returning a session.',
        );
      }
      yield events.current;
      while (await events.moveNext()) {
        yield events.current;
      }
    } finally {
      await events.cancel();
    }
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static Future<void> signInWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize().timeout(
        const Duration(seconds: 20),
      );
      _googleInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate().timeout(
      const Duration(seconds: 90),
    );
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google did not return an ID token. Check the Android OAuth configuration.',
      );
    }
    await FirebaseAuth.instance
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
        .timeout(const Duration(seconds: 30));
  }

  static Future<void> signOut() async {
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut().timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {
        // Firebase sign-out is the app's access gate and must still run.
      }
    }
    await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 15));
  }

  static String errorMessage(Object error) {
    if (error is TimeoutException) return error.message ?? 'Request timed out.';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'Check your internet connection and try again.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled in Firebase Authentication.';
        case 'invalid-credential':
          return 'Google sign-in could not be verified. Check the app SHA fingerprints in Firebase.';
      }
      return error.message ?? 'Authentication failed. Please try again.';
    }
    if (error is FirebaseException) {
      return error.message ?? 'Firebase is unavailable. Please retry.';
    }
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) return '';
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        return 'Google sign-in is not configured for this app. Check the Android OAuth client and SHA fingerprints.';
      }
      if (error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return 'Google Play services are unavailable on this device.';
      }
      return 'Google sign-in is unavailable. Check Play services, your account, and your connection.';
    }
    if (error is UnsupportedError || error is StateError) {
      return error.toString().replaceFirst(
        RegExp(r'^(Unsupported operation|Bad state): '),
        '',
      );
    }
    return 'Could not start Vocart. Please try again.';
  }
}
