import 'package:agroconnect/features/product/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];

  static void addToCart(Product product) {
    final existingItem = items.where(
      (item) => item.product.name == product.name,
    );

    if (existingItem.isNotEmpty) {
      existingItem.first.quantity++;
    } else {
      items.add(
        CartItem(product: product),
      );
    }
  }

  static void increaseQuantity(CartItem item) {
    item.quantity++;
  }

  static void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
  }

  static void removeItem(CartItem item) {
    items.remove(item);
  }

  static double get total {
    return items.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  static void clearCart() {
    items.clear();
  }
}