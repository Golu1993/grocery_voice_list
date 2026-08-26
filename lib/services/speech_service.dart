import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

typedef OnResult = void Function(String text, bool isFinal);
typedef OnStatus = void Function(String status);
typedef OnError = void Function(String error);

class SpeechService {
  static const _initialPause = Duration(seconds: 5);
  static const _speechPause = Duration(milliseconds: 900);
  static const _finalTimeout = Duration(milliseconds: 150);

  final SpeechToText _stt = SpeechToText();
  bool _isAvailable = false;
  Future<bool>? _initialization;
  // Android's recognizer API can select a dedicated local recognizer and
  // transparently fall back below. iOS does not expose a reliable capability
  // check through this package, so retain its normal system-selected engine.
  bool _preferOnDevice = defaultTargetPlatform == TargetPlatform.android;
  bool _usingOnDevice = false;
  bool _fallingBackToNetwork = false;
  bool _receivedWords = false;
  bool _sessionActive = false;
  String? _activeLocaleId;

  bool get isAvailable => _isAvailable;
  bool get isListening => _stt.isListening;

  Future<bool> initialize() async {
    if (_isAvailable) return true;
    return _initialization ??= _initializeOnce();
  }

  Future<bool> _initializeOnce() async {
    try {
      _isAvailable = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
        finalTimeout: _finalTimeout,
        options: [SpeechToText.androidNoBluetooth],
      );
      return _isAvailable;
    } finally {
      if (!_isAvailable) _initialization = null;
    }
  }

  OnResult? _onResult;
  OnStatus? _onStatusCallback;
  OnError? _onErrorCallback;

  void _onError(SpeechRecognitionError error) {
    if (_usingOnDevice &&
        _sessionActive &&
        !_receivedWords &&
        _isLocalRecognitionUnavailable(error.errorMsg)) {
      _preferOnDevice = false;
      _fallingBackToNetwork = true;
      unawaited(_restartWithNetwork());
      return;
    }
    _onErrorCallback?.call(error.errorMsg);
  }

  void _onStatus(String status) {
    if (_fallingBackToNetwork) return;
    _onStatusCallback?.call(status);
  }

  Future<void> startListening({
    required OnResult onResult,
    OnStatus? onStatus,
    OnError? onError,
    String? localeId,
  }) async {
    if (!_isAvailable) await initialize();
    if (!_isAvailable) {
      onError?.call('Speech recognition not available');
      return;
    }

    _onResult = onResult;
    _onStatusCallback = onStatus;
    _onErrorCallback = onError;
    _activeLocaleId = localeId;
    _receivedWords = false;
    _sessionActive = true;

    try {
      await _listen(onDevice: _preferOnDevice);
    } catch (error) {
      if (_preferOnDevice && _isLocalRecognitionUnavailable(error.toString())) {
        _preferOnDevice = false;
        await _listen(onDevice: false);
      } else {
        _onErrorCallback?.call(error.toString());
      }
    }
  }

  Future<void> _listen({required bool onDevice}) async {
    _usingOnDevice = onDevice;
    var speechDetected = false;
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) _receivedWords = true;
        if (!speechDetected && words.isNotEmpty && !result.finalResult) {
          speechDetected = true;
          // Give the user time to begin, then use a short natural pause to
          // finish a grocery command without waiting several seconds.
          if (_stt.isListening) _stt.changePauseFor(_speechPause);
        }
        _onResult?.call(words, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        localeId: _activeLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: _initialPause,
        partialResults: true,
        cancelOnError: false,
        onDevice: onDevice,
        listenMode: ListenMode.deviceDefault,
        autoPunctuation: false,
      ),
    );
  }

  Future<void> _restartWithNetwork() async {
    // Android reports a missing local language pack asynchronously. Let that
    // session close, then retry once with its normal network-capable engine.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!_sessionActive) {
      _fallingBackToNetwork = false;
      return;
    }
    if (_stt.isListening) await _stt.cancel();
    if (!_sessionActive) {
      _fallingBackToNetwork = false;
      return;
    }
    try {
      await _listen(onDevice: false);
      _fallingBackToNetwork = false;
    } catch (error) {
      _fallingBackToNetwork = false;
      _onErrorCallback?.call(error.toString());
    }
  }

  bool _isLocalRecognitionUnavailable(String error) {
    return error.contains('onDeviceError') ||
        error.contains('on device recognition is not supported') ||
        error.contains('error_language_not_supported') ||
        error.contains('error_language_unavailable');
  }

  Future<void> stopListening() async {
    _sessionActive = false;
    _fallingBackToNetwork = false;
    await _stt.stop();
  }

  Future<void> cancelListening() async {
    _sessionActive = false;
    _fallingBackToNetwork = false;
    await _stt.cancel();
  }

  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) await initialize();
    return _stt.locales();
  }

  void dispose() {
    _sessionActive = false;
    _stt.cancel();
  }
}
