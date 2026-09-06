import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:agroconnect/features/order/models/order.dart';

class OrderFirestoreService {
  OrderFirestoreService._();

  static final OrderFirestoreService instance =
      OrderFirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<void> createOrder(Order order) async {
    await _firestore.runTransaction(
      (transaction) async {
        final productSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};

        // --------------------------------------------------------
        // READ ALL PRODUCTS FIRST
        // --------------------------------------------------------

        for (final item in order.items) {
          if (item.productId.isEmpty) {
            throw Exception(
              'Product ID is missing for ${item.productName}.',
            );
          }

          final productRef = _products.doc(item.productId);
          final snapshot = await transaction.get(productRef);

          productSnapshots[item.productId] = snapshot;
        }

        // --------------------------------------------------------
        // VALIDATE STOCK
        // --------------------------------------------------------

        for (final item in order.items) {
          final snapshot = productSnapshots[item.productId];

          if (snapshot == null ||
              !snapshot.exists ||
              snapshot.data() == null) {
            throw Exception(
              'Product not found: ${item.productName}',
            );
          }

          final data = snapshot.data()!;
          final currentQuantity = _toInt(data['quantity']);

          if (currentQuantity <= 0) {
            throw Exception(
              'Out of stock: ${item.productName}',
            );
          }

          if (item.quantity > currentQuantity) {
            throw Exception(
              'Not enough stock for ${item.productName}. '
              'Only $currentQuantity available.',
            );
          }
        }

        // --------------------------------------------------------
        // REDUCE FIREBASE STOCK
        // --------------------------------------------------------

        for (final item in order.items) {
          final snapshot = productSnapshots[item.productId]!;

          final currentQuantity =
              _toInt(snapshot.data()?['quantity']);

          final productRef = _products.doc(item.productId);

          transaction.update(
            productRef,
            {
              'quantity': currentQuantity - item.quantity,
            },
          );
        }

        // --------------------------------------------------------
        // SAVE ORDER
        // --------------------------------------------------------

        final orderRef = _orders.doc(order.id);

        transaction.set(
          orderRef,
          order.toMap(),
        );
      },
    );
  }

  // ============================================================
  // GET SINGLE ORDER
  // ============================================================

  Future<Order?> getOrder(String orderId) async {
    final snapshot = await _orders.doc(orderId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return Order.fromMap(
      snapshot.data()!,
      snapshot.id,
    );
  }

  // ============================================================
  // BUYER ORDERS
  // ============================================================

  Stream<List<Order>> buyerOrdersStream(String buyerId) {
    return _orders
        .where(
          'buyerId',
          isEqualTo: buyerId,
        )
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map(
                  (doc) => Order.fromMap(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();

            orders.sort(
              (a, b) => b.date.compareTo(a.date),
            );

            return orders;
          },
        );
  }

  // ============================================================
  // FARMER ORDERS
  // ============================================================

  Stream<List<Order>> farmerOrdersStream(String farmerId) {
    return _orders
        .where(
          'farmerIds',
          arrayContains: farmerId,
        )
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map(
                  (doc) => Order.fromMap(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();

            orders.sort(
              (a, b) => b.date.compareTo(a.date),
            );

            return orders;
          },
        );
  }

  // ============================================================
  // ADMIN ORDERS
  // ============================================================

  Stream<List<Order>> adminOrdersStream() {
    return _orders.snapshots().map(
      (snapshot) {
        final orders = snapshot.docs
            .map(
              (doc) => Order.fromMap(
                doc.data(),
                doc.id,
              ),
            )
            .toList();

        orders.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        return orders;
      },
    );
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    await _firestore.runTransaction(
      (transaction) async {
        final orderRef = _orders.doc(orderId);

        final orderSnapshot =
            await transaction.get(orderRef);

        if (!orderSnapshot.exists ||
            orderSnapshot.data() == null) {
          throw Exception(
            'Order not found.',
          );
        }

        final order = Order.fromMap(
          orderSnapshot.data()!,
          orderSnapshot.id,
        );

        // --------------------------------------------------------
        // RESTORE STOCK WHEN A PENDING ORDER IS REJECTED
        // --------------------------------------------------------

        if (order.status == 'Pending' &&
            newStatus == 'Rejected') {
          final productSnapshots =
              <String,
                  DocumentSnapshot<Map<String, dynamic>>>{};

          // Read products first.
          for (final item in order.items) {
            if (item.productId.isEmpty) {
              continue;
            }

            final productRef =
                _products.doc(item.productId);

            final snapshot =
                await transaction.get(
              productRef,
            );

            productSnapshots[item.productId] =
                snapshot;
          }

          // Restore stock.
          for (final item in order.items) {
            if (item.productId.isEmpty) {
              continue;
            }

            final snapshot =
                productSnapshots[item.productId];

            if (snapshot == null ||
                !snapshot.exists ||
                snapshot.data() == null) {
              continue;
            }

            final currentQuantity =
                _toInt(
              snapshot.data()?['quantity'],
            );

            final productRef =
                _products.doc(item.productId);

            transaction.update(
              productRef,
              {
                'quantity':
                    currentQuantity + item.quantity,
              },
            );
          }
        }

        // --------------------------------------------------------
        // UPDATE ORDER STATUS
        // --------------------------------------------------------

        transaction.update(
          orderRef,
          {
            'status': newStatus,
          },
        );
      },
    );
  }

  // ============================================================
  // INTEGER CONVERSION HELPER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}