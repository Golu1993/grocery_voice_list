import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../services/hive_service.dart';

class OrderProvider extends ChangeNotifier {
   List<OrderItem> _orders = HiveService.getAllOrders();

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
    _orders = HiveService.getAllOrders();
    notifyListeners();
  }

  void addOrder(OrderItem order) {
    _orders.add(order);
    notifyListeners();
  }

  void removeOrder(int index) {
    HiveService.deleteOrder(_orders[index].orderId);
    _orders.removeAt(index);
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }
}
