import 'package:flutter_test/flutter_test.dart';
import 'package:groceryvoicelist/features/smooth_speech_to_text/smooth_speech_to_text.dart';

void main() {
  test('keeps final phrases and removes overlap between sessions', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final submittedPhrases = <String>[];
    final controller = SmoothSpeechToTextController(
      recognizer: recognizer,
      onFinalPhrase: submittedPhrases.add,
    );

    await controller.start();
    recognizer.result('buy milk and bread', true);
    recognizer.result('and bread tomorrow', true);

    expect(controller.transcript, 'buy milk and bread tomorrow');
    expect(submittedPhrases, ['buy milk and bread']);

    await controller.stop();
    expect(controller.state, SmoothSpeechState.idle);
    controller.dispose();
  });

  test('shows partial text immediately and clear removes it', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final controller = SmoothSpeechToTextController(recognizer: recognizer);

    await controller.start();
    recognizer.result('live partial words', false);
    expect(controller.transcript, 'live partial words');

    controller.clear();
    expect(controller.transcript, isEmpty);
    controller.dispose();
  });

  test('stop does not submit an unfinished partial phrase', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final submittedPhrases = <String>[];
    final controller = SmoothSpeechToTextController(
      recognizer: recognizer,
      onFinalPhrase: submittedPhrases.add,
    );

    await controller.start();
    recognizer.result('unfinished command', false);
    await controller.stop();

    expect(submittedPhrases, isEmpty);
    controller.dispose();
  });
}

class _FakeSmoothSpeechRecognizer implements SmoothSpeechRecognizer {
  SmoothSpeechResultCallback? _onResult;
  bool _listening = false;

  @override
  bool get isListening => _listening;

  void result(String words, bool isFinal) => _onResult?.call(words, isFinal);

  @override
  Future<bool> initialize({required SmoothSpeechErrorCallback onError}) async =>
      true;

  @override
  Future<void> listen({
    required SmoothSpeechResultCallback onResult,
    required SmoothSpeechLevelCallback onSoundLevel,
    String? localeId,
  }) async {
    _onResult = onResult;
    _listening = true;
  }

  @override
  Future<void> cancel() async => _listening = false;

  @override
  Future<void> stop() async => _listening = false;

  @override
  void dispose() => _listening = false;
}
