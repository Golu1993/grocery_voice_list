import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';

enum FirestoreQueryFailureKind {
  offline,
  timeout,
  temporary,
  permissionDenied,
  unauthenticated,
  invalidRequest,
  other,
}

class FirestoreQueryFailure implements Exception {
  const FirestoreQueryFailure(this.kind);

  final FirestoreQueryFailureKind kind;

  bool get canRetry =>
      kind == FirestoreQueryFailureKind.offline ||
      kind == FirestoreQueryFailureKind.timeout ||
      kind == FirestoreQueryFailureKind.temporary ||
      kind == FirestoreQueryFailureKind.other;

  bool get canRetryAutomatically =>
      kind == FirestoreQueryFailureKind.timeout ||
      kind == FirestoreQueryFailureKind.temporary;

  String get message => switch (kind) {
    FirestoreQueryFailureKind.offline =>
      'No internet connection. Connect and try again.',
    FirestoreQueryFailureKind.timeout =>
      'The request took too long. Please try again.',
    FirestoreQueryFailureKind.temporary =>
      'The service is temporarily unavailable. Please try again.',
    FirestoreQueryFailureKind.permissionDenied =>
      'This account does not have permission to access this data.',
    FirestoreQueryFailureKind.unauthenticated =>
      'Your sign-in is no longer valid. Please sign in again.',
    FirestoreQueryFailureKind.invalidRequest =>
      'The request could not be completed. Please contact support.',
    FirestoreQueryFailureKind.other => 'Could not reach Firestore right now.',
  };

  @override
  String toString() => message;

  static FirestoreQueryFailure from(Object error) {
    if (error is FirestoreQueryFailure) return error;
    if (error is TimeoutException) {
      return const FirestoreQueryFailure(FirestoreQueryFailureKind.timeout);
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'unavailable' || 'deadline-exceeded' || 'aborted' =>
          const FirestoreQueryFailure(FirestoreQueryFailureKind.temporary),
        'permission-denied' => const FirestoreQueryFailure(
          FirestoreQueryFailureKind.permissionDenied,
        ),
        'unauthenticated' => const FirestoreQueryFailure(
          FirestoreQueryFailureKind.unauthenticated,
        ),
        'invalid-argument' || 'failed-precondition' || 'not-found' =>
          const FirestoreQueryFailure(FirestoreQueryFailureKind.invalidRequest),
        _ => const FirestoreQueryFailure(FirestoreQueryFailureKind.other),
      };
    }
    return const FirestoreQueryFailure(FirestoreQueryFailureKind.other);
  }
}

/// Checks network connectivity and puts a deadline on server operations.
/// Only reads are automatically retried; a timed-out write may still finish.
class FirestoreQueryGuard {
  FirestoreQueryGuard({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  static const _readTimeout = Duration(seconds: 12);
  static const _writeTimeout = Duration(seconds: 15);
  static const _connectionCheckTimeout = Duration(seconds: 3);
  static const _readRetryDelay = Duration(seconds: 1);
  static final _offlineFailures =
      StreamController<FirestoreQueryFailure>.broadcast();

  static Stream<FirestoreQueryFailure> get offlineFailures =>
      _offlineFailures.stream;

  final Connectivity _connectivity;

  Future<T> read<T>(Future<T> Function() query) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      await _checkConnectivity();
      try {
        return await query().timeout(_readTimeout);
      } catch (error) {
        final failure = FirestoreQueryFailure.from(error);
        if (attempt == 1 || !failure.canRetryAutomatically) throw failure;
      }
      await Future<void>.delayed(_readRetryDelay);
    }
    throw StateError('The query retry loop ended without a result.');
  }

  Future<T> write<T>(Future<T> Function() query) async {
    await _checkConnectivity();
    try {
      return await query().timeout(_writeTimeout);
    } catch (error) {
      throw FirestoreQueryFailure.from(error);
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connections = await _connectivity.checkConnectivity().timeout(
        _connectionCheckTimeout,
      );
      if (connections.isEmpty ||
          connections.every(
            (connection) => connection == ConnectivityResult.none,
          )) {
        throw _offlineFailure();
      }
    } on FirestoreQueryFailure {
      rethrow;
    } catch (_) {
      // Let the Firestore operation report connectivity when this check fails.
    }
  }

  FirestoreQueryFailure _offlineFailure() {
    const failure = FirestoreQueryFailure(FirestoreQueryFailureKind.offline);
    _offlineFailures.add(failure);
    return failure;
  }
}
