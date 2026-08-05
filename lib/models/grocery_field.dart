
import 'package:hive/hive.dart';

part 'grocery_field.g.dart';

@HiveType(typeId: 2)
class GroceryField extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  String unit;
  @HiveField(3)
  bool? isChecked;

  GroceryField({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isChecked,
  });
}