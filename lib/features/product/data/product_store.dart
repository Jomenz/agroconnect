import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductStore {
  ProductStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<Product> products = [];
  static bool _isInitialized = false;

  // --------------------------------------------------
  // INITIALIZE FIRESTORE LISTENER
  // --------------------------------------------------

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _firestore.collection('products').snapshots().listen((snapshot) {
        final loaded = snapshot.docs.map((doc) {
          return Product.fromMap(doc.data(), doc.id);
        }).toList();

        products.clear();
        products.addAll(loaded);
      }, onError: (error) {
        debugPrint('ProductStore Firestore listener error: $error');
      });
    } catch (e) {
      debugPrint('ProductStore initialize failed: $e');
    }
  }

  // --------------------------------------------------
  // ADD PRODUCT
  // --------------------------------------------------

  static bool addProduct(Product product) {
    if (!_isValidProduct(product)) {
      return false;
    }

    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
    } else {
      products.add(product);
    }

    // Persist to Cloud Firestore
    _firestore
        .collection('products')
        .doc(product.id)
        .set(product.toMap())
        .catchError((error) {
      debugPrint('Firestore addProduct error: $error');
    });

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

    // Update in Cloud Firestore
    _firestore
        .collection('products')
        .doc(updatedProduct.id)
        .set(updatedProduct.toMap(), SetOptions(merge: true))
        .catchError((error) {
      debugPrint('Firestore updateProduct error: $error');
    });

    return true;
  }

  // --------------------------------------------------
  // VALIDATE PRODUCT
  // --------------------------------------------------

  static bool _isValidProduct(Product product) {
    if (product.price <= 0) {
      return false;
    }

    if (product.quantity <= 0) {
      return false;
    }

    if (product.name.trim().isEmpty) {
      return false;
    }

    if (product.description.trim().isEmpty) {
      return false;
    }

    if (product.allowNegotiation) {
      if (product.minimumPrice == null) {
        return false;
      }

      if (product.minimumPrice! <= 0) {
        return false;
      }

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

    // Delete in Cloud Firestore
    _firestore
        .collection('products')
        .doc(productId)
        .delete()
        .catchError((error) {
      debugPrint('Firestore deleteProduct error: $error');
    });

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

    if (quantity <= 0) {
      return false;
    }

    if (quantity > product.quantity) {
      return false;
    }

    product.quantity -= quantity;

    _firestore
        .collection('products')
        .doc(productId)
        .update({'quantity': product.quantity})
        .catchError((error) {
      debugPrint('Firestore reduceStock error: $error');
    });

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

    _firestore
        .collection('products')
        .doc(productId)
        .update({'quantity': products[index].quantity})
        .catchError((error) {
      debugPrint('Firestore restoreStock error: $error');
    });

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
      if (product.name.toLowerCase() == productName.toLowerCase()) {
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

    return product.allowNegotiation && product.minimumPrice != null;
  }
}