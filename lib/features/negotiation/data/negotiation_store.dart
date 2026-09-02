import '../models/negotiation.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';

class NegotiationStore {
  static final List<Negotiation> negotiations = [];

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------

  static bool addNegotiation(Negotiation negotiation) {
    if (negotiation.quantity <= 0) {
      return false;
    }

    if (negotiation.buyerOffer <= 0) {
      return false;
    }

    if (negotiation.buyerOffer > negotiation.originalPrice) {
      return false;
    }

    negotiations.add(negotiation);
    return true;
  }

  // ------------------------------------------------------------
  // FIND
  // ------------------------------------------------------------

  static Negotiation? findById(String id) {
    try {
      return negotiations.firstWhere(
        (negotiation) => negotiation.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  static List<Negotiation> findByBuyer(String buyerName) {
    return negotiations
        .where((negotiation) => negotiation.buyerName == buyerName)
        .toList();
  }

  static List<Negotiation> findByFarmer(String farmerName) {
    return negotiations
        .where((negotiation) => negotiation.farmerName == farmerName)
        .toList();
  }

  static Negotiation? findByProduct(String productId) {
    for (int i = negotiations.length - 1; i >= 0; i--) {
      if (negotiations[i].productId == productId) {
        return negotiations[i];
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // NEGOTIATION STATUS
  // ------------------------------------------------------------

  static bool hasPendingNegotiation(String productId) {
    final negotiation = findByProduct(productId);

    if (negotiation == null) {
      return false;
    }

    return negotiation.status == 'Pending' ||
        negotiation.status == 'Countered';
  }

  // ------------------------------------------------------------
  // CHECKOUT
  // ------------------------------------------------------------

  static bool canCheckoutProduct(String productId) {
    final negotiation = findByProduct(productId);

    // No negotiation exists.
    if (negotiation == null) {
      return true;
    }

    // Pending or countered negotiations must be resolved first.
    if (negotiation.status == 'Pending' ||
        negotiation.status == 'Countered') {
      return false;
    }

    // Accepted -> buyer can checkout using agreed price.
    if (negotiation.status == 'Accepted') {
      return true;
    }

    // Rejected -> buyer can checkout using original price.
    if (negotiation.status == 'Rejected') {
      return true;
    }

    return true;
  }

  static String checkoutBlockMessage(String productId) {
    final negotiation = findByProduct(productId);

    if (negotiation == null) {
      return '';
    }

    if (negotiation.status == 'Pending') {
      return 'This product has a pending negotiation. '
          'Wait for the farmer to respond before checkout.';
    }

    if (negotiation.status == 'Countered') {
      return 'The farmer has made a counter offer. '
          'Respond to the counter offer before checkout.';
    }

    return '';
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  static double getMinimumPrice(Negotiation negotiation) {
    return negotiation.originalPrice;
  }

  static bool isNegotiatedPriceValid(
    String productId,
    double price,
  ) {
    final negotiation = findByProduct(productId);

    if (negotiation == null) {
      return false;
    }

    return price > 0 &&
        price <= negotiation.originalPrice;
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  static bool updateNegotiation(Negotiation negotiation) {
    final index = negotiations.indexWhere(
      (item) => item.id == negotiation.id,
    );

    if (index == -1) {
      return false;
    }

    negotiations[index] = negotiation;
    return true;
  }

  static bool updateStatus(
    String negotiationId,
    String newStatus,
  ) {
    final negotiation = findById(negotiationId);

    if (negotiation == null) {
      return false;
    }

    negotiation.status = newStatus;
    return true;
  }

  // ------------------------------------------------------------
  // FARMER COUNTER OFFER
  // ------------------------------------------------------------

  static bool setFarmerCounterOffer(
    String negotiationId,
    double counterOffer,
  ) {
    final negotiation = findById(negotiationId);

    if (negotiation == null) {
      return false;
    }

    if (counterOffer <= 0 ||
        counterOffer > negotiation.originalPrice) {
      return false;
    }

    negotiation.farmerCounterOffer = counterOffer;
    negotiation.agreedPrice = null;
    negotiation.status = 'Countered';

    return true;
  }

  // ------------------------------------------------------------
  // ACCEPT
  // ------------------------------------------------------------

  static bool acceptNegotiation(String negotiationId) {
    final negotiation = findById(negotiationId);

    if (negotiation == null) {
      return false;
    }

    if (negotiation.status == 'Rejected') {
      return false;
    }

    if (negotiation.status == 'Accepted') {
      return false;
    }

    final agreedPrice =
        negotiation.farmerCounterOffer ??
        negotiation.buyerOffer;

    if (agreedPrice <= 0 ||
        agreedPrice > negotiation.originalPrice) {
      return false;
    }

    negotiation.agreedPrice = agreedPrice;
    negotiation.status = 'Accepted';

    // Apply the negotiated price to the cart.
    CartStore.applyNegotiatedPrice(
      negotiation.productId,
      agreedPrice,
    );

    return true;
  }

  // ------------------------------------------------------------
  // REJECT
  // ------------------------------------------------------------

  static bool rejectNegotiation(String negotiationId) {
    final negotiation = findById(negotiationId);

    if (negotiation == null) {
      return false;
    }

    negotiation.status = 'Rejected';
    negotiation.agreedPrice = null;
    negotiation.farmerCounterOffer = null;

    CartStore.clearNegotiatedPriceByProduct(
      negotiation.productId,
    );

    return true;
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  static bool deleteNegotiation(String negotiationId) {
    final index = negotiations.indexWhere(
      (negotiation) => negotiation.id == negotiationId,
    );

    if (index == -1) {
      return false;
    }

    negotiations.removeAt(index);
    return true;
  }

  static void clear() {
    negotiations.clear();
  }
}