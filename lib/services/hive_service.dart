import 'package:grocery_voice_list/models/order_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  static List<GroceryItem> getAll() {
    return _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> save(GroceryItem item) async {
    await _box.put(item.id, item);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static Future<void> deleteAll() async {
   await saveToOrderBox();
    await _box.clear();
  }

  static Future<void> close() async {
    await _box.close();
  }

  static Future<void> saveToOrderBox() async {
    await _boxOrder.put(DateTime.now().toString(), getAllGroceryItems());
  }


  static List<OrderItem> getAllOrders() {
    return _boxOrder.values.toList();
  }

  static OrderItem getAllGroceryItems() {
    final groceries = getAll();
    return OrderItem(
      time: DateTime.now().toString(),
      storeName: 'My Store',
      itemCount: groceries.length,
      amount: 0,
      // Calculate if you have prices
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
}
