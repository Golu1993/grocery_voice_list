import 'package:hive/hive.dart';

part 'grocery_item.g.dart';

@HiveType(typeId: 0)
class GroceryItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String unit; // 'kg', 'g', 'l', 'ml', 'piece', 'packet', 'dozen', 'bottle', 'can', 'bundle'

  @HiveField(4)
  String categoryKey;

  @HiveField(5)
  bool isChecked;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? notes;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.categoryKey,
    this.isChecked = false,
    required this.createdAt,
    this.notes,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? categoryKey,
    bool? isChecked,
    DateTime? createdAt,
    String? notes,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      categoryKey: categoryKey ?? this.categoryKey,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'GroceryItem($name, $quantity $unit)';
}
