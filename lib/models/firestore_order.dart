import 'package:cloud_firestore/cloud_firestore.dart';

import 'grocery_item.dart';

class FirestoreOrder {
  const FirestoreOrder({
    required this.uuid,
    required this.createdBy,
    required this.updatedBy,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.completed = false,
  });

  final String uuid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool completed;
  final List<GroceryItem> items;

  factory FirestoreOrder.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('Order ${document.id} was deleted.');
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return FirestoreOrder(
      uuid: document.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      completed: data['completed'] as bool? ?? false,
      items: rawItems.asMap().entries.map((entry) {
        final raw = entry.value;
        final item = raw as Map<String, dynamic>;
        return GroceryItem(
          id: item['id'] as String? ?? '${document.id}_${entry.key}',
          name: item['name'] as String,
          quantity: (item['quantity'] as num).toDouble(),
          unit: item['unit'] as String,
          categoryKey: item['categoryKey'] as String? ?? 'other',
          isChecked: item['isChecked'] as bool? ?? false,
          createdAt:
              (item['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          notes: item['notes'] as String?,
        );
      }).toList(),
    );
  }

  static List<Map<String, dynamic>> encodeItems(Iterable<GroceryItem> items) =>
      items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
              'unit': item.unit,
              'isChecked': item.isChecked,
              'categoryKey': item.categoryKey,
              'createdAt': Timestamp.fromDate(item.createdAt),
              'notes': item.notes,
            },
          )
          .toList();
}
