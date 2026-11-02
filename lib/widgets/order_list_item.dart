import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:vocart/models/order_item.dart';

import '../utils/app_colors.dart';
import 'pin_button.dart';

class OrderListItemItem extends StatelessWidget {
  const OrderListItemItem({
    super.key,
    required this.orderItem,
    required this.index,
    required this.onDelete,
    required this.onShare,
    required this.onOpen,
    required this.onToggleExpanded,
    required this.onTogglePinned,
    this.isPinning = false,
  });

  final OrderItem orderItem;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onOpen;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTogglePinned;
  final bool isPinning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isActive = orderItem.isCurrent;
    final itemCount = orderItem.itemList.length;

    return Slidable(
      key: ValueKey('order-${orderItem.orderId}'),
      enabled: !isActive,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: .25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.shopping_basket_outlined
                            : Icons.receipt_long_outlined,
                        color: isActive
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderItem.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            orderItem.updatedAt == null
                                ? orderItem.time
                                : 'Updated ${DateFormat('MMM d, yyyy h:mm a').format(orderItem.updatedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(isActive: isActive),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: orderItem.isExpanded ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 17,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    PinButton(
                      isPinned: orderItem.isPinned,
                      isSaving: isPinning,
                      onPressed: onTogglePinned,
                      label: orderItem.storeName,
                    ),
                    TextButton(
                      onPressed: onToggleExpanded,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(88, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        foregroundColor: colors.onSurfaceVariant,
                        textStyle: Theme.of(context).textTheme.labelMedium,
                      ),
                      child: Text(
                        orderItem.isExpanded ? 'Hide items' : 'View items',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: onShare,
                      tooltip: 'Share this list as PDF',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        maximumSize: const Size(40, 40),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 19),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Divider(height: 1, color: colors.outlineVariant),
                        const SizedBox(height: 12),
                        if (orderItem.itemList.isEmpty)
                          Text(
                            'No items in this list yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          )
                        else
                          ...orderItem.itemList.map(
                            (item) => _OrderItemRow(
                              name: item.name,
                              quantity: '${item.quantity} ${item.unit}',
                              isChecked: item.isChecked ?? false,
                              isPinned: item.isPinned,
                            ),
                          ),
                      ],
                    ),
                  ),
                  crossFadeState: orderItem.isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Saved',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.name,
    required this.quantity,
    required this.isChecked,
    required this.isPinned,
  });

  final String name;
  final String quantity;
  final bool isChecked;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 19,
            color: isChecked ? colors.primary : colors.outline,
          ),
          const SizedBox(width: 10),
          if (isPinned) ...[
            Icon(Icons.push_pin_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isChecked ? colors.onSurfaceVariant : colors.onSurface,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            quantity,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
