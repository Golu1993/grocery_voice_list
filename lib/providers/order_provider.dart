import 'package:flutter/material.dart';
import 'package:grocery_voice_list/services/hive_service.dart';

import '../models/order_item.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderItem> _orders = HiveService.getAllOrders();

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
