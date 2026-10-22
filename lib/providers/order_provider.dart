import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../services/hive_order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({required this.orderRepository, this.activeOrderUuid});

  final HiveOrderRepository orderRepository;
  String? activeOrderUuid;
  List<OrderItem> _orders = [];

  List<OrderItem> get orders => List.unmodifiable(_orders);

  void toggleExpanded(int index) {
    for (var i = 0; i < _orders.length; i++) {
      _orders[i].isExpanded = i == index && !_orders[i].isExpanded;
    }
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    _orders = orderRepository
        .getOrders()
        .where((order) => order.itemList.isNotEmpty)
        .toList();
    for (final order in _orders) {
      order.isCurrent = order.uuid == activeOrderUuid;
    }
    notifyListeners();
  }

  void setActiveOrder(String uuid) {
    activeOrderUuid = uuid;
    for (final order in _orders) {
      order.isCurrent = order.uuid == uuid;
      if (!order.isCurrent) {
        order.completed = true;
        order.status = 'Completed';
      }
    }
    notifyListeners();
  }

  Future<void> showEditedOrder(String uuid) async {
    activeOrderUuid = uuid;
    await refreshOrders();
  }

  Future<void> removeOrder(int index) async {
    final order = _orders[index];
    if (order.isCurrent) throw StateError('The active list cannot be deleted.');
    await orderRepository.deleteOrder(order.uuid);
    _orders.removeAt(index);
    notifyListeners();
  }
}
