import 'package:flutter/material.dart';
import 'package:vocart/widgets/order_list_item.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/order_provider.dart';
import '../services/firestore_query_guard.dart';
import '../utils/app_colors.dart';
import 'grocery_pdf_preview_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, required this.onShowHome});

  final VoidCallback onShowHome;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshOrders();
    });
  }

  Future<void> _refreshOrders() async {
    try {
      await context.read<OrderProvider>().refreshOrders();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (error is FirestoreQueryFailure &&
        error.kind == FirestoreQueryFailureKind.offline) {
      // The app-wide connection alert already explains this failure.
      return;
    }
    final message = error is FirestoreQueryFailure
        ? error.message
        : error.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not update lists: $message')));
  }

  Future<void> _openList(OrderItem order) async {
    if (order.isCurrent) {
      widget.onShowHome();
      return;
    }

    final hasCurrentItems = context.read<GroceryProvider>().totalItems > 0;
    final action = await showDialog<_OpenListAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Open this list?')),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            ),
          ],
        ),
        content: const Text('Choose how you want to open this list.'),
        actions: [
          if (hasCurrentItems)
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _OpenListAction.merge),
              child: const Text(
                'Merge',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _OpenListAction.newList),
            child: const Text(
              'New List',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _OpenListAction.edit),
            child: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    final grocery = context.read<GroceryProvider>();
    final orderProvider = context.read<OrderProvider>();
    try {
      if (action == _OpenListAction.merge) {
        await grocery.mergeSavedItems(order.itemList);
        await orderProvider.refreshOrders();
      } else if (action == _OpenListAction.newList) {
        final uuid = await grocery.startNewList();
        orderProvider.setActiveOrder(uuid);
        await grocery.mergeSavedItems(order.itemList);
        await orderProvider.refreshOrders();
      } else {
        await grocery.editSavedList(order.uuid);
        await orderProvider.showEditedOrder(order.uuid);
      }

      if (!mounted) return;
      widget.onShowHome();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).surfaceContainerLowest,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrderProvider>(
              builder: (context, provider, _) {
                final visibleOrders = provider.orders
                    .where((order) => order.itemList.isNotEmpty)
                    .toList();
                if (visibleOrders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No lists with items yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add items to a list to see it here.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: visibleOrders.length,
                  itemBuilder: (context, visibleIndex) {
                    final order = visibleOrders[visibleIndex];
                    return OrderListItemItem(
                      key: ValueKey(order.uuid),
                      orderItem: order,
                      index: visibleIndex,
                      isPinning: provider.isPinning(order.uuid),
                      onTogglePinned: () async {
                        try {
                          await provider.togglePinned(order.uuid);
                        } catch (error) {
                          if (mounted) _showError(error);
                        }
                      },
                      onDelete: () async {
                        try {
                          await provider.removeOrder(order.uuid);
                        } catch (error) {
                          if (mounted) _showError(error);
                        }
                      },
                      onOpen: () => _openList(order),
                      onToggleExpanded: () =>
                          provider.toggleExpanded(order.uuid),
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

enum _OpenListAction { merge, newList, edit }
