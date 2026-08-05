import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:groceryvoicelist/models/order_item.dart';
import 'package:groceryvoicelist/providers/order_provider.dart';
import 'package:provider/provider.dart';

import '../utils/app_colors.dart';

class OrderListItemItem extends StatelessWidget {
  const OrderListItemItem({
    super.key,
    required this.orderItem,
    required this.index,
    required this.onDelete,
  });

  final OrderItem orderItem;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final orderProvider = context.read<OrderProvider>();
    final isActive = orderItem.isCurrent;
    final itemCount = orderItem.itemList.length;
    final preview = orderItem.itemList
        .take(2)
        .map((item) => item.name)
        .join(' • ');
    final title = preview + (itemCount > 2 ? ' +${itemCount - 2} more' : '');

    return Slidable(
      key: ValueKey('order-${orderItem.orderId}'),
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
          onTap: () => orderProvider.toggleExpanded(index),
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            orderItem.time,
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
                    Text(
                      orderItem.isExpanded ? 'Hide items' : 'View items',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
                        ...orderItem.itemList.map(
                          (item) => _OrderItemRow(
                            name: item.name,
                            quantity: '${item.quantity} ${item.unit}',
                            isChecked: item.isChecked ?? false,
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
  });

  final String name;
  final String quantity;
  final bool isChecked;

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
