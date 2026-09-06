import 'package:agroconnect/features/product/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  final String buyerId;

  double? negotiatedPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.buyerId = '',
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
  static String? _currentBuyerId;

  static void setCurrentBuyerId(String? buyerId) {
    if (_currentBuyerId != buyerId) {
      _currentBuyerId = buyerId;
      items.clear();
    }
  }

  static List<CartItem> get itemsForCurrentUser {
    final buyerId = _currentBuyerId;
    if (buyerId == null || buyerId.isEmpty) return const [];
    return items.where((item) => item.buyerId == buyerId).toList();
  }

  static bool _isCurrentUser(String? buyerId) {
    return buyerId != null &&
        buyerId.isNotEmpty &&
        buyerId == _currentBuyerId;
  }

  // --------------------------------------------------
  // ADD TO CART
  // --------------------------------------------------

  static bool addToCart(
    Product product, {
    double? negotiatedPrice,
  }) {
    final buyerId = _currentBuyerId ?? '';
    if (buyerId.isEmpty) return false;

    if (product.quantity <= 0) {
      return false;
    }

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

      if (item.quantity >= product.quantity) {
        return false;
      }

      if (negotiatedPrice != null) {
        item.negotiatedPrice = negotiatedPrice;
      }

      item.quantity++;
    } else {
      items.add(
        CartItem(
          product: product,
          buyerId: buyerId,
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
    if (!_isCurrentUser(item.buyerId)) {
      return false;
    }

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
      final item = itemsForCurrentUser.firstWhere(
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
      final item = itemsForCurrentUser.firstWhere(
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
    if (_isCurrentUser(item.buyerId)) {
      item.negotiatedPrice = null;
    }
  }

  // --------------------------------------------------
  // INCREASE QUANTITY
  // --------------------------------------------------

  static bool increaseQuantity(CartItem item) {
    if (!_isCurrentUser(item.buyerId)) {
      return false;
    }

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
    if (!_isCurrentUser(item.buyerId)) {
      return;
    }

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
    if (_isCurrentUser(item.buyerId)) {
      items.remove(item);
    }
  }

  // --------------------------------------------------
  // TOTAL
  // --------------------------------------------------

  static double get total {
    return itemsForCurrentUser.fold(
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
