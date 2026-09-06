import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String buyerId;
  final String buyerName;
  final List<OrderItem> items;
  final double total;
  final String deliveryAddress;
  final String fulfillmentMethod;
  String status;
  final DateTime date;

  Order({
    required this.id,
    this.buyerId = '',
    this.buyerName = '',
    required this.items,
    required this.total,
    required this.deliveryAddress,
    this.fulfillmentMethod = 'Delivery',
    this.status = 'Pending',
    required this.date,
  });

  /// All farmer IDs represented in this order.
  List<String> get farmerIds {
    return items
        .map((item) => item.farmerId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'items': items.map((item) => item.toMap()).toList(),
      'farmerIds': farmerIds,
      'total': total,
      'deliveryAddress': deliveryAddress,
      'fulfillmentMethod': fulfillmentMethod,
      'status': status,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Order.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    DateTime parsedDate;

    final dateRaw = map['date'];

    if (dateRaw is Timestamp) {
      parsedDate = dateRaw.toDate();
    } else if (dateRaw is String) {
      parsedDate =
          DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawItems = map['items'];

    List<OrderItem> itemsList = [];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          itemsList.add(
            OrderItem.fromMap(
              Map<String, dynamic>.from(rawItem),
            ),
          );
        }
      }
    }

    return Order(
      id: id,
      buyerId:
          map['buyerId']?.toString() ?? '',
      buyerName:
          map['buyerName']?.toString() ?? '',
      items: itemsList,
      total: _toDouble(map['total']),
      deliveryAddress:
          map['deliveryAddress']?.toString() ?? '',
      fulfillmentMethod:
          map['fulfillmentMethod']?.toString() ??
              'Delivery',
      status:
          map['status']?.toString() ?? 'Pending',
      date: parsedDate,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String farmerId;
  final String farmerName;
  final double price;
  final int quantity;

  OrderItem({
    this.productId = '',
    required this.productName,
    this.farmerId = '',
    this.farmerName = '',
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return OrderItem(
      productId:
          map['productId']?.toString() ?? '',
      productName:
          map['productName']?.toString() ?? '',
      farmerId:
          map['farmerId']?.toString() ?? '',
      farmerName:
          map['farmerName']?.toString() ?? '',
      price: _toDouble(map['price']),
      quantity: _toInt(map['quantity']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        1;
  }
}