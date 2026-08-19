import 'package:flutter_test/flutter_test.dart';
import 'package:groceryvoicelist/features/smooth_speech_to_text/smooth_speech_to_text.dart';
import 'package:groceryvoicelist/providers/grocery_provider.dart';

void main() {
  test(
    'final speech phrase is parsed and added to the grocery provider',
    () async {
      final grocery = _RecordingGroceryProvider();
      final processor = SmoothGroceryCommandProcessor(grocery);

      final feedback = await processor.process('add 2 kg potatoes');

    expect(grocery.name, 'Potatoes');
      expect(grocery.quantity, 2);
      expect(grocery.unit, 'kg');
    expect(feedback, 'Added 2 kg Potatoes');
    },
  );
}

class _RecordingGroceryProvider extends GroceryProvider {
  String? name;
  double? quantity;
  String? unit;

  @override
  Future<String> addItem({
    required String name,
    required double quantity,
    required String unit,
    required String categoryKey,
    String? notes,
  }) async {
    this.name = name;
    this.quantity = quantity;
    this.unit = unit;
    return 'Added ${quantity.toInt()} $unit $name';
  }
}
