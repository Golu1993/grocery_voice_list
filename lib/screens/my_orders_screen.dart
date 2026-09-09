import 'package:flutter/material.dart';
import 'package:vocart/widgets/order_list_item.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/order_provider.dart';
import '../utils/app_colors.dart';
import 'grocery_pdf_preview_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, required this.onShowHome});

  final VoidCallback onShowHome;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().refreshOrders();
    });
  }

  Future<void> _openList(OrderItem order) async {
    if (order.isCurrent) {
      widget.onShowHome();
      return;
    }

    final action = await showDialog<_OpenListAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open this list?'),
        content: const Text(
          'Merge it with your current list or open it as a new list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _OpenListAction.merge),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _OpenListAction.newList),
            child: const Text('New List'),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    final grocery = context.read<GroceryProvider>();
    if (action == _OpenListAction.merge) {
      await grocery.mergeSavedItems(order.itemList);
    } else {
      await grocery.openSavedItemsAsNew(order.itemList);
    }

    if (!mounted) return;
    await context.read<OrderProvider>().refreshOrders();
    if (mounted) widget.onShowHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surfaceContainerLowest,
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.orders.isEmpty ||
              provider.orders.first.itemList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No Orders Yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Your grocery orders will appear here.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              return OrderListItemItem(
                orderItem: order,
                index: index,
                onDelete: () => provider.removeOrder(index),
                onOpen: () => _openList(order),
                onToggleExpanded: () => provider.toggleExpanded(index),
                onShare: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroceryPdfPreviewScreen(order: order),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _OpenListAction { merge, newList }
