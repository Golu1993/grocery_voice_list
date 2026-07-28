import 'package:flutter/material.dart';
import 'package:grocery_voice_list/models/grocery_field.dart';

import '../models/order_item.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderItem> _orders = [
    OrderItem(
      time: 'Today, 10:30 AM',
      storeName: 'Fresh Mart',
      itemCount: 5,
      amount: 320,
      status: 'Delivered',
      itemList: const [
        GroceryField(name: 'Potato', quantity: 2, unit: 'kg'),
        GroceryField(name: 'Onion', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Coriander', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Tomato', quantity: 3, unit: 'kg'),
        GroceryField(name: 'Milk', quantity: 2, unit: 'lt'),
      ],
    ),
    OrderItem(
      time: 'Today, 10:30 AM',
      storeName: 'Fresh Mart',
      itemCount: 5,
      amount: 320,
      status: 'Delivered',
      itemList: const [
        GroceryField(name: 'Potato', quantity: 2, unit: 'kg'),
        GroceryField(name: 'Onion', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Coriander', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Tomato', quantity: 3, unit: 'kg'),
        GroceryField(name: 'Milk', quantity: 2, unit: 'lt'),
      ],
    ),
    OrderItem(
      time: 'Today, 10:30 AM',
      storeName: 'Fresh Mart',
      itemCount: 5,
      amount: 320,
      status: 'Delivered',
      itemList: const [
        GroceryField(name: 'Potato', quantity: 2, unit: 'kg'),
        GroceryField(name: 'Onion', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Coriander', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Tomato', quantity: 3, unit: 'kg'),
        GroceryField(name: 'Milk', quantity: 2, unit: 'lt'),
      ],
    ),
    OrderItem(
      time: 'Today, 10:30 AM',
      storeName: 'Fresh Mart',
      itemCount: 5,
      amount: 320,
      status: 'Delivered',
      itemList: const [
        GroceryField(name: 'Potato', quantity: 2, unit: 'kg'),
        GroceryField(name: 'Onion', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Coriander', quantity: 1, unit: 'kg'),
        GroceryField(name: 'Tomato', quantity: 3, unit: 'kg'),
        GroceryField(name: 'Milk', quantity: 2, unit: 'lt'),
      ],
    ),
  ];

  List<OrderItem> get orders => _orders;

  void toggleExpanded(int index) {
    for (int i = 0; i < _orders.length; i++) {
      if (i == index) {
        _orders[i].isExpanded = !_orders[i].isExpanded;
      } else {
        _orders[i].isExpanded = false;
      }
    }

    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await Future.delayed(const Duration(seconds: 1));

    notifyListeners();
  }

  void addOrder(OrderItem order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void removeOrder(int index) {
    _orders.removeAt(index);
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
}
