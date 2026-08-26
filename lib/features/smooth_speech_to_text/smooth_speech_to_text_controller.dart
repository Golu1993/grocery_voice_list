import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'smooth_speech_recognizer.dart';
import 'smooth_speech_state.dart';

/// State and session orchestration for the standalone dictation widget.
class SmoothSpeechToTextController extends ChangeNotifier {
  SmoothSpeechToTextController({
    SmoothSpeechRecognizer? recognizer,
    this.localeId,
    this.onFinalPhrase,
  }) : _recognizer = recognizer ?? NativeSmoothSpeechRecognizer();

  static const _watchdogInterval = Duration(milliseconds: 300);
  static const _restartDelay = Duration(milliseconds: 350);
  static const _errorRecoveryDelay = Duration(milliseconds: 650);

  final SmoothSpeechRecognizer _recognizer;
  final ValueNotifier<double> soundLevel = ValueNotifier(0);

  String? localeId;
  ValueChanged<String>? onFinalPhrase;
  SmoothSpeechState _state = SmoothSpeechState.idle;
  String _committedText = '';
  String _partialText = '';
  String _errorMessage = '';
  Timer? _watchdog;
  DateTime _restartAfter = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wantsToListen = false;
  bool _sessionStarting = false;
  bool _disposed = false;
  int _generation = 0;
  int _sessionId = 0;
  int _startFailures = 0;
  bool _finalDeliveredForSession = false;
  double _minimumLevel = double.infinity;
  double _maximumLevel = double.negativeInfinity;

  SmoothSpeechState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isActive => _state.isActive;
  bool get hasText => transcript.isNotEmpty;

  String get transcript {
    if (_committedText.isEmpty) return _partialText.trim();
    if (_partialText.trim().isEmpty) return _committedText;
    return '$_committedText ${_partialText.trim()}';
  }

  Future<void> start() async {
    if (_disposed || _wantsToListen || _sessionStarting) return;

    final generation = ++_generation;
    _wantsToListen = true;
    _errorMessage = '';
    _setState(SmoothSpeechState.starting);

    final available = await _recognizer.initialize(onError: _handleError);
    if (_disposed || generation != _generation || !_wantsToListen) return;
    if (!available) {
      _wantsToListen = false;
      _errorMessage = 'Microphone and speech recognition access are required.';
      _setState(SmoothSpeechState.unavailable);
      return;
    }

    _watchdog ??= Timer.periodic(_watchdogInterval, (_) => _checkSession());
    await _beginSession(generation);
  }

  Future<void> _beginSession(int generation) async {
    if (_disposed ||
        generation != _generation ||
        !_wantsToListen ||
        _sessionStarting ||
        _recognizer.isListening) {
      return;
    }

    _sessionStarting = true;
    _setState(SmoothSpeechState.starting);
    final sessionId = ++_sessionId;
    _finalDeliveredForSession = false;

    try {
      await _recognizer.listen(
        localeId: localeId,
        onResult: (words, isFinal) {
          if (_disposed ||
              generation != _generation ||
              sessionId != _sessionId ||
              !_wantsToListen) {
            return;
          }
          _handleResult(words, isFinal, sessionId);
        },
        onSoundLevel: (level) {
          if (_disposed ||
              generation != _generation ||
              sessionId != _sessionId ||
              !_wantsToListen) {
            return;
          }
          _handleSoundLevel(level);
        },
      );
      _startFailures = 0;
      _restartAfter = DateTime.now().add(_restartDelay);
      if (!_disposed && generation == _generation && _wantsToListen) {
        _setState(SmoothSpeechState.listening);
      }
    } catch (_) {
      _startFailures++;
      _restartAfter = DateTime.now().add(_restartDelay);
      if (_startFailures >= 3) {
        _wantsToListen = false;
        _errorMessage = 'Speech recognition could not be started.';
        _setState(SmoothSpeechState.error);
      }
    } finally {
      _sessionStarting = false;
    }
  }

  void _checkSession() {
    if (_disposed || !_wantsToListen || _sessionStarting) return;
    if (_recognizer.isListening || DateTime.now().isBefore(_restartAfter)) {
      return;
    }

    _finalizePendingPhrase();
    soundLevel.value = 0;
    unawaited(_beginSession(_generation));
  }

  void _handleResult(String words, bool isFinal, int sessionId) {
    _partialText = words.trim();
    if (isFinal) _finalizePendingPhrase(notify: false, sessionId: sessionId);
    _errorMessage = '';
    notifyListeners();
  }

