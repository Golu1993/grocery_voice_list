class GroceryItem {
  String id;

  String name;

  double quantity;

  // 'kg', 'g', 'l', 'ml', 'piece', 'packet', 'dozen', 'bottle', 'can', 'bundle'
  String unit;

  String categoryKey;

  bool isChecked;

  bool isPinned;

  DateTime createdAt;

  String? notes;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.categoryKey,
    this.isChecked = false,
    this.isPinned = false,
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
    bool? isPinned,
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
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  static int compareForDisplay(GroceryItem a, GroceryItem b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
    final byCreatedAt = a.createdAt.compareTo(b.createdAt);
    return byCreatedAt != 0 ? byCreatedAt : a.id.compareTo(b.id);
  }

  @override
  String toString() => 'GroceryItem($name, $quantity $unit)';
}
