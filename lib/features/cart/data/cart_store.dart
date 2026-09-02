import 'package:agroconnect/features/product/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  // The price agreed upon through negotiation.
  // Null means the buyer is using the original
  // listed price.
  double? negotiatedPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.negotiatedPrice,
  });

  // --------------------------------------------------
  // EFFECTIVE PRICE
  // --------------------------------------------------

  double get effectivePrice {
    return negotiatedPrice ?? product.price;
  }

  // --------------------------------------------------
  // TOTAL PRICE
  // --------------------------------------------------

  double get totalPrice {
    return effectivePrice * quantity;
  }

  // --------------------------------------------------
  // AVAILABLE QUANTITY
  // --------------------------------------------------

  int get availableQuantity {
    return product.quantity;
  }

  // --------------------------------------------------
  // IS NEGOTIATED
  // --------------------------------------------------

  bool get isNegotiated {
    return negotiatedPrice != null;
  }
}

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];

  // --------------------------------------------------
  // ADD TO CART
  // --------------------------------------------------

  static bool addToCart(
    Product product, {
    double? negotiatedPrice,
  }) {
    // Product is out of stock.
    if (product.quantity <= 0) {
      return false;
    }

    // If a negotiated price is supplied,
    // validate it before adding it to the cart.
    if (negotiatedPrice != null) {
      if (!ProductStoreHelper.isValidNegotiatedPrice(
        product,
        negotiatedPrice,
      )) {
        return false;
      }
    }

    final existingItems = items.where(
      (item) => item.product.id == product.id,
    );

    if (existingItems.isNotEmpty) {
      final item = existingItems.first;

      // Don't allow the buyer to exceed available stock.
      if (item.quantity >= product.quantity) {
        return false;
      }

      // If a negotiated price is supplied, update the
      // existing cart item's negotiated price.
      if (negotiatedPrice != null) {
        item.negotiatedPrice = negotiatedPrice;
      }

      item.quantity++;
    } else {
      items.add(
        CartItem(
          product: product,
          negotiatedPrice: negotiatedPrice,
        ),
      );
    }

    return true;
  }

  // --------------------------------------------------
  // SET NEGOTIATED PRICE
  // --------------------------------------------------

  static bool setNegotiatedPrice(
    CartItem item,
    double proposedPrice,
  ) {
    if (!ProductStoreHelper.isValidNegotiatedPrice(
      item.product,
      proposedPrice,
    )) {
      return false;
    }

    item.negotiatedPrice = proposedPrice;

    return true;
  }

  // --------------------------------------------------
  // APPLY NEGOTIATED PRICE BY PRODUCT ID
  // --------------------------------------------------
  //
  // Used when a farmer accepts a buyer's offer.
  // The agreed price is then applied to the buyer's
  // existing cart item.

  static bool applyNegotiatedPrice(
    String productId,
    double agreedPrice,
  ) {
    if (agreedPrice <= 0) {
      return false;
    }

    try {
      final item = items.firstWhere(
        (item) => item.product.id == productId,
      );

      item.negotiatedPrice = agreedPrice;

      return true;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------
  // CLEAR NEGOTIATED PRICE BY PRODUCT ID
  // --------------------------------------------------
  //
  // Used when a farmer rejects a buyer's negotiation.
  // The cart item then returns to the original
  // listed product price.

  static bool clearNegotiatedPriceByProduct(
    String productId,
  ) {
    try {
      final item = items.firstWhere(
        (item) => item.product.id == productId,
      );

      item.negotiatedPrice = null;

      return true;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------
  // CLEAR NEGOTIATED PRICE
  // --------------------------------------------------

  static void clearNegotiatedPrice(CartItem item) {
    item.negotiatedPrice = null;
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

// --------------------------------------------------
// NEGOTIATED PRICE VALIDATION HELPER
// --------------------------------------------------
//
// This helper keeps the farmer's minimum price hidden
// from the buyer-facing UI.
//
// It uses the ProductStore's private negotiation rules
// internally.

class ProductStoreHelper {
  static bool isValidNegotiatedPrice(
    Product product,
    double proposedPrice,
  ) {
    if (proposedPrice <= 0) {
      return false;
    }

    if (!product.allowNegotiation) {
      return false;
    }

    if (product.minimumPrice == null) {
      return false;
    }

    if (proposedPrice < product.minimumPrice!) {
      return false;
    }

    if (proposedPrice > product.price) {
      return false;
    }

    return true;
  }
}