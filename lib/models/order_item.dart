import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'grocery_field.dart';

part 'order.item.g.dart';

@HiveType(typeId: 1)
class OrderItem extends HiveObject {
  @HiveField(0)
  String time;

  @HiveField(1)
  String storeName;

  @HiveField(2)
  int itemCount;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String status;

  @HiveField(5)
  List<GroceryField> itemList;

  @HiveField(6)
  bool isExpanded;
  @HiveField(7)
  int orderId;

  @HiveField(8)
  bool isCurrent;

  @HiveField(9)
  String uuid;

  @HiveField(10)
  bool completed;

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
  }) : uuid = uuid ?? const Uuid().v1();
}
