import 'package:uuid/uuid.dart';

import 'grocery_field.dart';

class OrderItem {
  String time;

  String storeName;

  int itemCount;

  double amount;

  String status;

  List<GroceryField> itemList;

  bool isExpanded;
  int orderId;

  bool isCurrent;

  String uuid;

  bool completed;

  bool isPinned;

  DateTime? updatedAt;

  OrderItem({
    required this.time,
    required this.storeName,
    required this.itemCount,
    required this.amount,
    required this.status,
    required this.itemList,
    required this.orderId,
    this.isExpanded = false,
    required this.isCurrent,
    String? uuid,
    this.completed = false,
    this.isPinned = false,
    this.updatedAt,
  }) : uuid = uuid ?? const Uuid().v1();

  static int compareForDisplay(OrderItem a, OrderItem b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return compareByUpdatedTime(a, b);
  }

  static int compareByUpdatedTime(OrderItem a, OrderItem b) {
    final left = a.updatedAt;
    final right = b.updatedAt;
    if (left != null && right != null) {
      final byUpdate = right.compareTo(left);
      if (byUpdate != 0) return byUpdate;
    } else if (left != null) {
      return -1;
    } else if (right != null) {
      return 1;
    }
    return b.orderId.compareTo(a.orderId);
  }
}
