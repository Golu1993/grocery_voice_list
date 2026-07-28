import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

typedef OnResult = void Function(String text, bool isFinal);
typedef OnStatus = void Function(String status);
typedef OnError = void Function(String error);

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _stt.isListening;

  Future<bool> initialize() async {
    _isAvailable = await _stt.initialize(
      onError: _onError,
      onStatus: _onStatus,
      debugLogging: false,
    );
    return _isAvailable;
  }

  OnResult? _onResult;
  OnStatus? _onStatusCallback;
  OnError? _onErrorCallback;

  void _onError(SpeechRecognitionError error) {
    _onErrorCallback?.call(error.errorMsg);
  }

  void _onStatus(String status) {
    _onStatusCallback?.call(status);
  }

  Future<void> startListening({
    required OnResult onResult,
    OnStatus? onStatus,
    OnError? onError,
    String localeId = 'en_IN',
  }) async {
    if (!_isAvailable) await initialize();
    if (!_isAvailable) {
      onError?.call('Speech recognition not available');
      return;
    }

    _onResult = onResult;
    _onStatusCallback = onStatus;
    _onErrorCallback = onError;

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        _onResult?.call(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  Future<void> cancelListening() async {
    await _stt.cancel();
  }

  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) await initialize();
    return _stt.locales();
  }

  void dispose() {
    _stt.cancel();
  }
}
