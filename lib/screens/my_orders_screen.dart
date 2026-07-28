import 'package:flutter/material.dart';
import 'package:grocery_voice_list/widgets/custom_elevated_button.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              return Expanded(
                child: provider.orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders found',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.orders.length,
                        itemBuilder: (context, index) {
                          return getOrderListWidget(
                            provider.orders,
                            index,
                            provider,
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget getOrderListWidget(
  List<OrderItem> orderItem,
  int position,
  OrderProvider provider,
) {
  OrderItem order = orderItem[position];
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              order.time,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            Text(
              order.status,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            order.isExpanded
                ? Expanded(child: showExpandedWidget(order))
                : Text(
                    order.itemList.take(3).map((e) => e.name).join(' , '),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            CustomElevatedButton(
              label: order.isExpanded ? 'Hide' : 'Show',
              width: 100,
              height: 35,
              onPressed: () {
                provider.toggleExpanded(position);
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Widget showExpandedWidget(OrderItem order) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    child: Column(
      children: order.itemList.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 20,),
              Text('->',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 20,),
              Text(
                '${item.quantity} ${item.unit}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
