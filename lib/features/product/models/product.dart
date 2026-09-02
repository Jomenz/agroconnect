class Product {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String description;
  final String farmerName;

  // Price negotiation settings
  final bool allowNegotiation;
  final double? minimumPrice;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.farmerName,
    this.allowNegotiation = false,
    this.minimumPrice,
  });
}