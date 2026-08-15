import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/product/models/product.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  void _addProductToCart() {
    final product = widget.product;

    // Find the product currently in the cart.
    final existingItems = CartStore.items.where(
      (item) => item.product.id == product.id,
    );

    final bool alreadyInCart = existingItems.isNotEmpty;

    final int currentQuantity = alreadyInCart
        ? existingItems.first.quantity
        : 0;

    // If the maximum available quantity is already
    // in the cart, don't add anything.
    if (currentQuantity >= product.quantity) {
      _showCartMessage(
        'Maximum available quantity reached '
        '(${product.quantity}).',
      );
      return;
    }

    // Add one more unit.
    CartStore.addToCart(product);

    // Get the updated quantity after adding.
    final updatedItems = CartStore.items.where(
      (item) => item.product.id == product.id,
    );

    final int updatedQuantity = updatedItems.isNotEmpty
        ? updatedItems.first.quantity
        : currentQuantity + 1;

    // If we have reached the maximum available stock.
    if (updatedQuantity >= product.quantity) {
      _showCartMessage(
        '${product.name} × $updatedQuantity added '
        '• Maximum available reached',
      );
    } else {
      _showCartMessage(
        '${product.name} × $updatedQuantity added to cart',
      );
    }

    setState(() {});
  }

  void _showCartMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    // Remove the currently displayed message instead
    // of allowing SnackBars to queue up.
    messenger.hideCurrentSnackBar(
      reason: SnackBarClosedReason.hide,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // Get current cart quantity for this product.
    final existingItems = CartStore.items.where(
      (item) => item.product.id == product.id,
    );

    final int cartQuantity = existingItems.isNotEmpty
        ? existingItems.first.quantity
        : 0;

    final bool stockLimitReached =
        cartQuantity >= product.quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // PRODUCT IMAGE
            // --------------------------------------------------

            Container(
              width: double.infinity,
              height: 220,

              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.agriculture,
                size: 100,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // PRODUCT NAME
            // --------------------------------------------------

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // PRICE
            // --------------------------------------------------

            Text(
              '₵${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // DESCRIPTION
            // --------------------------------------------------

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              product.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // FARMER
            // --------------------------------------------------

            ListTile(
              contentPadding: EdgeInsets.zero,

              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),

              title: const Text('Farmer'),

              subtitle: Text(
                product.farmerName,
              ),
            ),

            // --------------------------------------------------
            // AVAILABLE QUANTITY
            // --------------------------------------------------

            ListTile(
              contentPadding: EdgeInsets.zero,

              leading: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),

              title: const Text(
                'Available Quantity',
              ),

              subtitle: Text(
                '${product.quantity} units',
              ),
            ),

            // --------------------------------------------------
            // CURRENT CART QUANTITY
            // --------------------------------------------------

            if (cartQuantity > 0) ...[
              const SizedBox(height: 5),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.08),

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'In your cart: '
                        '$cartQuantity / '
                        '${product.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // --------------------------------------------------
            // ADD TO CART BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: stockLimitReached
                    ? null
                    : _addProductToCart,

                icon: Icon(
                  stockLimitReached
                      ? Icons.check_circle
                      : Icons.shopping_cart,
                ),

                label: Text(
                  stockLimitReached
                      ? 'Maximum Quantity Reached'
                      : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,

                  foregroundColor:
                      AppColors.white,

                  disabledBackgroundColor:
                      Colors.grey.shade400,

                  disabledForegroundColor:
                      Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
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