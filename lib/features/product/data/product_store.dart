import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductStore {
  ProductStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<Product> products = [];
  static bool _isInitialized = false;

  static final List<Product> _defaultInitialProducts = [
    Product(
      id: 'demo_001',
      name: 'Tomatoes',
      price: 25.00,
      quantity: 20,
      description: 'Fresh farm tomatoes.',
      farmerName: 'Demo Farmer',
      farmerId: 'demo_farmer_01',
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
      farmerId: 'demo_farmer_01',
      allowNegotiation: false,
    ),
    Product(
      id: 'demo_003',
      name: 'Mangoes',
      price: 15.00,
      quantity: 25,
      description: 'Fresh and sweet mangoes.',
      farmerName: 'Demo Farmer',
      farmerId: 'demo_farmer_01',
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
      farmerId: 'demo_farmer_01',
      allowNegotiation: false,
    ),
  ];

  // --------------------------------------------------
  // INITIALIZE FIRESTORE LISTENER
  // --------------------------------------------------

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Populate initial products in local list as fallback
    if (products.isEmpty) {
      products.addAll(_defaultInitialProducts);
    }

    try {
      _firestore.collection('products').snapshots().listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          // If Firestore collection is empty, seed with initial demo products
          _seedDefaultProducts();
        } else {
          final loaded = snapshot.docs.map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          }).toList();

          products.clear();
          products.addAll(loaded);
        }
      }, onError: (error) {
        debugPrint('ProductStore Firestore listener error: $error');
      });
    } catch (e) {
      debugPrint('ProductStore initialize failed: $e');
    }
  }

  static Future<void> _seedDefaultProducts() async {
    try {
      final batch = _firestore.batch();
      for (final product in _defaultInitialProducts) {
        final docRef = _firestore.collection('products').doc(product.id);
        batch.set(docRef, product.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to seed default products: $e');
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