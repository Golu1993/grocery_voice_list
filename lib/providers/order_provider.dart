import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../services/firestore_query.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({required this.firestoreQuery, this.activeOrderUuid});

  final FirestoreQuery firestoreQuery;
  String? activeOrderUuid;
  List<OrderItem> _orders = [];
  final Set<String> _pinningOrderIds = {};

  List<OrderItem> get orders => List.unmodifiable(_orders);

  bool isPinning(String uuid) => _pinningOrderIds.contains(uuid);

  void toggleExpanded(String uuid) {
    final order = _orders.firstWhere((order) => order.uuid == uuid);
    order.isExpanded = !order.isExpanded;
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    final expandedById = {
      for (final order in _orders) order.uuid: order.isExpanded,
    };
    _orders = await firestoreQuery.getOrders();
    _orders.sort(OrderItem.compareForDisplay);
    for (final order in _orders) {
      order.isCurrent = order.uuid == activeOrderUuid;
      order.isExpanded = expandedById[order.uuid] ?? false;
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

  Future<void> togglePinned(String uuid) async {
    if (!_pinningOrderIds.add(uuid)) return;
    notifyListeners();
    try {
      final order = _orders.firstWhere((order) => order.uuid == uuid);
      final isPinned = !order.isPinned;
      final updatedAt = await firestoreQuery.setListPinned(
        uuid,
        isPinned: isPinned,
      );
      for (final current in _orders) {
        if (current.uuid != uuid) continue;
        current.isPinned = isPinned;
        current.updatedAt = updatedAt;
      }
      _orders.sort(OrderItem.compareForDisplay);
    } finally {
      _pinningOrderIds.remove(uuid);
      notifyListeners();
    }
  }

  Future<void> removeOrder(String uuid) async {
    final order = _orders.firstWhere((order) => order.uuid == uuid);
    if (order.isCurrent) throw StateError('The active list cannot be deleted.');
    await firestoreQuery.deleteOrder(order.uuid);
    _orders.removeWhere((current) => current.uuid == uuid);
    notifyListeners();
  }
}
