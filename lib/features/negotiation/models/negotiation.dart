class Negotiation {
  final String id;

  final String productId;
  final String productName;

  final String buyerId;
  final String buyerName;
  final String farmerId;
  final String farmerName;

  final int quantity;

  final double originalPrice;

  double buyerOffer;
  double? farmerCounterOffer;

  // The final price agreed upon by both parties.
  // Null means that the negotiation has not been accepted yet.
  double? agreedPrice;

  String status;

  Negotiation({
    required this.id,
    required this.productId,
    required this.productName,
    this.buyerId = '',
    required this.buyerName,
    this.farmerId = '',
    required this.farmerName,
    required this.quantity,
    required this.originalPrice,
    required this.buyerOffer,
    this.farmerCounterOffer,
    this.agreedPrice,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'quantity': quantity,
      'originalPrice': originalPrice,
      'buyerOffer': buyerOffer,
      'farmerCounterOffer': farmerCounterOffer,
      'agreedPrice': agreedPrice,
      'status': status,
    };
  }

  factory Negotiation.fromMap(Map<String, dynamic> map, String id) {
    return Negotiation(
      id: id,
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? '',
      farmerId: map['farmerId']?.toString() ?? '',
      farmerName: map['farmerName']?.toString() ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      originalPrice: (map['originalPrice'] is num)
          ? (map['originalPrice'] as num).toDouble()
          : 0.0,
      buyerOffer: (map['buyerOffer'] is num)
          ? (map['buyerOffer'] as num).toDouble()
          : 0.0,
      farmerCounterOffer: (map['farmerCounterOffer'] is num)
          ? (map['farmerCounterOffer'] as num).toDouble()
          : null,
      agreedPrice: (map['agreedPrice'] is num)
          ? (map['agreedPrice'] as num).toDouble()
          : null,
      status: map['status']?.toString() ?? 'Pending',
    );
  }
}