import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/models/product.dart';

// ======================================================
// BUYER NEGOTIATION SCREEN
// ======================================================
//
// Shows the buyer's negotiations and allows the buyer
// to respond to a farmer counter-offer.
//

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({
    super.key,
  });

  @override
  State<NegotiationScreen> createState() =>
      _NegotiationScreenState();
}

class _NegotiationScreenState
    extends State<NegotiationScreen> {
  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
      ),
    );
  }

  // --------------------------------------------------
  // STATUS COLOR
  // --------------------------------------------------

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;

      case 'Rejected':
        return Colors.red;

      case 'Countered':
        return Colors.orange;

      case 'Pending':
      default:
        return AppColors.primary;
    }
  }

  // --------------------------------------------------
  // ACCEPT COUNTER OFFER
  // --------------------------------------------------

  void _acceptCounterOffer(
    Negotiation negotiation,
  ) {
    if (negotiation.status != 'Countered') {
      _showMessage(
        'This counter-offer is no longer awaiting a response.',
      );
      return;
    }

    final counterOffer =
        negotiation.farmerCounterOffer;

    if (counterOffer == null) {
      _showMessage(
        'No counter-offer was found.',
      );
      return;
    }

    // --------------------------------------------------
    // CHECK PRODUCT
    // --------------------------------------------------

    final product =
        ProductStore.getProduct(
      negotiation.productId,
    );

    if (product == null) {
      _showMessage(
        'Product could not be found.',
      );
      return;
    }

    // --------------------------------------------------
    // CHECK STOCK
    // --------------------------------------------------

    if (product.quantity <= 0) {
      _showMessage(
        'This product is currently out of stock.',
      );
      return;
    }

    if (negotiation.quantity >
        product.quantity) {
      _showMessage(
        'Not enough stock is available '
        'for this negotiation.',
      );
      return;
    }

    // --------------------------------------------------
    // APPLY COUNTER-OFFER TO CART
    // --------------------------------------------------

    final cartUpdated =
        CartStore.applyNegotiatedPrice(
      negotiation.productId,
      counterOffer,
    );

    if (!cartUpdated) {
      _showMessage(
        'Add this product to your cart before '
        'accepting the counter-offer.',
      );
      return;
    }

    // --------------------------------------------------
    // UPDATE NEGOTIATION
    // --------------------------------------------------

    negotiation.agreedPrice =
        counterOffer;

    negotiation.status =
        'Accepted';

    final saved =
        NegotiationStore.updateNegotiation(
      negotiation,
    );

    if (!saved) {
      // Roll back the cart price if the negotiation
      // itself could not be updated.
      CartStore.clearNegotiatedPriceByProduct(
        negotiation.productId,
      );

      _showMessage(
        'Unable to accept the counter-offer.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Counter-offer accepted at '
      '₵${counterOffer.toStringAsFixed(2)} '
      'per unit.',
    );
  }

  // --------------------------------------------------
  // REJECT COUNTER OFFER
  // --------------------------------------------------

  void _rejectCounterOffer(
    Negotiation negotiation,
  ) {
    if (negotiation.status != 'Countered') {
      _showMessage(
        'This counter-offer is no longer awaiting a response.',
      );
      return;
    }

    // --------------------------------------------------
    // CLEAR NEGOTIATED PRICE
    // --------------------------------------------------

    CartStore.clearNegotiatedPriceByProduct(
      negotiation.productId,
    );

    // --------------------------------------------------
    // UPDATE NEGOTIATION
    // --------------------------------------------------

    negotiation.farmerCounterOffer =
        null;

    negotiation.agreedPrice =
        null;

    negotiation.status =
        'Rejected';

    final saved =
        NegotiationStore.updateNegotiation(
      negotiation,
    );

    if (!saved) {
      _showMessage(
        'Unable to reject the counter-offer.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Counter-offer rejected.',
    );
  }

  // --------------------------------------------------
  // NEGOTIATION CARD
  // --------------------------------------------------

  Widget _buildNegotiationCard(
    Negotiation negotiation,
  ) {
    final statusColor =
        _statusColor(
      negotiation.status,
    );

    final bool isCountered =
        negotiation.status ==
            'Countered';

    final bool isAccepted =
        negotiation.status ==
            'Accepted';

    final bool isRejected =
        negotiation.status ==
            'Rejected';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      elevation: 2,

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Text(
                    negotiation.productName,

                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.12,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Text(
                    negotiation.status,

                    style:
                        TextStyle(
                      color:
                          statusColor,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            // --------------------------------------------------
            // FARMER
            // --------------------------------------------------

            ListTile(
              contentPadding:
                  EdgeInsets.zero,

              leading:
                  const Icon(
                Icons.person_outline,
                color:
                    AppColors.primary,
              ),

              title:
                  const Text(
                'Farmer',
              ),

              subtitle:
                  Text(
                negotiation.farmerName,
              ),
            ),

            // --------------------------------------------------
            // QUANTITY
            // --------------------------------------------------

            ListTile(
              contentPadding:
                  EdgeInsets.zero,

              leading:
                  const Icon(
                Icons.inventory_2_outlined,
                color:
                    AppColors.primary,
              ),

              title:
                  const Text(
                'Quantity',
              ),

              subtitle:
                  Text(
                '${negotiation.quantity} units',
              ),
            ),

            const Divider(),

            // --------------------------------------------------
            // LISTED PRICE
            // --------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Listed Price',

                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),

                Text(
                  '₵${negotiation.originalPrice.toStringAsFixed(2)}',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // --------------------------------------------------
            // BUYER OFFER
            // --------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Your Offer',

                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  '₵${negotiation.buyerOffer.toStringAsFixed(2)} / unit',

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Total your offer: '
              '₵${(negotiation.buyerOffer * negotiation.quantity).toStringAsFixed(2)}',

              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),

            // --------------------------------------------------
            // COUNTER-OFFER
            // --------------------------------------------------

            if (negotiation
                    .farmerCounterOffer !=
                null) ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  14,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange.withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  border:
                      Border.all(
                    color:
                        Colors.orange.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Farmer Counter-Offer',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.orange,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '₵${negotiation.farmerCounterOffer!.toStringAsFixed(2)} '
                      'per unit',

                      style:
                          const TextStyle(
                        fontSize:
                            19,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.orange,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Total: ₵${(negotiation.farmerCounterOffer! * negotiation.quantity).toStringAsFixed(2)}',

                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --------------------------------------------------
            // AGREED PRICE
            // --------------------------------------------------

            if (negotiation.agreedPrice !=
                null) ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  14,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    const Text(
                      'Agreed Price',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Text(
                      '₵${negotiation.agreedPrice!.toStringAsFixed(2)} / unit',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Total agreed price: '
                '₵${(negotiation.agreedPrice! * negotiation.quantity).toStringAsFixed(2)}',

                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ],

            // --------------------------------------------------
            // PENDING MESSAGE
            // --------------------------------------------------

            if (negotiation.status ==
                'Pending') ...[
              const SizedBox(
                height: 15,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary.withValues(
                    alpha: 0.06,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    const Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      color:
                          AppColors.primary,
                      size:
                          20,
                    ),

                    SizedBox(
                      width:
                          8,
                    ),

                    Expanded(
                      child:
                          Text(
                        'Waiting for the farmer to respond.',
                        style:
                            TextStyle(
                          color:
                              AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --------------------------------------------------
            // COUNTER RESPONSE
            // --------------------------------------------------

            if (isCountered) ...[
              const SizedBox(
                height: 15,
              ),

              const Text(
                'The farmer has made a counter-offer. '
                'Please choose how to respond.',

                style:
                    TextStyle(
                  color:
                      Colors.grey,
                  fontStyle:
                      FontStyle.italic,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed: () {
                        _rejectCounterOffer(
                          negotiation,
                        );
                      },

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.red,

                        side:
                            const BorderSide(
                          color:
                              Colors.red,
                        ),
                      ),

                      child:
                          const Text(
                        'Reject Counter',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  Expanded(
                    child:
                        ElevatedButton(
                      onPressed: () {
                        _acceptCounterOffer(
                          negotiation,
                        );
                      },

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,

                        foregroundColor:
                            AppColors.white,
                      ),

                      child:
                          const Text(
                        'Accept Counter',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // --------------------------------------------------
            // ACCEPTED MESSAGE
            // --------------------------------------------------

            if (isAccepted) ...[
              const SizedBox(
                height: 15,
              ),

              const Text(
                'Negotiation accepted. You can proceed to checkout.',

                style:
                    TextStyle(
                  color:
                      Colors.green,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],

            // --------------------------------------------------
            // REJECTED MESSAGE
            // --------------------------------------------------

            if (isRejected) ...[
              const SizedBox(
                height: 15,
              ),

              const Text(
                'This negotiation has ended.',

                style:
                    TextStyle(
                  color:
                      Colors.red,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final negotiations =
        NegotiationStore.findByBuyer(
      'Buyer',
    );

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'My Negotiations',
        ),

        backgroundColor:
            AppColors.background,

        foregroundColor:
            AppColors.black,

        elevation: 0,
      ),

      body:
          negotiations.isEmpty
              ? const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(
                      25,
                    ),

                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .handshake_outlined,
                          size:
                              80,
                          color:
                              AppColors.primary,
                        ),

                        SizedBox(
                          height:
                              20,
                        ),

                        Text(
                          'No Negotiations Yet',

                          style:
                              TextStyle(
                            fontSize:
                                24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(
                          height:
                              8,
                        ),

                        Text(
                          'Your offers and negotiation responses '
                          'will appear here.',

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  itemCount:
                      negotiations.length,

                  itemBuilder:
                      (context, index) {
                    return _buildNegotiationCard(
                      negotiations[index],
                    );
                  },
                ),
    );
  }
}

// ======================================================
// CREATE NEGOTIATION SCREEN
// ======================================================
//
// Kept in this file so existing navigation to
// CreateNegotiationScreen continues to work.
//

class CreateNegotiationScreen
    extends StatefulWidget {
  final Product product;

  const CreateNegotiationScreen({
    super.key,
    required this.product,
  });

  @override
  State<CreateNegotiationScreen>
      createState() =>
          _CreateNegotiationScreenState();
}

class _CreateNegotiationScreenState
    extends State<CreateNegotiationScreen> {
  final TextEditingController
      offerController =
      TextEditingController();

  int quantity = 1;

  bool isSubmitting = false;

  @override
  void dispose() {
    offerController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // SUBMIT NEGOTIATION
  // --------------------------------------------------

  void _submitNegotiation() {
    if (isSubmitting) {
      return;
    }

    final product =
        widget.product;

    final double? offer =
        double.tryParse(
      offerController.text.trim(),
    );

    // --------------------------------------------------
    // VALIDATE OFFER
    // --------------------------------------------------

    if (offer == null ||
        offer <= 0) {
      _showMessage(
        'Please enter a valid offer.',
      );
      return;
    }

    // --------------------------------------------------
    // CHECK STOCK
    // --------------------------------------------------

    if (product.quantity <= 0) {
      _showMessage(
        'This product is currently out of stock.',
      );
      return;
    }

    // --------------------------------------------------
    // CHECK QUANTITY
    // --------------------------------------------------

    if (quantity <= 0) {
      _showMessage(
        'Quantity must be at least 1.',
      );
      return;
    }

    if (quantity >
        product.quantity) {
      _showMessage(
        'Only ${product.quantity} units are available.',
      );
      return;
    }

    // --------------------------------------------------
    // CHECK NEGOTIATION
    // --------------------------------------------------

    if (!product.allowNegotiation) {
      _showMessage(
        'This product is not available for negotiation.',
      );
      return;
    }

    // --------------------------------------------------
    // VALIDATE PRICE
    // --------------------------------------------------

    final validPrice =
        ProductStore
            .isNegotiatedPriceValid(
      product.id,
      offer,
    );

    if (!validPrice) {
      _showMessage(
        'Your offer is below the acceptable '
        'negotiation price or otherwise invalid.',
      );
      return;
    }

    // --------------------------------------------------
    // CREATE NEGOTIATION
    // --------------------------------------------------

    final negotiation =
        Negotiation(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),

      productId:
          product.id,

      productName:
          product.name,

      // Temporary buyer identity.
      // Firebase will replace this later.
      buyerName:
          'Buyer',

      farmerName:
          product.farmerName,

      quantity:
          quantity,

      originalPrice:
          product.price,

      buyerOffer:
          offer,

      farmerCounterOffer:
          null,

      agreedPrice:
          null,

      status:
          'Pending',
    );

    setState(() {
      isSubmitting = true;
    });

    // --------------------------------------------------
    // SAVE NEGOTIATION
    // --------------------------------------------------

    final saved =
        NegotiationStore
            .addNegotiation(
      negotiation,
    );

    if (!saved) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      _showMessage(
        'Unable to submit your negotiation. '
        'Please try again.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    _showMessage(
      'Negotiation request sent to the farmer.',
    );

    Navigator.pop(context);
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final product =
        widget.product;

    final double? enteredOffer =
        double.tryParse(
      offerController.text.trim(),
    );

    final totalOffer =
        enteredOffer == null
            ? 0
            : enteredOffer *
                quantity;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Make an Offer',
        ),

        backgroundColor:
            AppColors.primary,

        foregroundColor:
            AppColors.white,

        elevation: 0,
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            // ==================================================
            // PRODUCT
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                18,
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
                  16,
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width:
                        60,

                    height:
                        60,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primary
                              .withValues(
                        alpha:
                            0.12,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons.agriculture,
                      color:
                          AppColors.primary,
                      size:
                          32,
                    ),
                  ),

                  const SizedBox(
                    width:
                        15,
                  ),

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          product.name,

                          style:
                              const TextStyle(
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                              5,
                        ),

                        Text(
                          '₵${product.price.toStringAsFixed(2)} '
                          'per unit',

                          style:
                              const TextStyle(
                            color:
                                AppColors.primary,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                              4,
                        ),

                        Text(
                          '${product.quantity} '
                          'units available',

                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
                  30,
            ),

            const Text(
              'Make Your Offer',

              style:
                  TextStyle(
                fontSize:
                    24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            const Text(
              'Send an offer to the farmer. '
              'The farmer can accept your offer, '
              'reject it, or make a counter-offer.',

              style:
                  TextStyle(
                color:
                    Colors.grey,
                height:
                    1.5,
              ),
            ),

            const SizedBox(
              height:
                  25,
            ),

            // ==================================================
            // QUANTITY
            // ==================================================

            const Text(
              'Quantity',

              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            Container(
              decoration:
                  BoxDecoration(
                border:
                    Border.all(
                  color:
                      Colors.grey.shade300,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  IconButton(
                    onPressed:
                        isSubmitting ||
                                quantity <=
                                    1
                            ? null
                            : () {
                                setState(() {
                                  quantity--;
                                });
                              },

                    icon:
                        const Icon(
                      Icons.remove,
                    ),
                  ),

                  Text(
                    '$quantity',

                    style:
                        const TextStyle(
                      fontSize:
                          20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed:
                        isSubmitting ||
                                quantity >=
                                    product
                                        .quantity
                            ? null
                            : () {
                                setState(() {
                                  quantity++;
                                });
                              },

                    icon:
                        const Icon(
                      Icons.add,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            Text(
              '${product.quantity} '
              'units available',

              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height:
                  25,
            ),

            // ==================================================
            // OFFER
            // ==================================================

            const Text(
              'Your Offer Per Unit',

              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            TextField(
              controller:
                  offerController,

              enabled:
                  !isSubmitting,

              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal:
                    true,
              ),

              onChanged:
                  (_) {
                setState(() {});
              },

              decoration:
                  InputDecoration(
                prefixText:
                    '₵ ',

                hintText:
                    'Enter your proposed price',

                prefixIcon:
                    const Icon(
                  Icons
                      .payments_outlined,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            Text(
              'Listed price: '
              '₵${product.price.toStringAsFixed(2)}',

              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height:
                  25,
            ),

            // ==================================================
            // TOTAL OFFER
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.grey
                        .withValues(
                  alpha:
                      0.08,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    'Total Offer',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    '₵${totalOffer.toStringAsFixed(2)}',

                    style:
                        const TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
                  30,
            ),

            // ==================================================
            // SUBMIT
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height:
                  55,

              child:
                  ElevatedButton.icon(
                onPressed:
                    isSubmitting
                        ? null
                        : _submitNegotiation,

                icon:
                    isSubmitting
                        ? const SizedBox(
                            width:
                                20,
                            height:
                                20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .send_outlined,
                          ),

                label:
                    Text(
                  isSubmitting
                      ? 'Sending...'
                      : 'Send Offer',

                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      AppColors.primary,

                  foregroundColor:
                      AppColors.white,

                  disabledBackgroundColor:
                      Colors.grey.shade400,

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
          ],
        ),
      ),
    );
  }
}