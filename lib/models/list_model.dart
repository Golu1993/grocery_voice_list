import 'package:cloud_firestore/cloud_firestore.dart';

/// A grocery list stored as a Firestore document.
class ListModel {
  const ListModel({
    required this.createTime,
    required this.description,
    required this.listId,
    required this.listName,
    required this.updateTime,
    required this.color,
    required this.isArchive,
    required this.isDeleted,
    required this.ownerId,
    this.isPinned = false,
  });

  final DateTime createTime;
  final String description;
  final String listId;
  final String listName;
  final DateTime updateTime;
  final String color;
  final bool isArchive;
  final bool isDeleted;
  final String ownerId;
  final bool isPinned;

  Map<String, dynamic> toMap() => {
    'createTime': Timestamp.fromDate(createTime),
    'description': description,
    'listId': listId,
    'listName': listName,
    'updateTime': Timestamp.fromDate(updateTime),
    'color': color,
    'isArchive': isArchive,
    'isDeleted': isDeleted,
    'ownerId': ownerId,
    'isPinned': isPinned,
  };

  factory ListModel.fromMap(Map<String, dynamic> data) {
    return ListModel(
      createTime: (data['createTime'] as Timestamp).toDate(),
      description: data['description'] as String,
      listId: data['listId'] as String,
      listName: data['listName'] as String,
      updateTime: (data['updateTime'] as Timestamp).toDate(),
      color: data['color'] as String,
      isArchive: data['isArchive'] as bool,
      isDeleted: data['isDeleted'] as bool,
      ownerId: data['ownerId'] as String,
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }
}
