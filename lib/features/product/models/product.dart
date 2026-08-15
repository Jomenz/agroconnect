class Product {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String description;
  final String farmerName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.farmerName,
  });
}