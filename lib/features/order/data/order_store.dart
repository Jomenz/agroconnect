import '../models/order.dart';
import 'package:agroconnect/features/product/data/product_store.dart';

class OrderStore {
  OrderStore._();

  static final List<Order> orders = [];

  // --------------------------------------------------
  // ADD ORDER
  // --------------------------------------------------

  static void addOrder(Order order) {
    orders.add(order);
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

    // ------------------------------------------------
    // RESTORE STOCK ONLY WHEN:
    //
    // Pending → Rejected
    //
    // This prevents completed/accepted orders from
    // changing stock and also prevents a rejected order
    // from restoring stock more than once.
    // ------------------------------------------------

    if (oldStatus == 'Pending' &&
        newStatus == 'Rejected') {
      // First verify that every product in the order
      // can be found before changing any stock.
      for (final item in order.items) {
        final product = ProductStore.getProductByName(
          item.productName,
        );

        if (product == null) {
          return false;
        }
      }

      // Restore each product's quantity.
      for (final item in order.items) {
        final product = ProductStore.getProductByName(
          item.productName,
        );

        if (product == null) {
          return false;
        }

        final restored = ProductStore.restoreStock(
          product.id,
          item.quantity,
        );

        if (!restored) {
          return false;
        }
      }
    }

    order.status = newStatus;

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

    return orders.length < initialLength;
  }

  // --------------------------------------------------
  // CLEAR ORDERS
  // --------------------------------------------------

  static void clearOrders() {
    orders.clear();
  }
}