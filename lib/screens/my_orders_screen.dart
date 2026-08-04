import 'package:flutter/material.dart';
import 'package:grocery_voice_list/utils/app_colors.dart';
import 'package:provider/provider.dart';

import '../models/order_item.dart';
import '../providers/order_provider.dart';

enum OrderStatus { delivered, pending, cancelled }

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
          if (provider.orders.isEmpty||provider.orders.first.itemList.isEmpty) {
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
            itemBuilder: (_, index) => getOrderListWidget(index, provider,context),
          );
        },
      ),
    );
  }
}

Widget getOrderListWidget(int index, OrderProvider provider, BuildContext context) {
  final order = provider.orders[index];

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: AppColors.of(context).surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 5,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  color: Colors.green.shade700,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.itemList.take(3).map((e) => e.name).join(" • ") +
                          (order.itemList.length > 3
                              ? " +${order.itemList.length - 3} more"
                              : ""),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      order.time,
                      style: TextStyle(color: Colors.grey.shade600,fontSize: 13),
                    ),
                  ],
                ),
              ),

              IconButton(
                splashRadius: 22,
                onPressed: () => provider.toggleExpanded(index),
                icon: AnimatedRotation(
                  turns: order.isExpanded ? .5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${order.itemList.length} Items",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        order.isExpanded ? Container(
          padding: EdgeInsets.all(10),
          child: showExpandedWidget(order),
        ) : SizedBox(),
      ],
    ),
  );
}

Widget showExpandedWidget(OrderItem order) {
  return Column(
    children: order.itemList.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 15,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${item.quantity} ${item.unit}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
