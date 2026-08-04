import 'package:grocery_voice_list/models/order_item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/grocery_field.dart';
import '../models/grocery_item.dart';
import '../utils/constants.dart';

class HiveService {
  static late Box<GroceryItem> _box;
  static late Box<OrderItem> _boxOrder;

  static Future<void> init() async {
    await Hive.initFlutter();
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

  static Box<GroceryItem> get box => _box;

  static List<GroceryItem> getAllGrocery() {
    return _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> save(GroceryItem item) async {
    await _box.put(item.id, item);
    saveCurrentItem();
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
    saveCurrentItem();

  }

  static Future<void> deleteAll() async {
    OrderItem orderItem = getAllGroceryItems(false);
    await saveToOrderBox(orderItem);
    await _box.clear();
  }

  static Future<void> close() async {
    await _box.close();
  }

  static Future<void> saveToOrderBox(OrderItem orderItem) async {
    await _boxOrder.put(orderItem.orderId, orderItem);
  }

  static List<OrderItem> getAllOrders() {
    var orders= _boxOrder.values.toList();
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

    var orderID = getOrderID(current, list.length, listSaved.length);
    if (list.length == getAllSavedOrders().length) {}
    String date = DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now());
    return OrderItem(
      orderId: orderID,
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
            ),
          )
          .toList(),
    );
  }

  static void saveCurrentItem() async {
    OrderItem orderItem = getAllGroceryItems(true);
    var id = orderItem.orderId > 0 ? (orderItem.orderId - 1) : 0;
    await _boxOrder.put(orderItem.orderId, orderItem);
  }
}
