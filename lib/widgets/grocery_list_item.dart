import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/grocery_item.dart';
import '../utils/constants.dart';
import '../utils/unit_converter.dart';

class GroceryListItem extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onVoice;

  const GroceryListItem({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final category = GroceryCategoryExt.fromStorageKey(item.categoryKey);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ],
        ),
        child: _ItemCard(
          item: item,
          category: category,
          onToggle: onToggle,
          onVoice: onVoice,
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final GroceryItem item;
  final GroceryCategory category;
  final VoidCallback onToggle;
  final VoidCallback onVoice;

  const _ItemCard({
    required this.item,
    required this.category,
    required this.onToggle,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catColor = category.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: item.isChecked
            ? colorScheme.surfaceContainerLow
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isChecked
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
          child: Row(
            children: [
              // Category color indicator
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isChecked ? catColor.withOpacity(0.3) : catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Category icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? catColor.withOpacity(0.08)
                      : catColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 18,
                  color: item.isChecked ? catColor.withOpacity(0.4) : catColor,
                ),
              ),
              const SizedBox(width: 12),
              // Item name + notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(
                        item.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? colorScheme.surfaceContainerHigh
                      : catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  UnitConverter.formatQuantity(item.quantity, item.unit),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.isChecked
                        ? colorScheme.onSurface.withOpacity(0.4)
                        : catColor,
                  ),
                ),
              ),
              // Mic button overlay trigger
              IconButton(
                onPressed: onVoice,
                icon: Icon(
                  Icons.mic_rounded,
                  size: 20,
                  color: item.isChecked
                      ? colorScheme.onSurface.withOpacity(0.25)
                      : colorScheme.primary.withOpacity(0.7),
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: 'Voice update',
              ),
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: item.isChecked
                        ? Icon(Icons.check_circle_rounded,
                            key: const ValueKey('checked'),
                            color: colorScheme.primary,
                            size: 26)
                        : Icon(Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('unchecked'),
                            color: colorScheme.outlineVariant,
                            size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
