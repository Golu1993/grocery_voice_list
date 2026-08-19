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
            _speech.changePauseFor(const Duration(milliseconds: 1400));
          }
        }
        onResult(words, result.finalResult);
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: false,
        onDevice: false,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        // Do not finish before the user has had a reasonable chance to begin.
        // This changes to 1.4 seconds as soon as the first words arrive.
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(minutes: 2),
      ),
    );
  }

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
