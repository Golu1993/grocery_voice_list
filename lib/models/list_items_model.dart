import 'package:cloud_firestore/cloud_firestore.dart';

/// An item belonging to a grocery list stored in Firestore.
class ListItemsModel {
  const ListItemsModel({
    required this.createdTime,
    required this.itemId,
    required this.itemName,
    required this.listId,
    required this.listItemId,
    required this.notes,
    required this.quantity,
    required this.unit,
    required this.updateTime,
    required this.addedBy,
    required this.isChecked,
    required this.updatedBy,
    required this.ownerId,
    this.isPinned = false,
    this.checkedAt,
    this.checkedBy,
    this.categoryKey,
  });

  final DateTime? checkedAt;
  final String? checkedBy;
  final DateTime createdTime;
  final String itemId;
  final String itemName;
  final String listId;
  final String listItemId;
  final String notes;
  final String quantity;
  final String unit;
  final DateTime updateTime;
  final String addedBy;
  final bool isChecked;
  final String updatedBy;
  final String ownerId;
  final bool isPinned;
  final String? categoryKey;

  Map<String, dynamic> toMap() => {
    'checkedAt': checkedAt == null ? null : Timestamp.fromDate(checkedAt!),
    'checkedBy': checkedBy,
    'createdTime': Timestamp.fromDate(createdTime),
    'itemId': itemId,
    'itemName': itemName,
    'listId': listId,
    'listItemId': listItemId,
    'notes': notes,
    'quantity': quantity,
    'unit': unit,
    'updateTime': Timestamp.fromDate(updateTime),
    'addedBy': addedBy,
    'isChecked': isChecked,
    'updatedBy': updatedBy,
    'ownerId': ownerId,
    'isPinned': isPinned,
    'categoryKey': categoryKey,
  };

  factory ListItemsModel.fromMap(Map<String, dynamic> data) {
    return ListItemsModel(
      checkedAt: (data['checkedAt'] as Timestamp?)?.toDate(),
      checkedBy: data['checkedBy'] as String?,
      createdTime: (data['createdTime'] as Timestamp).toDate(),
      itemId: data['itemId'] as String,
      itemName: data['itemName'] as String,
      listId: data['listId'] as String,
      listItemId: data['listItemId'] as String,
      notes: data['notes'] as String,
      quantity: data['quantity'] as String,
      unit: data['unit'] as String,
      updateTime: (data['updateTime'] as Timestamp).toDate(),
      addedBy: data['addedBy'] as String,
      isChecked: data['isChecked'] as bool,
      updatedBy: data['updatedBy'] as String,
      ownerId: data['ownerId'] as String,
      isPinned: data['isPinned'] as bool? ?? false,
      categoryKey: data['categoryKey'] as String?,
    );
  }
}
