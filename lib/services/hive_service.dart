import 'package:hive_flutter/hive_flutter.dart';
import '../models/grocery_item.dart';
import '../utils/constants.dart';

class HiveService {
  static late Box<GroceryItem> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryItemAdapter());
    }
    _box = await Hive.openBox<GroceryItem>(kGroceryBox);
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
    await _box.clear();
  }

  static Future<void> close() async {
    await _box.close();
  }
}
