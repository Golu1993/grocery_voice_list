import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_field.dart';
import '../models/grocery_item.dart';
import '../services/firestore_query.dart';
import '../services/voice_parser.dart';
import '../utils/constants.dart';
import '../utils/unit_converter.dart';

class GroceryProvider extends ChangeNotifier {
  GroceryProvider({this.firestoreQuery});

  final _uuid = const Uuid();
  final FirestoreQuery? firestoreQuery;
  Future<void> _writeQueue = Future.value();

  FirestoreQuery get _queries =>
      firestoreQuery ?? (throw StateError('Order storage is unavailable.'));

  List<GroceryItem> _items = [];
  GroceryCategory _selectedCategory = GroceryCategory.all;
  bool _showChecked = true;
  String _searchQuery = '';

  // Undo stack: stores deleted items
  final List<GroceryItem> _undoStack = [];
  final Set<String> _pinningItemIds = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<GroceryItem> get allItems => List.unmodifiable(_items);

  bool isPinning(String id) => _pinningItemIds.contains(id);

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

    list.sort(GroceryItem.compareForDisplay);
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
    _items = await _queries.getActiveItems();
    notifyListeners();
  }

  Future<void> _saveItems() {
    final snapshot = _items.map((item) => item.copyWith()).toList();
    final write = _writeQueue.then((_) => _queries.saveItems(snapshot));
    final result = write.onError((error, stack) async {
      try {
        _items = await _queries.getActiveItems();
        notifyListeners();
      } catch (_) {
        // Keep the original write error for the caller to show.
      }
      Error.throwWithStackTrace(
        error ?? StateError('Item write failed.'),
        stack,
      );
    });
    _writeQueue = result.catchError((Object _) {});
    return result;
  }

  Future<String> startNewList() async {
    await _writeQueue;
    final uuid = await _queries.startNewList();
    _items.clear();
    _undoStack.clear();
    notifyListeners();
    return uuid;
  }

  Future<void> editSavedList(String uuid) async {
    await _writeQueue;
    await _queries.activateOrder(uuid);
    _items = await _queries.getActiveItems();
    _undoStack.clear();
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
        await _saveItems();
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
    await _saveItems();
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
      await _saveItems();
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
    await _saveItems();
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
    await _saveItems();
    notifyListeners();
    return 'Updated ${item.name}: ${UnitConverter.formatQuantity(quantity, unit)}';
  }

  Future<String?> updateItem(GroceryItem updated) async {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx == -1) return null;
    _items[idx] = updated;
    await _saveItems();
    _sortItems();
    notifyListeners();
    return 'Updated ${updated.name}';
  }

  Future<void> mergeSavedItems(Iterable<GroceryField> savedItems) async {
    for (final savedItem in savedItems) {
      final existing = _findItemByName(savedItem.name);
      if (existing != null) {
        final merged = UnitConverter.mergeQuantities(
          existing.quantity,
          existing.unit,
          savedItem.quantity,
          savedItem.unit,
        );
        if (merged != null) {
          existing.quantity = merged;
          existing.isChecked = false;
          existing.isPinned = existing.isPinned || savedItem.isPinned;
          continue;
        }
      }

      final parsed = VoiceParser.parse('add ${savedItem.name}');
      final item = GroceryItem(
        id: _uuid.v4(),
        name: savedItem.name,
        quantity: savedItem.quantity,
        unit: savedItem.unit,
        categoryKey:
            savedItem.categoryKey ??
            parsed.categoryKey ??
            GroceryCategory.other.storageKey,
        isChecked: false,
        isPinned: savedItem.isPinned,
        createdAt: savedItem.createdAt ?? DateTime.now(),
        notes: savedItem.notes,
      );
      _items.add(item);
    }

    _sortItems();
    await _saveItems();
    notifyListeners();
  }

  Future<String?> deleteItem(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return null;
    final item = _items[idx];
    _items.removeAt(idx);
    await _saveItems();
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
    await _saveItems();
    _sortItems();
    notifyListeners();
    return item.isChecked ? 'Checked ${item.name}' : 'Unchecked ${item.name}';
  }

  Future<void> togglePinned(String id) async {
    if (_pinningItemIds.contains(id)) return;
    final item = _items.firstWhere((item) => item.id == id);
    final wasPinned = item.isPinned;
    _pinningItemIds.add(id);
    item.isPinned = !wasPinned;
    _sortItems();
    notifyListeners();
    try {
      await _saveItems();
    } catch (_) {
      for (final current in _items) {
        if (current.id == id) current.isPinned = wasPinned;
      }
      _sortItems();
      rethrow;
    } finally {
      _pinningItemIds.remove(id);
      notifyListeners();
    }
  }

  Future<String?> checkItemByName(String name) async {
    final item = _findItemByName(name);
    if (item == null) return 'Item "$name" not found';
    item.isChecked = true;
    await _saveItems();
    _sortItems();
    notifyListeners();
    return 'Checked ${item.name}';
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final item = _undoStack.removeLast();
    _items.add(item);
    await _saveItems();
    _sortItems();
    notifyListeners();
  }

  void clearUndoStack() {
    _undoStack.clear();
  }

  Future<void> clearChecked() async {
    _items.removeWhere((item) => item.isChecked);
    await _saveItems();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _saveItems();
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
    _items.sort(GroceryItem.compareForDisplay);
  }
}
