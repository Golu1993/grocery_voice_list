import 'package:grocery_voice_list/models/grocery_field.dart';

import 'package:hive/hive.dart';

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

  OrderItem({
    required this.time,
    required this.storeName,
    required this.itemCount,
    required this.amount,
    required this.status,
    required this.itemList,
    this.isExpanded = false,
  });
}
