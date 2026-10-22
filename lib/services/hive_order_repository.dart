import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/grocery_field.dart';
import '../models/grocery_item.dart';
import '../models/order_item.dart';
import '../utils/constants.dart';

/// Local order storage scoped to a Firebase Authentication account.
class HiveOrderRepository {
  HiveOrderRepository._(this._items, this._orders);

  final Box<GroceryItem> _items;
  final Box<OrderItem> _orders;

  static Future<HiveOrderRepository> open(String authUid) async {
    if (authUid.isEmpty) throw StateError('No signed-in account is available.');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OrderItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GroceryFieldAdapter());
    }

    return HiveOrderRepository._(
      await Hive.openBox<GroceryItem>('${kGroceryBox}_$authUid'),
      await Hive.openBox<OrderItem>('${kOrderBox}_$authUid'),
    );
  }

  Future<String> ensureActiveOrder() async {
    final active = _activeOrder;
    if (active != null) {
      if (active.uuid.isEmpty) {
        // Older Hive records did not have UUIDs. Assign one once.
        active.uuid = const Uuid().v1();
      }
      await _syncActiveOrder(active);
      return active.uuid;
    }

    final order = _newOrder();
    await _orders.put(order.uuid, order);
    await _syncActiveOrder(order);
    return order.uuid;
  }

  List<GroceryItem> getActiveItems() =>
      _items.values.map((item) => item.copyWith()).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<OrderItem> getOrders() {
    final orders = _orders.values.map(_copyOrder).toList();
    orders.sort((a, b) => b.orderId.compareTo(a.orderId));
    return orders;
  }

  Future<void> saveItems(Iterable<GroceryItem> items) async {
    final active = _activeOrder;
    if (active == null) throw StateError('No active order is available.');
    final snapshot = {for (final item in items) item.id: item.copyWith()};
    await _items.putAll(snapshot);
    await _items.deleteAll(
      _items.keys.where((key) => !snapshot.containsKey(key)).toList(),
    );
    await _syncActiveOrder(active);
  }

  Future<String> startNewList() async {
    final previous = _activeOrder;
    if (previous != null) {
      await _syncActiveOrder(previous);
      previous.isCurrent = false;
      previous.completed = true;
      previous.status = 'Completed';
      await _orders.put(_keyFor(previous), previous);
    }

    await _items.clear();
    final next = _newOrder();
    await _orders.put(next.uuid, next);
    return next.uuid;
  }

  /// Reopens a saved order under its original UUID for editing.
  Future<void> activateOrder(String uuid) async {
    OrderItem? target;
    for (final order in _orders.values) {
      if (order.uuid == uuid) {
        target = order;
        break;
      }
    }
    if (target == null) throw StateError('List $uuid was not found.');
    if (target.isCurrent) return;

    final previous = _activeOrder;
    if (previous != null) {
      await _syncActiveOrder(previous);
      previous.isCurrent = false;
      await _orders.put(_keyFor(previous), previous);
    }

    final restored = target.itemList
        .map(
          (field) => GroceryItem(
            id: field.id ?? const Uuid().v4(),
            name: field.name,
            quantity: field.quantity,
            unit: field.unit,
            categoryKey: field.categoryKey ?? GroceryCategory.other.storageKey,
            isChecked: field.isChecked ?? false,
            createdAt: field.createdAt ?? DateTime.now(),
            notes: field.notes,
          ),
        )
        .toList();
    await _items.clear();
    await _items.putAll({for (final item in restored) item.id: item});

    target
      ..isCurrent = true
      ..completed = false
      ..status = 'Pending';
    await _syncActiveOrder(target);
  }

  Future<void> deleteOrder(String uuid) async {
    for (final key in _orders.keys) {
      final order = _orders.get(key);
      if (order?.uuid != uuid) continue;
      if (order!.isCurrent) {
        throw StateError('The active list cannot be deleted.');
      }
      await _orders.delete(key);
      return;
    }
  }

  OrderItem? get _activeOrder {
    final current = _orders.values.where((order) => order.isCurrent).toList();
    if (current.isEmpty) return null;
    current.sort((a, b) => b.orderId.compareTo(a.orderId));
    return current.first;
  }

  OrderItem _newOrder() {
    var id = DateTime.now().microsecondsSinceEpoch;
    while (_orders.values.any((order) => order.orderId == id)) {
      id++;
    }
    return OrderItem(
      time: DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now()),
      storeName: 'My Store',
      itemCount: 0,
      amount: 0,
      status: 'Pending',
      itemList: const [],
      orderId: id,
      isCurrent: true,
    );
  }

  Future<void> _syncActiveOrder(OrderItem order) async {
    final items = getActiveItems();
    order.itemCount = items.length;
    order.itemList = items
        .map(
          (item) => GroceryField(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            isChecked: item.isChecked,
            categoryKey: item.categoryKey,
            createdAt: item.createdAt,
            notes: item.notes,
          ),
        )
        .toList();
    await _orders.put(_keyFor(order), order);
  }

  dynamic _keyFor(OrderItem order) {
    for (final key in _orders.keys) {
      if (_orders.get(key)?.uuid == order.uuid) return key;
    }
    return order.uuid;
  }

  OrderItem _copyOrder(OrderItem order) => OrderItem(
    uuid: order.uuid,
    time: order.time,
    storeName: order.storeName,
    itemCount: order.itemCount,
    amount: order.amount,
    status: order.status,
    itemList: order.itemList
        .map(
          (item) => GroceryField(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            isChecked: item.isChecked,
            categoryKey: item.categoryKey,
            createdAt: item.createdAt,
            notes: item.notes,
          ),
        )
        .toList(),
    orderId: order.orderId,
    isExpanded: order.isExpanded,
    isCurrent: order.isCurrent,
    completed: order.completed,
  );
}
