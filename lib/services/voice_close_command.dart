/// Separates an explicit closing phrase from an optional grocery command.
class VoiceCloseCommand {
  const VoiceCloseCommand._({
    required this.shouldClose,
    required this.commandText,
  });

  final bool shouldClose;
  final String commandText;

  static const _standaloneOnly = {
    'done',
    'finished',
    'bas',
    'bs',
    'bus',
    'khatam',
    'khatm',
    'बस',
    'खत्म',
    'ख़त्म',
  };

  static final _closingPhrases = [
    'ok done',
    'okay done',
    'all done',
    'im done',
    'i am done',
    'thats all',
    'that is all',
    'thats it',
    'that is it',
    'nothing else',
    'no more items',
    'stop listening',
    'close this',
    'close mic',
    'close microphone',
    'done for now',
    'list complete',
    'bas itna hi',
    'bs itna hi',
    'bus itna hi',
    'bas karo',
    'bs karo',
    'bus karo',
    'bas ho gaya',
    'bs ho gaya',
    'bus ho gaya',
    'itna hi',
    'aur kuch nahi',
    'aur kuch nahin',
    'ab band karo',
    'mic band karo',
    'mike band karo',
    'microphone band karo',
    'ho gaya bas',
    'ho gya bas',
    'ho gaya',
    'ho gya',
    'बस इतना ही',
    'हो गया',
    'ठीक है बस',
    'बस करो',
    'इतना ही',
    'और कुछ नहीं',
    'और कुछ नही',
    'अब बंद करो',
    'माइक बंद करो',
    'माइक बन्द करो',
    'काम हो गया',
  ]..sort((a, b) => b.length.compareTo(a.length));

  static VoiceCloseCommand parse(String transcript) {
    final text = transcript
        .toLowerCase()
        .replaceAll(RegExp("['’]"), '')
        .replaceAll(RegExp(r'[.,!?;:…।॥“”"()\[\]{}\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (_standaloneOnly.contains(text)) {
      return const VoiceCloseCommand._(shouldClose: true, commandText: '');
    }
    for (final phrase in _closingPhrases) {
      if (text == phrase) {
        return const VoiceCloseCommand._(shouldClose: true, commandText: '');
      }
      // A complete phrase must end the utterance and begin at a word boundary.
      if (!text.endsWith(' $phrase')) continue;
      var command = text.substring(0, text.length - phrase.length).trim();
      command = command
          .replaceFirst(RegExp(r'(?:\s+(?:and|then|aur|और|please))+$'), '')
          .trim();
      if (const {'please', 'ok', 'okay', 'ठीक है'}.contains(command)) {
        command = '';
      }
      // Allow repeated closing phrases such as “OK done, bas itna hi”.
      final preceding = parse(command);
      if (preceding.shouldClose) command = preceding.commandText;
      return VoiceCloseCommand._(shouldClose: true, commandText: command);
    }
    return VoiceCloseCommand._(
      shouldClose: false,
      commandText: transcript.trim(),
    );
  }
}
