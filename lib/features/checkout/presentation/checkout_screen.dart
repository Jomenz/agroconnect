import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/order/models/order.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/buyer/presentation/buyer_home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController addressController =
      TextEditingController();

  String fulfillmentMethod = 'Delivery';

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // PLACE ORDER
  // --------------------------------------------------

  void _placeOrder() {
    // --------------------------------------------------
    // 1. CHECK CART
    // --------------------------------------------------

    if (CartStore.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    // --------------------------------------------------
    // 2. CHECK DELIVERY ADDRESS
    // --------------------------------------------------

    if (fulfillmentMethod == 'Delivery' &&
        addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your delivery address.',
          ),
        ),
      );
      return;
    }

    // --------------------------------------------------
    // 3. CHECK STOCK BEFORE CREATING ORDER
    // --------------------------------------------------

    for (final cartItem in CartStore.items) {
      final product = ProductStore.products.firstWhere(
        (product) => product.id == cartItem.product.id,
        orElse: () => cartItem.product,
      );

      if (cartItem.quantity > product.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock for ${product.name}. '
              'Only ${product.quantity} available.',
            ),
          ),
        );
        return;
      }
    }

    // --------------------------------------------------
    // 4. CREATE ORDER ITEMS
    // --------------------------------------------------

    final orderItems = CartStore.items.map((item) {
      return OrderItem(
        productName: item.product.name,
        price: item.product.price,
        quantity: item.quantity,
      );
    }).toList();

    // --------------------------------------------------
    // 5. CREATE ORDER
    // --------------------------------------------------

    final order = Order(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      items: orderItems,
      total: CartStore.total,
      deliveryAddress:
          fulfillmentMethod == 'Delivery'
              ? addressController.text.trim()
              : 'Customer will pick up',
      fulfillmentMethod: fulfillmentMethod,
      date: DateTime.now(),
    );

    // --------------------------------------------------
    // 6. DEDUCT STOCK
    // --------------------------------------------------

    for (final cartItem in CartStore.items) {
      final success = ProductStore.reduceStock(
        cartItem.product.id,
        cartItem.quantity,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update stock for ${cartItem.product.name}.',
            ),
          ),
        );
        return;
      }
    }

    // --------------------------------------------------
    // 7. SAVE ORDER
    // --------------------------------------------------

    OrderStore.addOrder(order);

    // --------------------------------------------------
    // 8. CLEAR CART
    // --------------------------------------------------

    CartStore.clearCart();

    // --------------------------------------------------
    // 9. RETURN TO BUYER DASHBOARD
    // --------------------------------------------------

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerHomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDelivery =
        fulfillmentMethod == 'Delivery';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // FULFILLMENT METHOD
            // --------------------------------------------------

            const Text(
              'Fulfillment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // DELIVERY
            Card(
              child: RadioListTile<String>(
                value: 'Delivery',
                groupValue: fulfillmentMethod,

                onChanged: (value) {
                  setState(() {
                    fulfillmentMethod = value!;
                  });
                },

                title: const Text(
                  'Delivery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'Have your order delivered to you.',
                ),

                secondary: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),

            // PICKUP
            Card(
              child: RadioListTile<String>(
                value: 'Pickup',
                groupValue: fulfillmentMethod,

                onChanged: (value) {
                  setState(() {
                    fulfillmentMethod = value!;
                  });
                },

                title: const Text(
                  'Pickup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'Collect your order from the farmer.',
                ),

                secondary: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // DELIVERY ADDRESS
            // --------------------------------------------------

            if (isDelivery) ...[
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: addressController,
                maxLines: 3,

                decoration: InputDecoration(
                  hintText:
                      'Enter your delivery address',

                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],

            // --------------------------------------------------
            // PICKUP INFORMATION
            // --------------------------------------------------

            if (!isDelivery) ...[
              Card(
                color:
                    AppColors.primary.withOpacity(0.08),

                child: const Padding(
                  padding: EdgeInsets.all(16),

                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront,
                        color: AppColors.primary,
                        size: 30,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'You will collect this order directly from the farmer.',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],

            // --------------------------------------------------
            // ORDER SUMMARY
            // --------------------------------------------------

            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ...CartStore.items.map(
              (item) => ListTile(
                contentPadding:
                    EdgeInsets.zero,

                title: Text(
                  item.product.name,
                ),

                subtitle: Text(
                  '${item.quantity} × ₵${item.product.price.toStringAsFixed(2)}',
                ),

                trailing: Text(
                  '₵${item.totalPrice.toStringAsFixed(2)}',
                ),
              ),
            ),

            const Divider(),

            // --------------------------------------------------
            // TOTAL
            // --------------------------------------------------

            ListTile(
              contentPadding:
                  EdgeInsets.zero,

              title: const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              trailing: Text(
                '₵${CartStore.total.toStringAsFixed(2)}',

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // PLACE ORDER BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: _placeOrder,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      AppColors.white,
                ),

                child: const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}