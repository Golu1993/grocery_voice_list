import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_voice_list/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../utils/constants.dart';

class EditItemScreen extends StatefulWidget {
  final GroceryItem? item; // null = add new item manually

  const EditItemScreen({super.key, this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _notesCtrl;
  late String _selectedUnit;
  late GroceryCategory _selectedCategory;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _quantityCtrl = TextEditingController(
      text: item != null ? _formatQty(item.quantity) : '1',
    );
    _notesCtrl = TextEditingController(text: item?.notes ?? '');
    _selectedUnit = item?.unit ?? 'piece';
    _selectedCategory = item != null
        ? GroceryCategoryExt.fromStorageKey(item.categoryKey)
        : GroceryCategory.other;
  }

  String _formatQty(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<GroceryProvider>();
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 1.0;

    if (_isEditing) {
      final updated = widget.item!.copyWith(
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: _selectedUnit,
        categoryKey: _selectedCategory.storageKey,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await provider.updateItem(updated);
    } else {
      await provider.addItem(
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: _selectedUnit,
        categoryKey: _selectedCategory.storageKey,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title:_isEditing ? 'Edit Item' : 'Add Item',showBackButton: true,),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.shopping_cart_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter item name' : null,
            ),
            const SizedBox(height: 16),

            // Quantity + Unit row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    items: kUnits.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text('${kUnitDisplay[u] ?? u} ($u)'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GroceryCategory.values
                  .where((c) => c != GroceryCategory.all)
                  .map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  avatar: Icon(cat.icon, size: 16),
                  label: Text(cat.displayName),
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Brand, variety, etc.',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
              label: Text(_isEditing ? 'Save Changes' : 'Add to List'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
