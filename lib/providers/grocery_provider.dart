import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_item.dart';
import '../services/hive_service.dart';
import '../services/voice_parser.dart';
import '../utils/constants.dart';
import '../utils/unit_converter.dart';

class GroceryProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<GroceryItem> _items = [];
  GroceryCategory _selectedCategory = GroceryCategory.all;
  bool _showChecked = true;
  String _searchQuery = '';

  // Undo stack: stores deleted items
  final List<GroceryItem> _undoStack = [];

  // ── Getters ───────────────────────────────────────────────────────────────

  List<GroceryItem> get allItems => List.unmodifiable(_items);

  List<GroceryItem> get filteredItems {
    var list = _items.where((item) {
      if (!_showChecked && item.isChecked) return false;
      if (_selectedCategory != GroceryCategory.all) {
        if (item.categoryKey != _selectedCategory.storageKey) return false;
      }
      if (_searchQuery.isNotEmpty) {
        if (!item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Unchecked first, then checked; within each group sort by creation time
    list.sort((a, b) {
      if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  GroceryCategory get selectedCategory => _selectedCategory;
  bool get showChecked => _showChecked;
  String get searchQuery => _searchQuery;
  bool get canUndo => _undoStack.isNotEmpty;

  int get totalItems => _items.length;
  int get checkedItems => _items.where((i) => i.isChecked).length;
  int get uncheckedItems => _items.where((i) => !i.isChecked).length;

  Map<GroceryCategory, int> get categoryCounts {
    final counts = <GroceryCategory, int>{};
    for (final item in _items) {
      if (_showChecked || !item.isChecked) {
        final cat = GroceryCategoryExt.fromStorageKey(item.categoryKey);
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> loadItems() async {
    _items = HiveService.getAllGrocery();
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<String> addItem({
    required String name,
    required double quantity,
    required String unit,
    required String categoryKey,
    String? notes,
  }) async {
    // Check for existing item with same name (case-insensitive)
    final existing = _findItemByName(name);
    if (existing != null) {
      // Merge quantities if same or compatible units
      final merged = UnitConverter.mergeQuantities(
        existing.quantity,
        existing.unit,
        quantity,
        unit,
      );
      if (merged != null) {
        existing.quantity = merged;
        await HiveService.save(existing);
        _sortItems();
        notifyListeners();
        return 'Updated ${existing.name}: ${UnitConverter.formatQuantity(merged, existing.unit)}';
      }
    }

    final item = GroceryItem(
      id: _uuid.v4(),
      name: name,
      quantity: quantity,
      unit: unit,
      categoryKey: categoryKey,
      createdAt: DateTime.now(),
      notes: notes,
    );
    _items.add(item);
    await HiveService.save(item);
    _sortItems();
    notifyListeners();
    return 'Added ${UnitConverter.formatQuantity(quantity, unit)} $name';
  }

  Future<String?> addMoreToItem(
    String name,
    double quantity,
    String unit,
  ) async {
    final item = _findItemByName(name);
    if (item == null) {
      // Item doesn't exist, just add it
      await addItem(
        name: name,
        quantity: quantity,
        unit: unit,
        categoryKey:
            VoiceParser.parse('add $name').categoryKey ??
            GroceryCategory.other.storageKey,
      );
      return 'Added $name (new item)';
    }
    final merged = UnitConverter.mergeQuantities(
      item.quantity,
      item.unit,
      quantity,
      unit,
    );
    if (merged != null) {
      item.quantity = merged;
      await HiveService.save(item);
      notifyListeners();
      return 'Updated ${item.name}: ${UnitConverter.formatQuantity(merged, item.unit)}';
    }
    return 'Could not update ${item.name} — incompatible units';
  }

  Future<String?> subtractFromItem(
    String name,
    double quantity,
    String unit,
  ) async {
    final item = _findItemByName(name);
    if (item == null) return 'Item "$name" not found in the list';

    // Convert subtracted quantity to item's unit
    double subtractInItemUnit;
    if (item.unit == unit) {
      subtractInItemUnit = quantity;
    } else if (UnitConverter.isSameUnitFamily(item.unit, unit)) {
      final baseSubtract = UnitConverter.toBaseUnit(quantity, unit);
      final baseItem = UnitConverter.toBaseUnit(1.0, item.unit);
      subtractInItemUnit = baseSubtract / baseItem;
    } else {
      return 'Cannot subtract $unit from ${item.unit} for ${item.name}';
    }

    final newQty = item.quantity - subtractInItemUnit;
    if (newQty <= 0) {
      // Quantity reaches zero — remove the item
      return deleteItem(item.id);
    }

    item.quantity = newQty;
    await HiveService.save(item);
    notifyListeners();
    return 'Updated ${item.name}: ${UnitConverter.formatQuantity(newQty, item.unit)}';
  }

  Future<String?> setItemQuantity(
    String name,
    double quantity,
    String unit,
  ) async {
    final item = _findItemByName(name);
    if (item == null) return 'Item "$name" not found in the list';
    if (quantity <= 0) return deleteItem(item.id);

    item.quantity = quantity;
    item.unit = unit;
    await HiveService.save(item);
    notifyListeners();
    return 'Updated ${item.name}: ${UnitConverter.formatQuantity(quantity, unit)}';
  }

  Future<String?> updateItem(GroceryItem updated) async {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx == -1) return null;
    _items[idx] = updated;
    await HiveService.save(updated);
    _sortItems();
    notifyListeners();
    return 'Updated ${updated.name}';
  }

  Future<String?> deleteItem(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return null;
    final item = _items[idx];
    _items.removeAt(idx);
    await HiveService.delete(id);
    _undoStack.add(item);
    if (_undoStack.length > 10) _undoStack.removeAt(0);
    notifyListeners();
    return 'Deleted ${item.name}';
  }

  Future<String?> deleteItemByName(String name) async {
    final item = _findItemByName(name);
    if (item == null) return 'Item "$name" not found';
    return deleteItem(item.id);
  }

  Future<String?> toggleChecked(String id) async {
    final item = _items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw StateError(''),
    );
    item.isChecked = !item.isChecked;
    await HiveService.save(item);
    _sortItems();
    notifyListeners();
    return item.isChecked ? 'Checked ${item.name}' : 'Unchecked ${item.name}';
  }

  Future<String?> checkItemByName(String name) async {
    final item = _findItemByName(name);
    if (item == null) return 'Item "$name" not found';
    item.isChecked = true;
    await HiveService.save(item);
    _sortItems();
    notifyListeners();
    return 'Checked ${item.name}';
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final item = _undoStack.removeLast();
    _items.add(item);
    await HiveService.save(item);
    _sortItems();
    notifyListeners();
  }

  void clearUndoStack() {
    _undoStack.clear();
  }

  Future<void> clearChecked() async {
    final toDelete = _items.where((i) => i.isChecked).map((i) => i.id).toList();
    for (final id in toDelete) {
      _items.removeWhere((i) => i.id == id);
      await HiveService.delete(id);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await HiveService.deleteAll();
    notifyListeners();
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setCategory(GroceryCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleShowChecked() {
    _showChecked = !_showChecked;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  GroceryItem? _findItemByName(String name) {
    try {
      return _items.firstWhere((i) => VoiceParser.itemNamesMatch(i.name, name));
    } catch (_) {
      return null;
    }
  }

  void _sortItems() {
    _items.sort((a, b) {
      if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
}
