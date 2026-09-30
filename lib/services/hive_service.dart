import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/grocery_field.dart';
import '../models/grocery_item.dart';
import '../models/order_item.dart';
import '../utils/constants.dart';

class HiveService {
  static late Box<GroceryItem> _box;
  static late Box<OrderItem> _boxOrder;
  static String? _activeUserId;
  static const _migrationBoxName = 'vocart_auth_migration';
  static const _migrationOwnerKey = 'legacy_owner_uid';

  static Future<void> init({String? directory}) async {
    if (directory == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(directory);
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OrderItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GroceryFieldAdapter());
    }
    _box = await Hive.openBox<GroceryItem>(kGroceryBox);
    _boxOrder = await Hive.openBox<OrderItem>(kOrderBox);
  }

  /// Keeps local lists separate for each signed-in account. Legacy lists are
  /// copied once to the first account, leaving the originals as a backup.
  static Future<void> activateUser(String uid) async {
    if (_activeUserId == uid && _box.isOpen && _boxOrder.isOpen) return;

    final previousGrocery = _box;
    final previousOrders = _boxOrder;
    final grocery = await Hive.openBox<GroceryItem>('${kGroceryBox}_$uid');
    final orders = await Hive.openBox<OrderItem>('${kOrderBox}_$uid');
    final migration = await Hive.openBox<String>(_migrationBoxName);

    if (migration.get(_migrationOwnerKey) == null) {
      final legacyGrocery = await Hive.openBox<GroceryItem>(kGroceryBox);
      final legacyOrders = await Hive.openBox<OrderItem>(kOrderBox);
      for (final key in legacyGrocery.keys) {
        if (!grocery.containsKey(key)) {
          await grocery.put(key, legacyGrocery.get(key)!.copyWith());
        }
      }
      for (final key in legacyOrders.keys) {
        if (!orders.containsKey(key)) {
          final item = legacyOrders.get(key)!;
          await orders.put(
            key,
            OrderItem(
              time: item.time,
              storeName: item.storeName,
              itemCount: item.itemCount,
              amount: item.amount,
              status: item.status,
              itemList: item.itemList
                  .map(
                    (field) => GroceryField(
                      name: field.name,
                      quantity: field.quantity,
                      unit: field.unit,
                      isChecked: field.isChecked,
                    ),
                  )
                  .toList(),
              orderId: item.orderId,
              isExpanded: item.isExpanded,
              isCurrent: item.isCurrent,
              uuid: item.uuid.isEmpty ? null : item.uuid,
              completed: item.completed,
            ),
          );
        }
      }
      await migration.put(_migrationOwnerKey, uid);
      if (legacyGrocery != previousGrocery) await legacyGrocery.close();
      if (legacyOrders != previousOrders) await legacyOrders.close();
    }

    for (final key in orders.keys) {
      final order = orders.get(key);
      if (order != null && order.uuid.isEmpty) {
        order.uuid = const Uuid().v1();
        await orders.put(key, order);
      }
    }

    _box = grocery;
    _boxOrder = orders;
    _activeUserId = uid;
    if (previousGrocery != grocery) await previousGrocery.close();
    if (previousOrders != orders) await previousOrders.close();
  }

  static Box<GroceryItem> get box => _box;

  static List<GroceryItem> getAllGrocery() {
    return _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> save(GroceryItem item) async {
    await _box.put(item.id, item);
    await saveCurrentItem();
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
    await saveCurrentItem();
  }

  static Future<void> deleteOrder(int id) async {
    await _boxOrder.delete(id);
  }

  static Future<void> deleteAll() async {
    OrderItem orderItem = getAllGroceryItems(false);
    await _boxOrder.put(orderItem.orderId, orderItem);
    await _box.clear();
  }

  static Future<void> close() async {
    await _box.close();
    await _boxOrder.close();
    _activeUserId = null;
  }

  static Future<void> saveToOrderBox(OrderItem orderItem) async {
    await _boxOrder.put(orderItem.orderId, orderItem);
  }

  static List<OrderItem> getAllOrders() {
    var orders = _boxOrder.values.toList();
    orders.sort((a, b) => b.orderId.compareTo(a.orderId));
    return orders;
  }

  static List<OrderItem> getAllSavedOrders() {
    return _boxOrder.values.where((item) => !item.isCurrent).toList();
  }

  static int getOrderID(bool current, int length, int length2) {
    if (current) {
      return length == length2 ? length : length2;
    }
    return length2;
  }

  static OrderItem getAllGroceryItems(bool current) {
    final groceries = getAllGrocery();
    var list = getAllOrders();
    var listSaved = getAllSavedOrders();

    OrderItem? currentOrder;
    for (final order in _boxOrder.values) {
      if (order.isCurrent) {
        currentOrder = order;
        break;
      }
    }

    var orderID =
        currentOrder?.orderId ??
        getOrderID(current, list.length, listSaved.length);
    if (list.length == getAllSavedOrders().length) {}
    String date = DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now());
    final existingUuid = currentOrder?.uuid;
    return OrderItem(
      orderId: orderID,
      uuid: existingUuid == null || existingUuid.isEmpty ? null : existingUuid,
      time: date,
      storeName: 'My Store',
      itemCount: groceries.length,
      amount: 0,
      isCurrent: current,
      isExpanded: false,
      status: 'Pending',
      itemList: groceries
          .map(
            (item) => GroceryField(
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              isChecked: item.isChecked,
            ),
          )
          .toList(),
    );
  }

  static Future<void> saveCurrentItem() async {
    OrderItem orderItem = getAllGroceryItems(true);
    await _boxOrder.put(orderItem.orderId, orderItem);
  }
}
