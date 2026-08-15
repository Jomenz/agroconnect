import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/order/data/order_store.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Refresh the screen periodically so changes made by the
    // farmer are reflected on the buyer's side.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blue;

      case 'Preparing':
        return Colors.orange;

      case 'Ready':
        return Colors.purple;

      case 'Completed':
        return Colors.green;

      case 'Rejected':
        return Colors.red;

      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderStore.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),

      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Your orders will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )

          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,

              itemBuilder: (context, index) {
                final order = orders[index];

                final statusColor = _statusColor(
                  order.status,
                );

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),

                  elevation: 2,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // --------------------------------
                        // ORDER HEADER
                        // --------------------------------

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              'Order #${order.id.substring(order.id.length - 6)}',

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(
                                  0.15,
                                ),

                                borderRadius:
                                    BorderRadius.circular(20),
                              ),

                              child: Text(
                                order.status,

                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // --------------------------------
                        // STATUS MESSAGE
                        // --------------------------------

                        if (order.status == 'Accepted')
                          _StatusMessage(
                            icon: Icons.check_circle_outline,
                            color: Colors.blue,
                            message:
                                'Your order has been accepted by the farmer.',
                          ),

                        if (order.status == 'Preparing')
                          _StatusMessage(
                            icon: Icons.inventory_2_outlined,
                            color: Colors.orange,
                            message:
                                'The farmer is preparing your order.',
                          ),

                        if (order.status == 'Ready')
                          _StatusMessage(
                            icon: Icons.done_all,
                            color: Colors.purple,
                            message:
                                'Your order is ready for delivery or pickup.',
                          ),

                        if (order.status == 'Completed')
                          _StatusMessage(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            message:
                                'Your order has been completed.',
                          ),

                        if (order.status == 'Rejected')
                          _StatusMessage(
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                            message:
                                'Unfortunately, the farmer rejected this order.',
                          ),

                        if (order.status == 'Pending')
                          _StatusMessage(
                            icon: Icons.hourglass_empty,
                            color: Colors.orange,
                            message:
                                'Your order is waiting for the farmer to respond.',
                          ),

                        const SizedBox(height: 15),

                        // --------------------------------
                        // PRODUCTS
                        // --------------------------------

                        const Text(
                          'Products',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ...order.items.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 6,
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} × ${item.quantity}',
                                  ),
                                ),

                                Text(
                                  '₵${item.total.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(),

                        // --------------------------------
                        // TOTAL
                        // --------------------------------

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              '₵${order.total.toStringAsFixed(2)}',

                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // --------------------------------
                        // FULFILLMENT METHOD
                        // --------------------------------

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Icon(
                              order.fulfillmentMethod ==
                                      'Delivery'
                                  ? Icons
                                      .local_shipping_outlined
                                  : Icons
                                      .storefront_outlined,

                              size: 20,

                              color:
                                  AppColors.primary,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                order.fulfillmentMethod ==
                                        'Delivery'
                                    ? 'Delivery: ${order.deliveryAddress}'
                                    : 'Pickup: Customer will collect the order from the farmer.',

                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --------------------------------------------------
// STATUS MESSAGE
// --------------------------------------------------

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,

              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}