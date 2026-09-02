import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/order/models/order.dart';
import 'package:agroconnect/features/product/data/product_store.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() =>
      _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState
    extends State<FarmerOrdersScreen> {

  // --------------------------------------------------
  // STATUS COLOR
  // --------------------------------------------------

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

  // --------------------------------------------------
  // RESTORE STOCK FOR REJECTED ORDER
  // --------------------------------------------------

  bool _restoreOrderStock(Order order) {
    for (final item in order.items) {
      final product =
          ProductStore.getProductByName(item.productName);

      if (product == null) {
        return false;
      }
    }

    for (final item in order.items) {
      final product =
          ProductStore.getProductByName(item.productName);

      if (product == null) {
        return false;
      }

      final restored = ProductStore.restoreStock(
        product.id,
        item.quantity,
      );

      if (!restored) {
        return false;
      }
    }

    return true;
  }

  // --------------------------------------------------
  // UPDATE ORDER STATUS
  // --------------------------------------------------

  void _updateOrderStatus(
    Order order,
    String newStatus,
  ) {
    final oldStatus = order.status;

    // -----------------------------------------------
    // ONLY RESTORE STOCK FOR:
    // Pending → Rejected
    // -----------------------------------------------

    if (oldStatus == 'Pending' &&
        newStatus == 'Rejected') {
      final restored = _restoreOrderStock(order);

      if (!restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to restore product stock. '
              'Order status was not changed.',
            ),
          ),
        );

        return;
      }
    }

    final success = OrderStore.updateOrderStatus(
      order.id,
      newStatus,
    );

    if (!success) {
      // If stock was restored but the order status failed
      // to update, restore the previous stock state by
      // reducing it again.
      if (oldStatus == 'Pending' &&
          newStatus == 'Rejected') {
        for (final item in order.items) {
          final product =
              ProductStore.getProductByName(
            item.productName,
          );

          if (product != null) {
            ProductStore.reduceStock(
              product.id,
              item.quantity,
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update order status.',
          ),
        ),
      );

      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order marked as $newStatus.',
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BUILD ACTION BUTTONS
  // --------------------------------------------------

  Widget _buildActionButtons(Order order) {
    // --------------------------------------------------
    // PENDING
    // --------------------------------------------------

    if (order.status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Rejected',
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(
                  color: Colors.red,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Reject',
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Accepted',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Accept',
              ),
            ),
          ),
        ],
      );
    }

    // --------------------------------------------------
    // ACCEPTED
    // --------------------------------------------------

    if (order.status == 'Accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _updateOrderStatus(
              order,
              'Preparing',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Start Preparing Order',
          ),
        ),
      );
    }

    // --------------------------------------------------
    // PREPARING
    // --------------------------------------------------

    if (order.status == 'Preparing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _updateOrderStatus(
              order,
              'Ready',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Mark as Ready',
          ),
        ),
      );
    }

    // --------------------------------------------------
    // READY
    // --------------------------------------------------

    if (order.status == 'Ready') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _updateOrderStatus(
              order,
              'Completed',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Complete Order',
          ),
        ),
      );
    }

    // --------------------------------------------------
    // REJECTED / COMPLETED
    // --------------------------------------------------

    return const SizedBox();
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orders = OrderStore.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incoming Orders',
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),

      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
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
                    'Orders from buyers will appear here.',
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

                final statusColor =
                    _statusColor(order.status);

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
                        // ORDER TOTAL
                        // --------------------------------

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₵${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
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
                              color: AppColors.primary,
                              size: 22,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                order.fulfillmentMethod ==
                                        'Delivery'
                                    ? 'Delivery Address: ${order.deliveryAddress}'
                                    : 'Pickup: Customer will collect the order from the farmer.',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --------------------------------
                        // ACTION BUTTONS
                        // --------------------------------

                        _buildActionButtons(order),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}