  void _handleError(String error) {
    if (_disposed || !_wantsToListen) return;
    final transient = _isRecoverableSessionError(error);

    if (transient) {
      // Android can report error_client/error_busy while its previous short
      // utterance is closing. That is a normal continuous-listening handoff,
      // not a user-facing failure. Preserve the last words, fully release the
      // old session, and let the watchdog open the next one after a brief
      // native-recognizer cooldown.
      _finalizePendingPhrase();
      _errorMessage = '';
      soundLevel.value = 0;
      _restartAfter = DateTime.now().add(_errorRecoveryDelay);
      if (_state != SmoothSpeechState.starting) {
        _setState(SmoothSpeechState.listening);
      }
      unawaited(_recognizer.cancel());
      return;
    }

    _wantsToListen = false;
    _watchdog?.cancel();
    _watchdog = null;
    soundLevel.value = 0;
    _errorMessage = _friendlyError(error);
    _setState(SmoothSpeechState.error);
  }

  bool _isRecoverableSessionError(String error) {
    return error.contains('error_no_match') ||
        error.contains('error_speech_timeout') ||
        error.contains('error_busy') ||
        error.contains('error_client') ||
        error.contains('error_server_disconnected');
  }

  void _handleSoundLevel(double level) {
    _minimumLevel = math.min(_minimumLevel, level);
    _maximumLevel = math.max(_maximumLevel, level);
    final range = _maximumLevel - _minimumLevel;
    soundLevel.value = range < 0.5
        ? 0.12
        : ((level - _minimumLevel) / range).clamp(0.0, 1.0);
  }

  /// Stops recognition and optionally submits the latest partial words.
  ///
  /// Native recognizers do not always send a final result before a user taps
  /// Done. Grocery voice entry opts into [submitPendingPhrase] so the last
  /// spoken item is not silently lost, while general dictation can still stop
  /// without treating an unfinished phrase as a command.
  Future<void> stop({bool submitPendingPhrase = false}) async {
    if (_disposed || (!_wantsToListen && !_state.isActive)) return;
    _wantsToListen = false;
    ++_generation;
    _watchdog?.cancel();
    _watchdog = null;
    if (submitPendingPhrase) {
      _finalizePendingPhrase();
    } else {
      _commitPartial();
    }
    soundLevel.value = 0;
    _setState(SmoothSpeechState.stopping);

    await _recognizer.stop();
    if (!_disposed) _setState(SmoothSpeechState.idle);
  }

  void clear() {
    if (_disposed) return;
    _committedText = '';
    _partialText = '';
    _errorMessage = '';
    notifyListeners();
  }

  void replaceText(String text) {
    if (_disposed) return;
    _committedText = text.trim();
    _partialText = '';
    notifyListeners();
  }

  void _commitPartial({bool notify = true}) {
    final phrase = _partialText.trim();
    if (phrase.isNotEmpty) {
      _committedText = _appendWithoutRepeatedWords(_committedText, phrase);
    }
    _partialText = '';
    if (notify && !_disposed) notifyListeners();
  }

  void _finalizePendingPhrase({bool notify = true, int? sessionId}) {
    final phrase = _partialText.trim();
    if (phrase.isEmpty) return;

    _commitPartial(notify: false);
    final belongsToCurrentSession =
        sessionId == null || sessionId == _sessionId;
    if (belongsToCurrentSession && !_finalDeliveredForSession) {
      _finalDeliveredForSession = true;
      onFinalPhrase?.call(phrase);
    }
    if (notify && !_disposed) notifyListeners();
  }

  String _appendWithoutRepeatedWords(String existing, String phrase) {
    if (existing.isEmpty) return phrase;

    final previousWords = existing.split(RegExp(r'\s+'));
    final newWords = phrase.split(RegExp(r'\s+'));
    final maximumOverlap = math.min(
      12,
      math.min(previousWords.length, newWords.length),
    );
    var overlap = 0;

    for (var length = maximumOverlap; length > 0; length--) {
      var matches = true;
      for (var index = 0; index < length; index++) {
        final oldWord = previousWords[previousWords.length - length + index];
        final newWord = newWords[index];
        if (_wordKey(oldWord) != _wordKey(newWord)) {
          matches = false;
          break;
        }
      }
      if (matches) {
        overlap = length;
        break;
      }
    }

    final addition = newWords.skip(overlap).join(' ');
    return addition.isEmpty ? existing : '$existing $addition';
  }

  String _wordKey(String word) {
    return word.toLowerCase().replaceAll(RegExp(r'[.,!?;:\u0964\u0965]+$'), '');
  }

  String _friendlyError(String error) {
    if (error.contains('permission') || error.contains('not_allowed')) {
      return 'Allow microphone and speech access in device settings.';
    }
    if (error.contains('network')) return 'Speech recognition is offline.';
    return 'Speech recognition stopped unexpectedly.';
  }

  void _setState(SmoothSpeechState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _wantsToListen = false;
    ++_generation;
    _watchdog?.cancel();
    soundLevel.dispose();
    _recognizer.dispose();
    super.dispose();
  }
}
