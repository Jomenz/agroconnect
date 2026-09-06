import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import 'package:agroconnect/features/product/data/product_store.dart';

class OrderStore {
  OrderStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final List<Order> orders = [];
  static bool _isInitialized = false;

  // --------------------------------------------------
  // INITIALIZE FIRESTORE LISTENER
  // --------------------------------------------------

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _firestore.collection('orders').snapshots().listen((snapshot) {
        final loaded = snapshot.docs.map((doc) {
          return Order.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort descending by date
        loaded.sort((a, b) => b.date.compareTo(a.date));

        orders.clear();
        orders.addAll(loaded);
      }, onError: (error) {
        debugPrint('OrderStore Firestore listener error: $error');
      });
    } catch (e) {
      debugPrint('OrderStore initialize failed: $e');
    }
  }

  // --------------------------------------------------
  // ADD ORDER
  // --------------------------------------------------

  static void addOrder(Order order) {
    orders.insert(0, order);

    _firestore
        .collection('orders')
        .doc(order.id)
        .set(order.toMap())
        .catchError((error) {
      debugPrint('Firestore addOrder error: $error');
    });
  }

  // --------------------------------------------------
  // GET ORDER
  // --------------------------------------------------

  static Order? getOrder(String orderId) {
    try {
      return orders.firstWhere(
        (order) => order.id == orderId,
      );
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------
  // UPDATE ORDER STATUS
  // --------------------------------------------------

  static bool updateOrderStatus(
    String orderId,
    String newStatus,
  ) {
    final index = orders.indexWhere(
      (order) => order.id == orderId,
    );

    if (index == -1) {
      return false;
    }

    final order = orders[index];
    final oldStatus = order.status;

    // Restore stock when Pending -> Rejected
    if (oldStatus == 'Pending' && newStatus == 'Rejected') {
      for (final item in order.items) {
        final product = ProductStore.getProductByName(item.productName);
        if (product == null) {
          return false;
        }
      }

      for (final item in order.items) {
        final product = ProductStore.getProductByName(item.productName);
        if (product != null) {
          ProductStore.restoreStock(product.id, item.quantity);
        }
      }
    }

    order.status = newStatus;

    _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus})
        .catchError((error) {
      debugPrint('Firestore updateOrderStatus error: $error');
    });

    return true;
  }

  // --------------------------------------------------
  // REMOVE ORDER
  // --------------------------------------------------

  static bool removeOrder(String orderId) {
    final initialLength = orders.length;

    orders.removeWhere(
      (order) => order.id == orderId,
    );

    _firestore
        .collection('orders')
        .doc(orderId)
        .delete()
        .catchError((error) {
      debugPrint('Firestore removeOrder error: $error');
    });

    return orders.length < initialLength;
  }

  // --------------------------------------------------
  // CLEAR ORDERS
  // --------------------------------------------------

  static void clearOrders() {
    orders.clear();
  }
}