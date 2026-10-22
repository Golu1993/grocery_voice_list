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

  @HiveField(4)
  String? id;

  @HiveField(5)
  String? categoryKey;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  String? notes;

  GroceryField({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isChecked,
    this.id,
    this.categoryKey,
    this.createdAt,
    this.notes,
  });
}
