import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/grocery_field.dart';
import '../models/order_item.dart';
import '../services/firestore_query.dart';

class OrderProvider extends ChangeNotifier {
  factory OrderProvider({
    FirestoreQuery? firestoreQuery,
    String? userUuid,
    String? activeOrderUuid,
  }) => OrderProvider._(firestoreQuery, userUuid, activeOrderUuid);

  OrderProvider._(this._firestoreQuery, this._userUuid, this._activeOrderUuid);

  FirestoreQuery? _firestoreQuery;
  final String? _userUuid;
  String? _activeOrderUuid;
  List<OrderItem> _orders = [];

  FirestoreQuery get _query => _firestoreQuery ??= FirestoreQuery();
  List<OrderItem> get orders => List.unmodifiable(_orders);

  void toggleExpanded(int index) {
    for (var i = 0; i < _orders.length; i++) {
      _orders[i].isExpanded = i == index && !_orders[i].isExpanded;
    }
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    final userUuid = _userUuid;
    if (userUuid == null) return;
    final documents = await _query.getOrders(userUuid);
    _orders = documents.where((order) => order.items.isNotEmpty).map((order) {
      final createdAt = order.createdAt ?? DateTime.now();
      return OrderItem(
        uuid: order.uuid,
        time: DateFormat('MMMM dd, yyyy hh:mm a').format(createdAt),
        storeName: 'My Store',
        itemCount: order.items.length,
        amount: 0,
        status: order.completed ? 'Completed' : 'Pending',
        itemList: order.items
            .map(
              (item) => GroceryField(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                isChecked: item.isChecked,
              ),
            )
            .toList(),
        orderId: createdAt.microsecondsSinceEpoch,
        isCurrent: order.uuid == _activeOrderUuid,
        completed: order.completed,
      );
    }).toList();
    notifyListeners();
  }

  void setActiveOrder(String uuid) {
    _activeOrderUuid = uuid;
    for (final order in _orders) {
      order.isCurrent = order.uuid == uuid;
      if (!order.isCurrent) {
        order.completed = true;
        order.status = 'Completed';
      }
    }
    notifyListeners();
  }

  Future<void> removeOrder(int index) async {
    final userUuid = _userUuid;
    if (userUuid == null) throw StateError('No signed-in user is available.');
    final order = _orders[index];
    if (order.isCurrent) throw StateError('The active list cannot be deleted.');
    await _query.deleteOrder(orderUuid: order.uuid, userUuid: userUuid);
    _orders.removeAt(index);
    notifyListeners();
  }
}
