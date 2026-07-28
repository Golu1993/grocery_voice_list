import 'package:grocery_voice_list/models/grocery_field.dart';

class OrderItem {
  final String time;
  final String storeName;
  final int itemCount;
  final double amount;
  final String status;
  final List<GroceryField> itemList;
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
