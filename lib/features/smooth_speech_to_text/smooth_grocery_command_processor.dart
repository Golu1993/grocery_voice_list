import '../../providers/grocery_provider.dart';
import '../../services/voice_parser.dart';

/// Converts one finalized phrase into exactly one grocery-list operation.
class SmoothGroceryCommandProcessor {
  const SmoothGroceryCommandProcessor(this.groceryProvider);

  final GroceryProvider groceryProvider;

  Future<String> process(String transcript, {String? itemContextName}) async {
    var command = VoiceParser.parse(transcript.trim());
    if (itemContextName != null && command.itemName == null) {
      command = ParsedCommand(
        action: command.action,
        itemName: itemContextName,
        quantity: command.quantity,
        unit: command.unit,
        categoryKey: command.categoryKey,
        rawText: command.rawText,
      );
    }

    switch (command.action) {
      case CommandAction.add:
        if (command.itemName == null) return _unknownMessage;
        return groceryProvider.addItem(
          name: command.itemName!,
          quantity: command.quantity ?? 1,
          unit: command.unit ?? 'piece',
          categoryKey: command.categoryKey ?? 'other',
        );
      case CommandAction.addMore:
        if (command.itemName == null) return _unknownMessage;
        return await groceryProvider.addMoreToItem(
              command.itemName!,
              command.quantity ?? 1,
              command.unit ?? 'piece',
            ) ??
            'Done';
      case CommandAction.subtractQuantity:
        if (command.itemName == null) return _unknownMessage;
        return await groceryProvider.subtractFromItem(
              command.itemName!,
              command.quantity ?? 1,
              command.unit ?? 'piece',
            ) ??
            'Done';
      case CommandAction.setQuantity:
        if (command.itemName == null || command.quantity == null) {
          return _unknownMessage;
        }
        return await groceryProvider.setItemQuantity(
              command.itemName!,
              command.quantity!,
              command.unit ?? 'piece',
            ) ??
            'Done';
      case CommandAction.remove:
        final target = command.itemName ?? itemContextName;
        if (target == null) return _unknownMessage;
        return await groceryProvider.deleteItemByName(target) ?? 'Done';
      case CommandAction.check:
        final target = command.itemName ?? itemContextName;
        if (target == null) return _unknownMessage;
        return await groceryProvider.checkItemByName(target) ?? 'Done';
      case CommandAction.undo:
        await groceryProvider.undo();
        return 'Undone';
      case CommandAction.clear:
        await groceryProvider.clearAll();
        return 'List cleared';
      case CommandAction.uncheck:
        return 'Uncheck is not supported yet';
      case CommandAction.unknown:
        return _unknownMessage;
    }
  }

  static const _unknownMessage = 'Not understood. Try “add 2 kg tomatoes”';
}
