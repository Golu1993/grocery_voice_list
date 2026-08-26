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

  test('can submit the latest partial phrase when Done is tapped', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final submittedPhrases = <String>[];
    final controller = SmoothSpeechToTextController(
      recognizer: recognizer,
      onFinalPhrase: submittedPhrases.add,
    );

    await controller.start();
    recognizer.result('add two kilos of rice', false);
    await controller.stop(submitPendingPhrase: true);

    expect(controller.transcript, 'add two kilos of rice');
    expect(submittedPhrases, ['add two kilos of rice']);
    expect(controller.state, SmoothSpeechState.idle);
    controller.dispose();
  });

  test('recovers when Android closes a completed speech session', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final submittedPhrases = <String>[];
    final controller = SmoothSpeechToTextController(
      recognizer: recognizer,
      onFinalPhrase: submittedPhrases.add,
    );

    await controller.start();
    recognizer.result('add milk', false);
    recognizer.error('error_client');

    expect(controller.state, isNot(SmoothSpeechState.error));
    expect(controller.errorMessage, isEmpty);
    expect(submittedPhrases, ['add milk']);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(recognizer.listenCount, greaterThan(1));
    expect(controller.state, SmoothSpeechState.listening);
    controller.dispose();
  });

  test('still reports genuine permission failures', () async {
    final recognizer = _FakeSmoothSpeechRecognizer();
    final controller = SmoothSpeechToTextController(recognizer: recognizer);

    await controller.start();
    recognizer.error('error_permission');

    expect(controller.state, SmoothSpeechState.error);
    expect(controller.errorMessage, contains('device settings'));
    controller.dispose();
  });
}

class _FakeSmoothSpeechRecognizer implements SmoothSpeechRecognizer {
  SmoothSpeechResultCallback? _onResult;
  SmoothSpeechErrorCallback? _onError;
  bool _listening = false;
  int listenCount = 0;

  @override
  bool get isListening => _listening;

  void result(String words, bool isFinal) => _onResult?.call(words, isFinal);

  void error(String error) {
    _listening = false;
    _onError?.call(error);
  }

  @override
  Future<bool> initialize({required SmoothSpeechErrorCallback onError}) async {
    _onError = onError;
    return true;
  }

  @override
  Future<void> listen({
    required SmoothSpeechResultCallback onResult,
    required SmoothSpeechLevelCallback onSoundLevel,
    String? localeId,
  }) async {
    listenCount++;
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
