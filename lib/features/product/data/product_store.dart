import '../models/product.dart';

class ProductStore {
  ProductStore._();

  static final List<Product> products = [
    Product(
      id: 'demo_001',
      name: 'Tomatoes',
      price: 25.00,
      quantity: 20,
      description: 'Fresh farm tomatoes.',
      farmerName: 'Demo Farmer',
      allowNegotiation: true,
      minimumPrice: 20.00,
    ),
    Product(
      id: 'demo_002',
      name: 'Maize',
      price: 18.00,
      quantity: 30,
      description: 'Quality locally grown maize.',
      farmerName: 'Demo Farmer',
      allowNegotiation: false,
    ),
    Product(
      id: 'demo_003',
      name: 'Mangoes',
      price: 15.00,
      quantity: 25,
      description: 'Fresh and sweet mangoes.',
      farmerName: 'Demo Farmer',
      allowNegotiation: true,
      minimumPrice: 12.00,
    ),
    Product(
      id: 'demo_004',
      name: 'Potatoes',
      price: 20.00,
      quantity: 40,
      description: 'Fresh farm potatoes.',
      farmerName: 'Demo Farmer',
      allowNegotiation: false,
    ),
  ];

  // --------------------------------------------------
  // ADD PRODUCT
  // --------------------------------------------------

  static bool addProduct(Product product) {
    if (!_isValidProduct(product)) {
      return false;
    }

    products.add(product);
    return true;
  }

  // --------------------------------------------------
  // UPDATE PRODUCT
  // --------------------------------------------------

  static bool updateProduct(Product updatedProduct) {
    final index = products.indexWhere(
      (product) => product.id == updatedProduct.id,
    );

    if (index == -1) {
      return false;
    }

    if (!_isValidProduct(updatedProduct)) {
      return false;
    }

    products[index] = updatedProduct;
    return true;
  }

  // --------------------------------------------------
  // VALIDATE PRODUCT
  // --------------------------------------------------

  static bool _isValidProduct(Product product) {
    // Product price must be positive.
    if (product.price <= 0) {
      return false;
    }

    // Product quantity must be positive.
    if (product.quantity <= 0) {
      return false;
    }

    // Product name must not be empty.
    if (product.name.trim().isEmpty) {
      return false;
    }

    // Product description must not be empty.
    if (product.description.trim().isEmpty) {
      return false;
    }

    // If negotiation is enabled,
    // a valid minimum price must be provided.
    if (product.allowNegotiation) {
      if (product.minimumPrice == null) {
        return false;
      }

      if (product.minimumPrice! <= 0) {
        return false;
      }

      // Minimum price cannot be greater than
      // the original listed price.
      if (product.minimumPrice! > product.price) {
        return false;
      }
    }

    return true;
  }

  // --------------------------------------------------
  // DELETE PRODUCT
  // --------------------------------------------------

  static bool deleteProduct(String productId) {
    final initialLength = products.length;

    products.removeWhere(
      (product) => product.id == productId,
    );

    return products.length < initialLength;
  }

  // --------------------------------------------------
  // REDUCE PRODUCT STOCK
  // --------------------------------------------------

  static bool reduceStock(
    String productId,
    int quantity,
  ) {
    final index = products.indexWhere(
      (product) => product.id == productId,
    );

    if (index == -1) {
      return false;
    }

    final product = products[index];

    // Quantity must be positive.
    if (quantity <= 0) {
      return false;
    }

    // Prevent stock from becoming negative.
    if (quantity > product.quantity) {
      return false;
    }

    product.quantity -= quantity;

    return true;
  }

  // --------------------------------------------------
  // RESTORE PRODUCT STOCK
  // --------------------------------------------------

  static bool restoreStock(
    String productId,
    int quantity,
  ) {
    final index = products.indexWhere(
      (product) => product.id == productId,
    );

    if (index == -1) {
      return false;
    }

    if (quantity <= 0) {
      return false;
    }

    products[index].quantity += quantity;

    return true;
  }

  // --------------------------------------------------
  // CHECK NEGOTIATED PRICE
  // --------------------------------------------------

  static bool isNegotiatedPriceValid(
    String productId,
    double proposedPrice,
  ) {
    final product = getProduct(productId);

    if (product == null) {
      return false;
    }

    // Proposed price must be greater than zero.
    if (proposedPrice <= 0) {
      return false;
    }

    // Negotiation must be enabled.
    if (!product.allowNegotiation) {
      return false;
    }

    // Negotiation requires a minimum price.
    if (product.minimumPrice == null) {
      return false;
    }

    // Buyer cannot offer below the farmer's minimum.
    if (proposedPrice < product.minimumPrice!) {
      return false;
    }

    // Buyer cannot offer more than the listed price.
    if (proposedPrice > product.price) {
      return false;
    }

    return true;
  }

  // --------------------------------------------------
  // GET PRODUCT
  // --------------------------------------------------

  static Product? getProduct(String productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // GET PRODUCT BY NAME
  // --------------------------------------------------

  static Product? getProductByName(String productName) {
    for (final product in products) {
      if (product.name == productName) {
        return product;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // GET NEGOTIATION MINIMUM PRICE
  // --------------------------------------------------

  static double? getMinimumPrice(String productId) {
    final product = getProduct(productId);

    if (product == null) {
      return null;
    }

    if (!product.allowNegotiation) {
      return null;
    }

    return product.minimumPrice;
  }

  // --------------------------------------------------
  // CHECK IF PRODUCT ALLOWS NEGOTIATION
  // --------------------------------------------------

  static bool canNegotiate(String productId) {
    final product = getProduct(productId);

    if (product == null) {
      return false;
    }

    return product.allowNegotiation &&
        product.minimumPrice != null;
  }
}