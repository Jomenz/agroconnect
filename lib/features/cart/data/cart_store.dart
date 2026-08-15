import 'package:agroconnect/features/product/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  // Maximum quantity the buyer can add.
  int get availableQuantity => product.quantity;
}

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];

  // --------------------------------------------------
  // ADD TO CART
  // --------------------------------------------------

  static bool addToCart(Product product) {
    // Product is out of stock.
    if (product.quantity <= 0) {
      return false;
    }

    final existingItem = items.where(
      (item) => item.product.id == product.id,
    );

    if (existingItem.isNotEmpty) {
      final item = existingItem.first;

      // Don't allow the buyer to exceed available stock.
      if (item.quantity >= product.quantity) {
        return false;
      }

      item.quantity++;
    } else {
      items.add(
        CartItem(
          product: product,
        ),
      );
    }

    return true;
  }

  // --------------------------------------------------
  // INCREASE QUANTITY
  // --------------------------------------------------

  static bool increaseQuantity(CartItem item) {
    if (item.quantity >= item.product.quantity) {
      return false;
    }

    item.quantity++;
    return true;
  }

  // --------------------------------------------------
  // DECREASE QUANTITY
  // --------------------------------------------------

  static void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
  }

  // --------------------------------------------------
  // REMOVE ITEM
  // --------------------------------------------------

  static void removeItem(CartItem item) {
    items.remove(item);
  }

  // --------------------------------------------------
  // TOTAL
  // --------------------------------------------------

  static double get total {
    return items.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  // --------------------------------------------------
  // CLEAR CART
  // --------------------------------------------------

  static void clearCart() {
    items.clear();
  }
}