import 'package:flutter/material.dart';
import 'package:groceryvoicelist/widgets/order_list_item.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../providers/order_provider.dart';
import '../utils/app_colors.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

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
            itemBuilder: (_, index) =>
                OrderListItemItem(orderItem: provider.orders[index], index: index,
                onDelete: ()=>{provider.removeOrder(index)},),
          );
        },
      ),
    );
  }
}
