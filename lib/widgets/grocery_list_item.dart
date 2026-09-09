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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(14),
              ),
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
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ],
        ),
        child: _ItemCard(
          item: item,
          category: category,
          onToggle: onToggle,
          onEdit: onEdit,
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
  final VoidCallback onEdit;
  final VoidCallback onVoice;

  const _ItemCard({
    required this.item,
    required this.category,
    required this.onToggle,
    required this.onEdit,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isChecked
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 3, bottom: 3, right: 2),
          child: Row(
            children: [
              // Category color indicator
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? catColor.withValues(alpha: 0.3)
                      : catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              // Category icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? catColor.withValues(alpha: 0.08)
                      : catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 16,
                  color: item.isChecked
                      ? catColor.withValues(alpha: 0.4)
                      : catColor,
                ),
              ),
              const SizedBox(width: 9),
              // Item name + notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isChecked
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(
                        item.notes!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? colorScheme.surfaceContainerHigh
                      : catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  UnitConverter.formatQuantity(item.quantity, item.unit),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.isChecked
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : catColor,
                  ),
                ),
              ),
              // Mic button overlay trigger
              IconButton(
                onPressed: onVoice,
                icon: Icon(
                  Icons.mic_rounded,
                  size: 18,
                  color: item.isChecked
                      ? colorScheme.onSurface.withValues(alpha: 0.25)
                      : colorScheme.primary.withValues(alpha: 0.7),
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(40, 40),
                  maximumSize: const Size(40, 40),
                  padding: const EdgeInsets.all(6),
                ),
                tooltip: 'Voice update',
              ),
              // Checkbox
              InkResponse(
                onTap: onToggle,
                radius: 20,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: item.isChecked
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('checked'),
                            color: colorScheme.primary,
                            size: 23,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('unchecked'),
                            color: colorScheme.outlineVariant,
                            size: 23,
                          ),
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
