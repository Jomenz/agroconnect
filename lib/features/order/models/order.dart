class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final String deliveryAddress;
  final String buyerName;
  final String farmerName;
  String status;
  final DateTime date;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.deliveryAddress,
    required this.buyerName,
    required this.farmerName,
    this.status = 'Pending',
    required this.date,
  });
}

class OrderItem {
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}