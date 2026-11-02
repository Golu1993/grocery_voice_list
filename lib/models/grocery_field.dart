class GroceryField {
  String name;

  double quantity;

  String unit;
  bool? isChecked;
  bool isPinned;

  String? id;

  String? categoryKey;

  DateTime? createdAt;

  String? notes;

  GroceryField({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isChecked,
    this.isPinned = false,
    this.id,
    this.categoryKey,
    this.createdAt,
    this.notes,
  });
}
