import 'package:flutter_test/flutter_test.dart';
import 'package:groceryvoicelist/services/voice_parser.dart';

void main() {
  group('VoiceParser local grocery commands', () {
    test('adds a weighted item', () {
      final command = VoiceParser.parse('add two kg potato');

      expect(command.action, CommandAction.add);
      expect(command.itemName, 'Potato');
      expect(command.quantity, 2);
      expect(command.unit, 'kg');
    });

    test('ignores natural filler words around an item', () {
      final command = VoiceParser.parse('please add 2 kilos of rice for me');

      expect(command.action, CommandAction.add);
      expect(command.itemName, 'Rice');
      expect(command.quantity, 2);
      expect(command.unit, 'kg');
    });

    test('adds a simple item with its local default unit', () {
      final command = VoiceParser.parse('add milk');

      expect(command.action, CommandAction.add);
      expect(command.itemName, 'Milk');
      expect(command.quantity, 1);
      expect(command.unit, 'l');
    });

    test('removes and deletes items', () {
      expect(VoiceParser.parse('remove tomato').action, CommandAction.remove);
      expect(VoiceParser.parse('delete milk').action, CommandAction.remove);
    });

    test('sets an existing item to an exact quantity', () {
      final command = VoiceParser.parse('increase onion to 3 kg');

      expect(command.action, CommandAction.setQuantity);
      expect(command.itemName, 'Onion');
      expect(command.quantity, 3);
      expect(command.unit, 'kg');
    });

    test('keeps context commands and splits compact quantities', () {
      final command = VoiceParser.parse('change to 500g');

      expect(command.action, CommandAction.setQuantity);
      expect(command.itemName, isNull);
      expect(command.quantity, 500);
      expect(command.unit, 'g');
      expect(VoiceParser.parse('delete').action, CommandAction.remove);
    });
  });
}
