import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SmoothSpeechResultCallback = void Function(String words, bool isFinal);
typedef SmoothSpeechErrorCallback = void Function(String error);
typedef SmoothSpeechLevelCallback = void Function(double level);

/// Platform boundary for the standalone smooth speech-to-text feature.
abstract class SmoothSpeechRecognizer {
  bool get isListening;

  Future<bool> initialize({required SmoothSpeechErrorCallback onError});

  Future<void> listen({
    required SmoothSpeechResultCallback onResult,
    required SmoothSpeechLevelCallback onSoundLevel,
    String? localeId,
  });

  Future<void> stop();

  Future<void> cancel();

  void dispose();
}

/// Native implementation used only by [SmoothSpeechToTextController].
class NativeSmoothSpeechRecognizer implements SmoothSpeechRecognizer {
  static final NativeSmoothSpeechRecognizer _instance =
      NativeSmoothSpeechRecognizer._();

  factory NativeSmoothSpeechRecognizer() => _instance;

  NativeSmoothSpeechRecognizer._();

  final SpeechToText _speech = SpeechToText();

  SmoothSpeechErrorCallback? _onError;
  bool _initialized = false;
  bool _ownsSession = false;
  final Map<String, String?> _resolvedLocales = {};

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize({required SmoothSpeechErrorCallback onError}) async {
    _onError = onError;
    if (_initialized || _speech.isAvailable) {
      _initialized = true;
      return true;
    }

    _initialized = await _speech.initialize(
      debugLogging: false,
      finalTimeout: const Duration(milliseconds: 250),
      onError: _handleNativeError,
      options: [SpeechToText.androidNoBluetooth],
    );
    return _initialized;
  }

  void _handleNativeError(SpeechRecognitionError error) {
    _onError?.call(error.errorMsg);
  }

  @override
  Future<void> listen({
    required SmoothSpeechResultCallback onResult,
    required SmoothSpeechLevelCallback onSoundLevel,
    String? localeId,
  }) async {
    if (!_initialized) {
      throw StateError('Smooth speech recognizer is not initialized');
    }

    // Locale identifiers use underscores on some Android recognizers and
    // hyphens on Apple platforms. Resolve the requested locale against the
    // device list so English (India) does not silently fall back or fail.
    final resolvedLocaleId = await _resolveLocaleId(localeId);

    // A device exposes only one native microphone recognition session. Close
    // a stale session before starting this standalone widget's session.
    if (_speech.isListening) await _speech.cancel();

    _ownsSession = true;
    var speechDetected = false;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (!speechDetected && words.isNotEmpty) {
          speechDetected = true;
          // The initial timeout gives the user enough time to begin. Only
          // after speech starts do we use the short pause that separates one
          // grocery command from the next.
          if (_speech.isListening && !result.finalResult) {
            _speech.changePauseFor(const Duration(milliseconds: 1800));
          }
        }
        onResult(words, result.finalResult);
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        localeId: resolvedLocaleId,
        partialResults: true,
        cancelOnError: false,
        onDevice: false,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        // Do not finish before the user has had a reasonable chance to begin.
        // This changes to 1.8 seconds as soon as the first words arrive.
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(minutes: 2),
      ),
    );
  }

  Future<String?> _resolveLocaleId(String? requested) async {
    if (requested == null || requested.trim().isEmpty) return null;
    if (_resolvedLocales.containsKey(requested)) {
      return _resolvedLocales[requested];
    }

    try {
      final locales = await _speech.locales();
      final requestedKey = _localeKey(requested);
      for (final locale in locales) {
        if (_localeKey(locale.localeId) == requestedKey) {
          return _resolvedLocales[requested] = locale.localeId;
        }
      }

      // Prefer another regional variant of the requested language over an
      // invalid locale identifier. If none is installed, the system default
      // is the safest fallback.
      final language = requestedKey.split('_').first;
      for (final locale in locales) {
        if (_localeKey(locale.localeId).split('_').first == language) {
          return _resolvedLocales[requested] = locale.localeId;
        }
      }
    } catch (_) {
      // Some platform speech services cannot enumerate locales even though
      // recognition itself is available. Let the device choose its default.
    }

    _resolvedLocales[requested] = null;
    return null;
  }

  String _localeKey(String localeId) =>
      localeId.trim().toLowerCase().replaceAll('-', '_');

  @override
  Future<void> stop() async {
    if (!_ownsSession) return;
    _ownsSession = false;
    await _speech.stop();
  }

  @override
  Future<void> cancel() async {
    if (!_ownsSession && !_speech.isListening) return;
    _ownsSession = false;
    await _speech.cancel();
  }

  @override
  void dispose() {
    if (_ownsSession && _speech.isListening) {
      _ownsSession = false;
      _speech.cancel();
    }
  }
}
