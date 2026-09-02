import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  // --------------------------------------------------
  // GET CURRENT CART ITEM
  // --------------------------------------------------

  CartItem? _getCartItem() {
    for (final item in CartStore.items) {
      if (item.product.id == widget.product.id) {
        return item;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // GET CURRENT CART QUANTITY
  // --------------------------------------------------

  int _getCartQuantity() {
    final item = _getCartItem();
    return item?.quantity ?? 0;
  }

  // --------------------------------------------------
  // ADD TO CART
  // --------------------------------------------------

  void _addProductToCart() {
    final product = widget.product;

    final int currentQuantity = _getCartQuantity();

    // Product must have stock.
    if (product.quantity <= 0) {
      _showCartMessage(
        'This product is currently out of stock.',
      );
      return;
    }

    // Prevent exceeding available stock.
    if (currentQuantity >= product.quantity) {
      _showCartMessage(
        'Maximum available quantity reached '
        '(${product.quantity}).',
      );
      return;
    }

    // Add one unit.
    final bool success = CartStore.addToCart(product);

    if (!success) {
      _showCartMessage(
        'Unable to add this product to your cart.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    final int updatedQuantity = _getCartQuantity();

    if (updatedQuantity >= product.quantity) {
      _showCartMessage(
        '${product.name} × $updatedQuantity added. '
        'Maximum available quantity reached.',
      );
    } else {
      _showCartMessage(
        '${product.name} × $updatedQuantity added to cart.',
      );
    }
  }

  // --------------------------------------------------
  // CART MESSAGE
  // --------------------------------------------------

  void _showCartMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar(
      reason: SnackBarClosedReason.hide,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(
          milliseconds: 1600,
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAKE AN OFFER
  // --------------------------------------------------

  Future<void> _showOfferDialog() async {
    final product = widget.product;

    // --------------------------------------------------
    // CHECK CURRENT NEGOTIATION
    // --------------------------------------------------

    final existingNegotiation =
        NegotiationStore.findByProduct(product.id);

    if (existingNegotiation != null) {
      if (existingNegotiation.status == 'Pending') {
        _showOfferMessage(
          'You already have a pending negotiation '
          'for this product. Wait for the farmer '
          'to respond.',
        );
        return;
      }

      if (existingNegotiation.status == 'Countered') {
        _showOfferMessage(
          'The farmer has made a counter offer. '
          'Please respond to it before making '
          'another offer.',
        );
        return;
      }
    }

    // --------------------------------------------------
    // CURRENT CART QUANTITY
    // --------------------------------------------------

    final int currentCartQuantity = _getCartQuantity();

    // If the product is already in the cart,
    // negotiate for that exact quantity.
    //
    // If it is not in the cart, the offer will
    // be for one unit and one unit will be added
    // automatically after submission.
    final int negotiationQuantity =
        currentCartQuantity > 0
            ? currentCartQuantity
            : 1;

    // Make sure the negotiation quantity is still
    // available in stock.
    if (negotiationQuantity > product.quantity) {
      _showOfferMessage(
        'The quantity in your cart is greater than '
        'the product\'s current available stock.',
      );
      return;
    }

    // --------------------------------------------------
    // OFFER INPUT
    // --------------------------------------------------

    String offerText = '';

    final double? submittedOffer =
        await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Make an Offer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ----------------------------------------
                // PRODUCT
                // ----------------------------------------

                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------
                // LISTED PRICE
                // ----------------------------------------

                Text(
                  'Listed price: '
                  '₵${product.price.toStringAsFixed(2)} '
                  'per unit',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------
                // QUANTITY
                // ----------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Negotiation quantity: '
                          '$negotiationQuantity unit'
                          '${negotiationQuantity == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (currentCartQuantity == 0)
                  const Text(
                    'You are not currently buying this '
                    'product from the cart, so this offer '
                    'will be for 1 unit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                else
                  const Text(
                    'This offer will apply to the '
                    'quantity currently in your cart.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                const SizedBox(height: 18),

                // ----------------------------------------
                // INFORMATION
                // ----------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter the price you would '
                          'like to offer per unit.',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------
                // OFFER FIELD
                // ----------------------------------------

                TextField(
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    offerText = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Your Offer Per Unit',
                    hintText: 'Enter amount',
                    prefixText: '₵ ',
                    prefixIcon: const Icon(
                      Icons.local_offer_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // ------------------------------------------
            // CANCEL
            // ------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            // ------------------------------------------
            // SUBMIT
            // ------------------------------------------

            ElevatedButton(
              onPressed: () {
                final double? proposedPrice =
                    double.tryParse(
                  offerText.trim(),
                );

                // ----------------------------------------
                // VALIDATE NUMBER
                // ----------------------------------------

                if (proposedPrice == null ||
                    proposedPrice <= 0) {
                  _showOfferMessage(
                    'Please enter a valid offer.',
                  );
                  return;
                }

                // ----------------------------------------
                // VALIDATE LISTED PRICE
                // ----------------------------------------

                if (proposedPrice > product.price) {
                  _showOfferMessage(
                    'Your offer cannot be higher '
                    'than the listed price.',
                  );
                  return;
                }

                // ----------------------------------------
                // VALIDATE STOCK
                // ----------------------------------------

                if (product.quantity <= 0) {
                  _showOfferMessage(
                    'This product is currently '
                    'out of stock.',
                  );
                  return;
                }

                if (negotiationQuantity >
                    product.quantity) {
                  _showOfferMessage(
                    'The requested quantity is no '
                    'longer available in stock.',
                  );
                  return;
                }

                // ----------------------------------------
                // VALIDATE NEGOTIATION RULES
                // ----------------------------------------

                final bool isValid =
                    ProductStore.isNegotiatedPriceValid(
                  product.id,
                  proposedPrice,
                );

                if (!isValid) {
                  _showOfferMessage(
                    'This offer is below the '
                    'acceptable negotiation price.',
                  );
                  return;
                }

                // ----------------------------------------
                // RETURN VALID OFFER
                // ----------------------------------------

                Navigator.pop(
                  dialogContext,
                  proposedPrice,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit Offer',
              ),
            ),
          ],
        );
      },
    );

    // --------------------------------------------------
    // USER CANCELLED
    // --------------------------------------------------

    if (submittedOffer == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------
    // RECHECK CART QUANTITY
    // --------------------------------------------------
    //
    // The dialog can stay open while another operation
    // changes the cart, so we check again before saving.
    // --------------------------------------------------

    final CartItem? currentCartItem =
        _getCartItem();

    final int finalCartQuantity =
        currentCartItem?.quantity ?? 0;

    final int finalNegotiationQuantity =
        finalCartQuantity > 0
            ? finalCartQuantity
            : 1;

    if (finalNegotiationQuantity >
        product.quantity) {
      _showOfferMessage(
        'The requested quantity is no longer '
        'available in stock.',
      );
      return;
    }

    // --------------------------------------------------
    // CREATE PENDING NEGOTIATION
    // --------------------------------------------------

    final negotiation = Negotiation(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      productId: product.id,
      productName: product.name,

      // Temporary buyer identity.
      // Firebase authentication will replace this later.
      buyerName: 'Buyer',

      farmerName: product.farmerName,

      // IMPORTANT:
      // Use the actual cart quantity.
      quantity: finalNegotiationQuantity,

      originalPrice: product.price,
      buyerOffer: submittedOffer,
      farmerCounterOffer: null,
      agreedPrice: null,
      status: 'Pending',
    );

    // --------------------------------------------------
    // SAVE NEGOTIATION
    // --------------------------------------------------

    final bool saved =
        NegotiationStore.addNegotiation(
      negotiation,
    );

    if (!saved) {
      _showOfferMessage(
        'Unable to submit your offer. '
        'Please try again.',
      );
      return;
    }

    // --------------------------------------------------
    // ADD PRODUCT TO CART WHEN NECESSARY
    // --------------------------------------------------
    //
    // If the buyer was not already buying the product,
    // add exactly one unit because the offer is for
    // one unit in that situation.
    // --------------------------------------------------

    bool addedToCart = false;

    if (currentCartItem == null) {
      addedToCart =
          CartStore.addToCart(product);

      if (!addedToCart) {
        // The negotiation has already been saved.
        // Inform the user rather than pretending the
        // cart operation succeeded.
        _showOfferMessage(
          'Offer submitted, but the product '
          'could not be added to your cart.',
        );
        return;
      }
    }

    // --------------------------------------------------
    // REFRESH PRODUCT DETAILS
    // --------------------------------------------------

    if (mounted) {
      setState(() {});
    }

    // --------------------------------------------------
    // SUCCESS MESSAGE
    // --------------------------------------------------

    final String quantityText =
        '${finalNegotiationQuantity} unit'
        '${finalNegotiationQuantity == 1 ? '' : 's'}';

    _showOfferMessage(
      'Offer of ₵${submittedOffer.toStringAsFixed(2)} '
      'per unit submitted for $quantityText. '
      '${addedToCart ? 'Product added to your cart. ' : ''}'
      'Checkout is locked until the negotiation is resolved.',
    );
  }

  // --------------------------------------------------
  // OFFER MESSAGE
  // --------------------------------------------------

  void _showOfferMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration:
            const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // --------------------------------------------------
    // CURRENT CART QUANTITY
    // --------------------------------------------------

    final int cartQuantity = _getCartQuantity();

    // --------------------------------------------------
    // STOCK STATUS
    // --------------------------------------------------

    final bool outOfStock =
        product.quantity <= 0;

    final bool stockLimitReached =
        cartQuantity >= product.quantity;

    // --------------------------------------------------
    // NEGOTIATION STATUS
    // --------------------------------------------------

    final bool negotiationAvailable =
        ProductStore.canNegotiate(product.id);

    final Negotiation? currentNegotiation =
        NegotiationStore.findByProduct(product.id);

    final bool negotiationPending =
        currentNegotiation?.status == 'Pending';

    final bool negotiationCountered =
        currentNegotiation?.status == 'Countered';

    final bool negotiationLocked =
        negotiationPending ||
        negotiationCountered;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.agriculture,
                size: 100,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // PRODUCT NAME
            // ==================================================

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // PRICE
            // ==================================================

            Text(
              '₵${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // STOCK STATUS
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: outOfStock
                    ? Colors.red.withValues(
                        alpha: 0.1,
                      )
                    : Colors.green.withValues(
                        alpha: 0.1,
                      ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    outOfStock
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    size: 17,
                    color: outOfStock
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    outOfStock
                        ? 'Out of stock'
                        : '${product.quantity} '
                            'units available',
                    style: TextStyle(
                      color: outOfStock
                          ? Colors.red
                          : Colors.green,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // NEGOTIABLE LABEL
            // ==================================================

            if (negotiationAvailable) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 17,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Price negotiable',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // NEGOTIATION STATUS
            // ==================================================

            if (negotiationLocked) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange
                        .withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        negotiationPending
                            ? 'Your offer is pending. '
                                'Checkout is locked until '
                                'the farmer responds.'
                            : 'The farmer has made a '
                                'counter offer. Respond '
                                'to it before checkout.',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              product.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // FARMER
            // ==================================================

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              title: const Text(
                'Farmer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  Text(product.farmerName),
            ),

            // ==================================================
            // AVAILABLE QUANTITY
            // ==================================================

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Available Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  Text('${product.quantity} units'),
            ),

            // ==================================================
            // CURRENT CART QUANTITY
            // ==================================================

            if (cartQuantity > 0) ...[
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .shopping_cart_outlined,
                      color:
                          AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'In your cart: '
                        '$cartQuantity / '
                        '${product.quantity}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ==================================================
            // MAKE AN OFFER
            // ==================================================

            if (negotiationAvailable) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                      outOfStock ||
                              negotiationLocked
                          ? null
                          : _showOfferDialog,
                  icon: const Icon(
                    Icons
                        .local_offer_outlined,
                  ),
                  label: Text(
                    negotiationPending
                        ? 'Offer Pending'
                        : negotiationCountered
                            ? 'Counter Offer Received'
                            : 'Make an Offer',
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                    side: BorderSide(
                      color: outOfStock ||
                              negotiationLocked
                          ? Colors.grey
                          : AppColors.primary,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ==================================================
            // ADD TO CART
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    outOfStock ||
                            stockLimitReached
                        ? null
                        : _addProductToCart,
                icon: Icon(
                  outOfStock
                      ? Icons
                          .remove_shopping_cart
                      : stockLimitReached
                          ? Icons.check_circle
                          : Icons
                              .shopping_cart,
                ),
                label: Text(
                  outOfStock
                      ? 'Out of Stock'
                      : stockLimitReached
                          ? 'Maximum Quantity Reached'
                          : 'Add to Cart',
                  style:
                      const TextStyle(
                    fontSize: 18,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      AppColors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade400,
                  disabledForegroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}