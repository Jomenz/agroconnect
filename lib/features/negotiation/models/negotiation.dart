class Negotiation {
  final String id;

  final String productId;
  final String productName;

  final String buyerName;
  final String farmerName;

  final int quantity;

  final double originalPrice;

  double buyerOffer;
  double? farmerCounterOffer;

  // The final price agreed upon by both parties.
  //
  // Null means that the negotiation has not
  // been accepted yet.
  double? agreedPrice;

  String status;

  Negotiation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerName,
    required this.farmerName,
    required this.quantity,
    required this.originalPrice,
    required this.buyerOffer,
    this.farmerCounterOffer,
    this.agreedPrice,
    this.status = 'Pending',
  });
}