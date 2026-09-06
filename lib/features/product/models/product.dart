class Product {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String description;
  final String farmerName;
  final String farmerId;
  final String? imageUrl;
  final String? imageBase64;

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
    this.farmerId = '',
    this.imageUrl,
    this.imageBase64,
    this.allowNegotiation = false,
    this.minimumPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'farmerName': farmerName,
      'farmerId': farmerId,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'allowNegotiation': allowNegotiation,
      'minimumPrice': minimumPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name']?.toString() ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 0,
      description: map['description']?.toString() ?? '',
      farmerName: map['farmerName']?.toString() ?? '',
      farmerId: map['farmerId']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      imageBase64: map['imageBase64']?.toString(),
      allowNegotiation: map['allowNegotiation'] == true,
      minimumPrice: (map['minimumPrice'] is num)
          ? (map['minimumPrice'] as num).toDouble()
          : null,
    );
  }
}