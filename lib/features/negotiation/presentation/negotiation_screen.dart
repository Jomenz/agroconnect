import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';

// ======================================================
// BUYER NEGOTIATION SCREEN
// ======================================================
//
// Shows the buyer's negotiations and allows the buyer
// to respond to farmer counter-offers.
//
// Core negotiation behavior is preserved.
// This version mainly refines the UI and presentation.
//

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({
    super.key,
  });

  @override
  State<NegotiationScreen> createState() =>
      _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
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
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(
            milliseconds: 2200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ==================================================
  // STATUS COLOR
  // ==================================================

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

  // ==================================================
  // STATUS ICON
  // ==================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle_outline;

      case 'Rejected':
        return Icons.cancel_outlined;

      case 'Countered':
        return Icons.reply_outlined;

      case 'Pending':
      default:
        return Icons.hourglass_top;
    }
  }

  // ==================================================
  // ACCEPT COUNTER OFFER
  // ==================================================

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
      CartStore.clearNegotiatedPriceByProduct(
        negotiation.productId,
      );

      negotiation.agreedPrice = null;
      negotiation.status = 'Countered';

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
      'GH₵${counterOffer.toStringAsFixed(2)} '
      'per unit.',
    );
  }

  // ==================================================
  // REJECT COUNTER OFFER
  // ==================================================

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

  // ==================================================
  // NEGOTIATION CARD
  // ==================================================

  Widget _buildNegotiationCard(
    Negotiation negotiation,
  ) {
    final statusColor =
        _statusColor(
      negotiation.status,
    );

    final statusIcon =
        _statusIcon(
      negotiation.status,
    );

    final bool isPending =
        negotiation.status == 'Pending';

    final bool isCountered =
        negotiation.status == 'Countered';

    final bool isAccepted =
        negotiation.status == 'Accepted';

    final bool isRejected =
        negotiation.status == 'Rejected';

    final double buyerOfferTotal =
        negotiation.buyerOffer *
            negotiation.quantity;

    final double? counterOffer =
        negotiation.farmerCounterOffer;

    final double? counterOfferTotal =
        counterOffer == null
            ? null
            : counterOffer *
                negotiation.quantity;

    final double? agreedPrice =
        negotiation.agreedPrice;

    final double? agreedTotal =
        agreedPrice == null
            ? null
            : agreedPrice *
                negotiation.quantity;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 1.5,
      shadowColor:
          Colors.black.withValues(
        alpha: 0.07,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        side:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.primary
                            .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .handshake_outlined,
                    color:
                        AppColors.primary,
                    size:
                        25,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        negotiation
                            .productName,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize:
                              19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Negotiation details',
                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade600,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ------------------------------------------
                // STATUS BADGE
                // ------------------------------------------

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        10,
                    vertical:
                        7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor
                            .withValues(
                      alpha:
                          0.1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                      Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size:
                            15,
                        color:
                            statusColor,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        negotiation.status,
                        style:
                            TextStyle(
                          color:
                              statusColor,
                          fontWeight:
                              FontWeight.bold,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // FARMER + QUANTITY
            // ==================================================

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
                    Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  Row(
                children: [
                  Expanded(
                    child:
                        _InfoItem(
                      icon:
                          Icons.person_outline,
                      label:
                          'Farmer',
                      value:
                          negotiation.farmerName,
                    ),
                  ),

                  Container(
                    width:
                        1,
                    height:
                        38,
                    color:
                        Colors.grey.shade300,
                  ),

                  Expanded(
                    child:
                        _InfoItem(
                      icon:
                          Icons.inventory_2_outlined,
                      label:
                          'Quantity',
                      value:
                          '${negotiation.quantity} '
                          '${negotiation.quantity == 1 ? 'unit' : 'units'}',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PRICE BREAKDOWN
            // ==================================================

            const Text(
              'Price Details',
              style:
                  TextStyle(
                fontSize:
                    16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            _PriceRow(
              label:
                  'Listed price',
              amount:
                  negotiation.originalPrice,
              color:
                  Colors.grey.shade700,
            ),

            const SizedBox(
              height: 8,
            ),

            _PriceRow(
              label:
                  'Your offer',
              amount:
                  negotiation.buyerOffer,
              color:
                  AppColors.primary,
              bold:
                  true,
              suffix:
                  ' / unit',
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Your offer total: '
              'GH₵${buyerOfferTotal.toStringAsFixed(2)}',
              style:
                  const TextStyle(
                fontSize:
                    12,
                color:
                    Colors.grey,
              ),
            ),

            // ==================================================
            // COUNTER OFFER
            // ==================================================

            if (counterOffer != null) ...[
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
                    alpha:
                        0.07,
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
                          0.2,
                    ),
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .reply_outlined,
                          size:
                              19,
                          color:
                              Colors.orange
                                  .shade800,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          'Farmer Counter-Offer',
                          style:
                              TextStyle(
                            color:
                                Colors.orange
                                    .shade800,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'GH₵${counterOffer.toStringAsFixed(2)} / unit',
                      style:
                          TextStyle(
                        fontSize:
                            20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.orange
                                .shade800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Total: '
                      'GH₵${counterOfferTotal!.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // AGREED PRICE
            // ==================================================

            if (agreedPrice != null) ...[
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
                    alpha:
                        0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.green
                            .withValues(
                      alpha:
                          0.18,
                    ),
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .check_circle_outline,
                          size:
                              19,
                          color:
                              Colors.green,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        const Text(
                          'Agreed Price',
                          style:
                              TextStyle(
                            color:
                                Colors.green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'GH₵${agreedPrice.toStringAsFixed(2)} / unit',
                      style:
                          const TextStyle(
                        fontSize:
                            20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.green,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Total: '
                      'GH₵${agreedTotal!.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // PENDING MESSAGE
            // ==================================================

            if (isPending) ...[
              const SizedBox(
                height: 16,
              ),

              _StatusMessage(
                icon:
                    Icons.hourglass_top,
                title:
                    'Waiting for the farmer',
                message:
                    'Your offer has been submitted. '
                    'You cannot change the quantity or '
                    'checkout this product until the farmer responds.',
                color:
                    AppColors.primary,
              ),
            ],

            // ==================================================
            // COUNTERED ACTIONS
            // ==================================================

            if (isCountered) ...[
              const SizedBox(
                height: 16,
              ),

              const Text(
                'Respond to Counter-Offer',
                style:
                    TextStyle(
                  fontSize:
                      16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Choose whether to accept the farmer\'s new price or reject it.',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
                  fontSize:
                      13,
                  height:
                      1.4,
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
                      onPressed:
                          () =>
                              _rejectCounterOffer(
                        negotiation,
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.red,
                        side:
                            const BorderSide(
                          color:
                              Colors.red,
                        ),
                        minimumSize:
                            const Size(
                          0,
                          48,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            11,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Reject',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
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
                      onPressed:
                          () =>
                              _acceptCounterOffer(
                        negotiation,
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            AppColors.white,
                        minimumSize:
                            const Size(
                          0,
                          48,
                        ),
                        elevation:
                            0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            11,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Accept',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ==================================================
            // ACCEPTED MESSAGE
            // ==================================================

            if (isAccepted) ...[
              const SizedBox(
                height: 16,
              ),

              const _StatusMessage(
                icon:
                    Icons.check_circle_outline,
                title:
                    'Negotiation accepted',
                message:
                    'The agreed price has been applied to your cart. '
                    'You can proceed to checkout.',
                color:
                    Colors.green,
              ),
            ],

            // ==================================================
            // REJECTED MESSAGE
            // ==================================================

            if (isRejected) ...[
              const SizedBox(
                height: 16,
              ),

              const _StatusMessage(
                icon:
                    Icons.cancel_outlined,
                title:
                    'Negotiation rejected',
                message:
                    'The negotiation has ended. The product can be purchased at its listed price.',
                color:
                    Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================================================
  // BUILD SCREEN
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser = AuthService.instance.currentUser;
    final buyerName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : 'Buyer';
    final buyerId = currentUser?.uid ?? '';
    final negotiations = NegotiationStore.negotiations.where((item) {
      return item.buyerId == buyerId ||
          item.buyerName.toLowerCase() == buyerName.toLowerCase() ||
          item.buyerName.toLowerCase() == 'buyer';
    }).toList();

    final pendingCount =
        negotiations
            .where(
              (item) =>
                  item.status == 'Pending',
            )
            .length;

    final counteredCount =
        negotiations
            .where(
              (item) =>
                  item.status == 'Countered',
            )
            .length;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade50,

      appBar:
          AppBar(
        title:
            const Text(
          'My Negotiations',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            AppColors.black,
        elevation:
            0,
      ),

      body:
          negotiations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // ==================================================
                    // SUMMARY HEADER
                    // ==================================================

                    Container(
                      width:
                          double.infinity,
                      margin:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        8,
                      ),
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          Container(
                            width:
                                46,
                            height:
                                46,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white
                                      .withValues(
                                alpha:
                                    0.14,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .handshake_outlined,
                              color:
                                  Colors.white,
                              size:
                                  24,
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
                                  '${negotiations.length} '
                                  '${negotiations.length == 1 ? 'Negotiation' : 'Negotiations'}',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      3,
                                ),

                                Text(
                                  pendingCount > 0 ||
                                          counteredCount > 0
                                      ? '$pendingCount pending • '
                                          '$counteredCount countered'
                                      : 'Review your completed negotiations',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white
                                            .withValues(
                                      alpha:
                                          0.82,
                                    ),
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

                    // ==================================================
                    // NEGOTIATIONS LIST
                    // ==================================================

                    Expanded(
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          24,
                        ),
                        itemCount:
                            negotiations.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          return _buildNegotiationCard(
                            negotiations[index],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // ==================================================
  // EMPTY STATE
  // ==================================================

  Widget _buildEmptyState() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width:
                  90,
              height:
                  90,
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primary
                        .withValues(
                  alpha:
                      0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .handshake_outlined,
                size:
                    46,
                color:
                    AppColors.primary,
              ),
            ),

            const SizedBox(
              height:
                  20,
            ),

            const Text(
              'No Negotiations Yet',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  9,
            ),

            const Text(
              'When you make an offer on a negotiable '
              'product, your negotiation will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey,
                height:
                    1.5,
                fontSize:
                    14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// INFO ITEM
// ======================================================

class _InfoItem
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        const SizedBox(
          width:
              8,
        ),

        Icon(
          icon,
          size:
              19,
          color:
              AppColors.primary,
        ),

        const SizedBox(
          width:
              8,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                  fontSize:
                      11,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                value,
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// PRICE ROW
// ======================================================

class _PriceRow
    extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  final String suffix;

  const _PriceRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
    this.suffix = '',
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Text(
          label,
          style:
              TextStyle(
            color:
                bold
                    ? Colors.black87
                    : Colors.grey,
            fontWeight:
                bold
                    ? FontWeight.w600
                    : FontWeight.normal,
            fontSize:
                13,
          ),
        ),

        Text(
          'GH₵${amount.toStringAsFixed(2)}$suffix',
          style:
              TextStyle(
            color:
                color,
            fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.w600,
            fontSize:
                bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

// ======================================================
// STATUS MESSAGE
// ======================================================

class _StatusMessage
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        13,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              color.withValues(
            alpha:
                0.15,
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
            icon,
            size:
                20,
            color:
                color,
          ),

          const SizedBox(
            width:
                9,
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
                      TextStyle(
                    color:
                        color,
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        13,
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  message,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize:
                        12,
                    height:
                        1.4,
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

// ======================================================
// CREATE NEGOTIATION SCREEN
// ======================================================
//
// Existing functionality retained.
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

  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(
    String message,
  ) {
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
              const EdgeInsets.all(
            16,
          ),
        ),
      );
  }

  // ==================================================
  // SUBMIT NEGOTIATION
  // ==================================================

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

    final currentUser = AuthService.instance.currentUser;
    final negotiation =
        Negotiation(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),

      productId:
          product.id,

      productName:
          product.name,

      buyerId: currentUser?.uid ?? '',
      buyerName: currentUser?.name.isNotEmpty == true
          ? currentUser!.name
          : 'Buyer',
      farmerId: product.farmerId,
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
        isSubmitting =
            false;
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
      isSubmitting =
          false;
    });

    _showMessage(
      'Negotiation request sent to the farmer.',
    );

    Navigator.pop(
      context,
    );
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
      appBar:
          AppBar(
        title:
            const Text(
          'Make an Offer',
        ),
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            AppColors.white,
        elevation:
            0,
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child:
            Column(
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
              child:
                  Row(
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
                          BorderRadius.circular(
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
                          'GH₵${product.price.toStringAsFixed(2)} '
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
              child:
                  Row(
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
                                    product.quantity
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
              '${product.quantity} units available',
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
                    'GH₵ ',
                hintText:
                    'Enter your proposed price',
                prefixIcon:
                    const Icon(
                  Icons.payments_outlined,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                      BorderSide(
                    color:
                        Colors.grey.shade300,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        AppColors.primary,
                    width:
                        1.4,
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
              'GH₵${product.price.toStringAsFixed(2)}',
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
                    'GH₵${totalOffer.toStringAsFixed(2)}',
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
                    ElevatedButton.styleFrom(
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