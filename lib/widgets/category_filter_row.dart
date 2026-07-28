import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grocery_provider.dart';
import '../utils/constants.dart';

class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroceryProvider>();
    final counts = provider.categoryCounts;
    final selected = provider.selectedCategory;

    final categories = GroceryCategory.values
        .where((c) => (counts[c] ?? 0) > 0)
        .toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          final count = category == GroceryCategory.all
              ? provider.uncheckedItems
              : (counts[category] ?? 0);

          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            count: count,
            onTap: () => provider.setCategory(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final GroceryCategory category;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = category.color;
    final label = count > 0
        ? '${category.displayName}  $count'
        : category.displayName;

    return RawChip(
      selected: isSelected,
      onPressed: onTap,
      avatar: Icon(
        category.icon,
        size: 15,
        color: isSelected ? Colors.white : catColor,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected ? Colors.white : colorScheme.onSurface,
        letterSpacing: 0,
      ),
      backgroundColor: colorScheme.surface,
      selectedColor: catColor,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      side: BorderSide(
        color: isSelected ? catColor : colorScheme.outlineVariant,
        width: 1,
      ),
    );
  }
}
