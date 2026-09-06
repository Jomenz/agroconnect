import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';

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
  // ==================================================
  // CART HELPERS
  // ==================================================

  CartItem? _getCartItem() {
    for (final item in CartStore.itemsForCurrentUser) {
      if (item.product.id == widget.product.id) {
        return item;
      }
    }

    return null;
  }

  int _getCartQuantity() {
    return _getCartItem()?.quantity ?? 0;
  }

  // ==================================================
  // NEGOTIATION HELPERS
  // ==================================================

  Negotiation? _getNegotiation() {
    return NegotiationStore.findByProduct(
      widget.product.id,
    );
  }

  bool _isNegotiationLocked() {
    final negotiation = _getNegotiation();

    if (negotiation == null) {
      return false;
    }

    return negotiation.status == 'Pending' ||
        negotiation.status == 'Countered';
  }

  // ==================================================
  // ADD TO CART
  // ==================================================

  void _addProductToCart() {
    final product = widget.product;
    final currentQuantity = _getCartQuantity();

    if (product.quantity <= 0) {
      _showMessage(
        'This product is currently out of stock.',
      );
      return;
    }

    if (currentQuantity >= product.quantity) {
      _showMessage(
        'Maximum available quantity reached '
        '(${product.quantity}).',
      );
      return;
    }

    final success = CartStore.addToCart(product);

    if (!success) {
      _showMessage(
        'Unable to add this product to your cart.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    final updatedQuantity = _getCartQuantity();

    if (updatedQuantity >= product.quantity) {
      _showMessage(
        '${product.name} × $updatedQuantity added. '
        'Maximum available quantity reached.',
      );
    } else {
      _showMessage(
        '${product.name} × $updatedQuantity added to cart.',
      );
    }
  }

  // ==================================================
  // MAKE AN OFFER
  // ==================================================

  Future<void> _showOfferDialog() async {
    final product = widget.product;

    // --------------------------------------------------
    // EXISTING NEGOTIATION
    // --------------------------------------------------

    final existingNegotiation =
        _getNegotiation();

    if (existingNegotiation != null) {
      if (existingNegotiation.status == 'Pending') {
        _showMessage(
          'You already have a pending negotiation '
          'for this product.',
        );
        return;
      }

      if (existingNegotiation.status == 'Countered') {
        _showMessage(
          'The farmer has made a counter-offer. '
          'Please respond to it first.',
        );
        return;
      }
    }

    // --------------------------------------------------
    // CURRENT CART QUANTITY
    // --------------------------------------------------

    final currentCartQuantity =
        _getCartQuantity();

    final negotiationQuantity =
        currentCartQuantity > 0
            ? currentCartQuantity
            : 1;

    if (negotiationQuantity >
        product.quantity) {
      _showMessage(
        'The requested quantity is no longer '
        'available in stock.',
      );
      return;
    }

    String offerText = '';

    // --------------------------------------------------
    // OFFER DIALOG
    // --------------------------------------------------

    final submittedOffer =
        await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
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
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'GH₵${product.price.toStringAsFixed(2)} per unit',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------
                // QUANTITY
                // ----------------------------------------

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .inventory_2_outlined,
                        color:
                            AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Quantity: '
                          '$negotiationQuantity '
                          '${negotiationQuantity == 1 ? 'unit' : 'units'}',
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

                const SizedBox(height: 12),

                Text(
                  currentCartQuantity > 0
                      ? 'Your offer will apply to the '
                          'quantity currently in your cart.'
                      : 'Your offer will be for 1 unit '
                          'and that unit will be added '
                          'to your cart.',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------
                // INFO
                // ----------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Enter the price you would '
                        'like to offer per unit.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ----------------------------------------
                // OFFER FIELD
                // ----------------------------------------

                TextField(
                  autofocus: true,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  onChanged:
                      (value) {
                    offerText = value;
                  },
                  decoration:
                      InputDecoration(
                    labelText:
                        'Your Offer Per Unit',
                    hintText:
                        'Enter amount',
                    prefixText:
                        'GH₵ ',
                    prefixIcon:
                        const Icon(
                      Icons
                          .local_offer_outlined,
                    ),
                    filled: true,
                    fillColor:
                        Colors.grey.shade50,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey
                                .shade300,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            14,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final proposedPrice =
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

                if (proposedPrice >
                    product.price) {
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
                    'The requested quantity is '
                    'no longer available.',
                  );
                  return;
                }

                // ----------------------------------------
                // VALIDATE NEGOTIATION RULE
                // ----------------------------------------

                final valid =
                    ProductStore
                        .isNegotiatedPriceValid(
                  product.id,
                  proposedPrice,
                );

                if (!valid) {
                  _showOfferMessage(
                    'This offer is below the '
                    'acceptable negotiation price.',
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  proposedPrice,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    AppColors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              child:
                  const Text(
                'Submit Offer',
              ),
            ),
          ],
        );
      },
    );

    // --------------------------------------------------
    // CANCELLED
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

    final currentCartItem =
        _getCartItem();

    final finalCartQuantity =
        currentCartItem?.quantity ?? 0;

    final finalNegotiationQuantity =
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
    // CREATE NEGOTIATION
    // --------------------------------------------------

    final currentUser = AuthService.instance.currentUser;
    final negotiation = Negotiation(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      productId: product.id,
      productName: product.name,
      buyerId: currentUser?.uid ?? '',
      buyerName: currentUser?.name.isNotEmpty == true
          ? currentUser!.name
          : 'Buyer',
      farmerId: product.farmerId,
      farmerName: product.farmerName,
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

    final saved =
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
    // ADD TO CART IF NECESSARY
    // --------------------------------------------------

    bool addedToCart = false;

    if (currentCartItem == null) {
      addedToCart =
          CartStore.addToCart(product);

      if (!addedToCart) {
        _showOfferMessage(
          'Offer submitted, but the product '
          'could not be added to your cart.',
        );
        return;
      }
    }

    // --------------------------------------------------
    // REFRESH
    // --------------------------------------------------

    if (mounted) {
      setState(() {});
    }

    // --------------------------------------------------
    // SUCCESS MESSAGE
    // --------------------------------------------------

    final quantityText =
        '$finalNegotiationQuantity '
        '${finalNegotiationQuantity == 1 ? 'unit' : 'units'}';

    _showOfferMessage(
      'Offer of GH₵${submittedOffer.toStringAsFixed(2)} '
      'per unit submitted for $quantityText. '
      '${addedToCart ? 'Product added to your cart. ' : ''}'
      'Checkout is locked until the negotiation is resolved.',
    );
  }

  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          duration:
              const Duration(
            milliseconds: 1800,
          ),
        ),
      );
  }

  void _showOfferMessage(
    String message,
  ) {
    _showMessage(message);
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final product =
        widget.product;

    final cartQuantity =
        _getCartQuantity();

    final outOfStock =
        product.quantity <= 0;

    final stockLimitReached =
        cartQuantity >=
            product.quantity;

    final negotiationAvailable =
        ProductStore.canNegotiate(
      product.id,
    );

    final negotiation =
        _getNegotiation();

    final negotiationLocked =
        _isNegotiationLocked();

    final negotiatedPrice =
        negotiation?.agreedPrice;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade50,

      // ==================================================
      // APP BAR
      // ==================================================

      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            AppColors.black,
        elevation: 0,
      ),

      body:
          SingleChildScrollView(
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            Container(
              width: double.infinity,
              height: 280,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  if (product.imageUrl != null)
                    Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.agriculture,
                            size: 110,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.agriculture,
                        size: 110,
                        color: AppColors.primary,
                      ),
                    ),

                  // ------------------------------------------
                  // NEGOTIABLE BADGE
                  // ------------------------------------------

                  if (negotiationAvailable)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Price Negotiable',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  // ------------------------------------------
                  // STOCK BADGE
                  // ------------------------------------------

                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: outOfStock
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        outOfStock
                            ? 'Out of stock'
                            : '${product.quantity} available',
                        style: TextStyle(
                          color: outOfStock
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                30,
              ),
              color:
                  Colors.white,
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  // ==================================================
                  // PRODUCT NAME
                  // ==================================================

                  Text(
                    product.name,
                    style:
                        const TextStyle(
                      fontSize:
                          30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  // ==================================================
                  // PRICE
                  // ==================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                    children: [
                      Text(
                        'GH₵${product.price.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          fontSize:
                              25,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.primary,
                        ),
                      ),
                      const SizedBox(
                        width:
                            6,
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom:
                              3,
                        ),
                        child:
                            Text(
                          'per unit',
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // ACCEPTED PRICE
                  // ==================================================

                  if (negotiatedPrice !=
                      null) ...[
                    const SizedBox(
                      height:
                          8,
                    ),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            11,
                        vertical:
                            8,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary
                                .withValues(
                          alpha:
                              0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      child:
                          Text(
                        'Agreed price: '
                        'GH₵${negotiatedPrice.toStringAsFixed(2)} per unit',
                        style:
                            const TextStyle(
                          color:
                              AppColors.primary,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height:
                        24,
                  ),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  const _SectionLabel(
                    title:
                        'Description',
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    product.description,
                    style:
                        const TextStyle(
                      fontSize:
                          15,
                      color:
                          Colors.grey,
                      height:
                          1.55,
                    ),
                  ),

                  const SizedBox(
                    height:
                        24,
                  ),

                  // ==================================================
                  // PRODUCT INFORMATION
                  // ==================================================

                  const _SectionLabel(
                    title:
                        'Product Information',
                  ),

                  const SizedBox(
                    height:
                        12,
                  ),

                  _InfoCard(
                    icon:
                        Icons.person_outline,
                    title:
                        'Farmer',
                    value:
                        product.farmerName,
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  _InfoCard(
                    icon:
                        Icons.inventory_2_outlined,
                    title:
                        'Available Quantity',
                    value:
                        '${product.quantity} units',
                  ),

                  if (cartQuantity >
                      0) ...[
                    const SizedBox(
                      height:
                          10,
                    ),

                    _InfoCard(
                      icon:
                          Icons
                              .shopping_cart_outlined,
                      title:
                          'In Your Cart',
                      value:
                          '$cartQuantity '
                          '${cartQuantity == 1 ? 'unit' : 'units'}',
                    ),
                  ],

                  // ==================================================
                  // NEGOTIATION STATUS
                  // ==================================================

                  if (negotiationLocked) ...[
                    const SizedBox(
                      height:
                          20,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.orange
                                .withValues(
                          alpha:
                              0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        border:
                            Border.all(
                          color:
                              Colors.orange
                                  .withValues(
                            alpha:
                                0.22,
                          ),
                        ),
                      ),
                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Icon(
                            negotiation?.status ==
                                    'Countered'
                                ? Icons
                                    .reply_outlined
                                : Icons
                                    .hourglass_top,
                            color:
                                Colors.orange
                                    .shade700,
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  negotiation?.status ??
                                      'Pending',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.orange
                                            .shade800,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height:
                                      3,
                                ),
                                Text(
                                  negotiation?.status ==
                                          'Countered'
                                      ? 'The farmer has made a counter-offer.'
                                      : 'Your offer is waiting for the farmer\'s response.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.orange
                                            .shade900,
                                    fontSize:
                                        13,
                                    height:
                                        1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height:
                        28,
                  ),

                  // ==================================================
                  // MAKE AN OFFER
                  // ==================================================

                  if (negotiationAvailable)
                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          54,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            outOfStock ||
                                    negotiationLocked
                                ? null
                                : _showOfferDialog,
                        icon:
                            const Icon(
                          Icons
                              .local_offer_outlined,
                        ),
                        label:
                            Text(
                          negotiationLocked
                              ? negotiation?.status ==
                                      'Countered'
                                  ? 'Counter Offer Received'
                                  : 'Offer Pending'
                              : 'Make an Offer',
                          style:
                              const TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.primary,
                          disabledForegroundColor:
                              Colors.grey,
                          side:
                              BorderSide(
                            color:
                                outOfStock ||
                                        negotiationLocked
                                    ? Colors.grey
                                    : AppColors.primary,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (negotiationAvailable)
                    const SizedBox(
                      height:
                          12,
                    ),

                  // ==================================================
                  // ADD TO CART
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height:
                        56,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          outOfStock ||
                                  stockLimitReached
                              ? null
                              : _addProductToCart,
                      icon:
                          Icon(
                        outOfStock
                            ? Icons
                                .remove_shopping_cart_outlined
                            : stockLimitReached
                                ? Icons
                                    .check_circle_outline
                                : Icons
                                    .shopping_cart_outlined,
                      ),
                      label:
                          Text(
                        outOfStock
                            ? 'Out of Stock'
                            : stockLimitReached
                                ? 'Maximum Quantity Reached'
                                : 'Add to Cart',
                        style:
                            const TextStyle(
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            AppColors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        disabledForegroundColor:
                            Colors.grey.shade600,
                        elevation:
                            0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SECTION LABEL
// ======================================================

class _SectionLabel
    extends StatelessWidget {
  final String title;

  const _SectionLabel({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        fontSize:
            18,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }
}

// ======================================================
// INFORMATION CARD
// ======================================================

class _InfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            14,
        vertical:
            12,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                42,
            height:
                42,
            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
                      .withValues(
                alpha:
                    0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  AppColors.primary,
              size:
                  21,
            ),
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize:
                        12,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}