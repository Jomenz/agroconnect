import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/order/models/order.dart';
import 'package:agroconnect/features/buyer/presentation/buyer_home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

 void _placeOrder() {
  if (addressController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your delivery address.'),
      ),
    );
    return;
  }

  if (CartStore.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your cart is empty.'),
      ),
    );
    return;
  }

  final orderItems = CartStore.items.map((item) {
    return OrderItem(
      productName: item.product.name,
      price: item.product.price,
      quantity: item.quantity,
    );
  }).toList();

 final order = Order(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  items: orderItems,
  total: CartStore.total,
  deliveryAddress: addressController.text.trim(),

  // Temporary user information.
  // We will connect this to the actual logged-in users later.
  buyerName: 'Buyer',
  farmerName: CartStore.items.first.product.farmerName,

  date: DateTime.now(),
);
  // Save the order
  OrderStore.addOrder(order);

  // Clear the cart immediately
  CartStore.clearCart();

  // Return directly to the Buyer Dashboard
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const BuyerHomeScreen(),
    ),
    (route) => false,
  );

  // Show success message after reaching the dashboard
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Order placed successfully!'),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                hintText: 'Enter your delivery address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

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
                contentPadding: EdgeInsets.zero,
                title: Text(item.product.name),
                subtitle: Text(
                  '${item.quantity} × ₵${item.product.price.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '₵${item.totalPrice.toStringAsFixed(2)}',
                ),
              ),
            ),

            const Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
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

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}