import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';

class FarmerNegotiationsScreen extends StatefulWidget {
  const FarmerNegotiationsScreen({
    super.key,
  });

  @override
  State<FarmerNegotiationsScreen> createState() =>
      _FarmerNegotiationsScreenState();
}

class _FarmerNegotiationsScreenState
    extends State<FarmerNegotiationsScreen> {
  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          duration: const Duration(seconds: 2),
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
        return Icons.swap_horiz_rounded;

      case 'Pending':
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  // ==================================================
  // STATUS MESSAGE
  // ==================================================

  String _statusMessage(String status) {
    switch (status) {
      case 'Accepted':
        return 'This negotiation has been accepted.';

      case 'Rejected':
        return 'This negotiation was rejected.';

      case 'Countered':
        return 'A counter offer has been sent. Waiting for the buyer.';

      case 'Pending':
      default:
        return 'Review the buyer offer and choose an action.';
    }
  }

  // ==================================================
  // COUNTER OFFER DIALOG
  // ==================================================

  Future<void> _showCounterOfferDialog(
    Negotiation negotiation,
  ) async {
    String counterOfferText = '';

    final double? counterOffer = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            10,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: const Text(
            'Make Counter Offer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.06,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buyer Offer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₵${negotiation.buyerOffer.toStringAsFixed(2)} / unit',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.sell_outlined,
                    size: 17,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Listed price: '
                    '₵${negotiation.originalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              TextField(
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  counterOfferText = value;
                },
                decoration: InputDecoration(
                  labelText: 'Your Counter Offer',
                  hintText: 'Enter amount per unit',
                  prefixText: '₵ ',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The buyer will see your counter offer, '
                        'but not your minimum acceptable price.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(
                  counterOfferText.trim(),
                );

                if (parsed == null || parsed <= 0) {
                  _showMessage(
                    'Please enter a valid counter offer.',
                  );
                  return;
                }

                if (parsed > negotiation.originalPrice) {
                  _showMessage(
                    'Counter offer cannot exceed the listed price.',
                  );
                  return;
                }

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

                if (!product.allowNegotiation ||
                    product.minimumPrice == null) {
                  _showMessage(
                    'This product is no longer available for negotiation.',
                  );
                  return;
                }

                if (parsed < product.minimumPrice!) {
                  _showMessage(
                    'Counter offer cannot be below your minimum acceptable price.',
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  parsed,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Counter Offer',
              ),
            ),
          ],
        );
      },
    );

    if (counterOffer == null || !mounted) {
      return;
    }

    final success =
        NegotiationStore.setFarmerCounterOffer(
      negotiation.id,
      counterOffer,
    );

    if (!success) {
      _showMessage(
        'Unable to send counter offer.',
      );
      return;
    }

    setState(() {});

    _showMessage(
      'Counter offer of ₵${counterOffer.toStringAsFixed(2)} sent to the buyer.',
    );
  }

  // ==================================================
  // ACCEPT NEGOTIATION
  // ==================================================

  void _acceptNegotiation(
    Negotiation negotiation,
  ) {
    final product = ProductStore.getProduct(
      negotiation.productId,
    );

    if (product == null) {
      _showMessage(
        'Product could not be found.',
      );
      return;
    }

    if (product.quantity <= 0) {
      _showMessage(
        'This product is currently out of stock.',
      );
      return;
    }

    if (negotiation.quantity > product.quantity) {
      _showMessage(
        'Not enough stock is available for this negotiation.',
      );
      return;
    }

    final success =
        NegotiationStore.acceptNegotiation(
      negotiation.id,
    );

    if (!success) {
      _showMessage(
        'Unable to accept this negotiation.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    final agreedPrice =
        negotiation.agreedPrice;

    if (agreedPrice == null) {
      _showMessage(
        'Negotiation accepted, but no agreed price was found.',
      );
      return;
    }

    _showMessage(
      'Negotiation accepted at '
      '₵${agreedPrice.toStringAsFixed(2)} per unit.',
    );
  }

  // ==================================================
  // REJECT NEGOTIATION
  // ==================================================

  void _rejectNegotiation(
    Negotiation negotiation,
  ) {
    final success =
        NegotiationStore.rejectNegotiation(
      negotiation.id,
    );

    if (!success) {
      _showMessage(
        'Unable to reject this negotiation.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Negotiation rejected.',
    );
  }

  // ==================================================
  // ACTION BUTTON
  // ==================================================

  Widget _actionButtons(
    Negotiation negotiation,
  ) {
    if (negotiation.status != 'Pending') {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _rejectNegotiation(
                negotiation,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              minimumSize: const Size(
                double.infinity,
                46,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _showCounterOfferDialog(
                negotiation,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
              ),
              minimumSize: const Size(
                double.infinity,
                46,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Counter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _acceptNegotiation(
                negotiation,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(
                double.infinity,
                46,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================================================
  // PRICE ROW
  // ==================================================

  Widget _priceRow({
    required String label,
    required String value,
    bool highlighted = false,
    Color? color,
  }) {
    final valueColor =
        color ??
        (highlighted
            ? AppColors.primary
            : Colors.black87);

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlighted
                ? Colors.black87
                : Colors.grey.shade600,
            fontSize: highlighted ? 13 : 12,
            fontWeight: highlighted
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: highlighted ? 17 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==================================================
  // NEGOTIATION CARD
  // ==================================================

  Widget _buildNegotiationCard(
    Negotiation negotiation,
  ) {
    final statusColor =
        _statusColor(negotiation.status);

    final statusIcon =
        _statusIcon(negotiation.status);

    final statusMessage =
        _statusMessage(negotiation.status);

    final buyerTotal =
        negotiation.buyerOffer *
            negotiation.quantity;

    final counterTotal =
        negotiation.farmerCounterOffer != null
            ? negotiation.farmerCounterOffer! *
                negotiation.quantity
            : null;

    final agreedTotal =
        negotiation.agreedPrice != null
            ? negotiation.agreedPrice! *
                negotiation.quantity
            : null;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ========================================
            // HEADER
            // ========================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Negotiation',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        negotiation.productName,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    negotiation.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ========================================
            // STATUS MESSAGE
            // ========================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.055,
                ),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ========================================
            // BUYER DETAILS
            // ========================================

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buyer',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          negotiation.buyerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(9),
                      border: Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      '${negotiation.quantity} units',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ========================================
            // PRICE BREAKDOWN
            // ========================================

            const Text(
              'Offer Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 11),

            _priceRow(
              label: 'Listed price',
              value:
                  '₵${negotiation.originalPrice.toStringAsFixed(2)} / unit',
            ),

            const SizedBox(height: 9),

            _priceRow(
              label: 'Buyer offer',
              value:
                  '₵${negotiation.buyerOffer.toStringAsFixed(2)} / unit',
              highlighted: true,
            ),

            const SizedBox(height: 5),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Buyer total: ₵${buyerTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),

            // ========================================
            // COUNTER OFFER
            // ========================================

            if (negotiation.farmerCounterOffer !=
                null) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.orange.withValues(
                      alpha: 0.14,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 18,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Counter Offer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₵${negotiation.farmerCounterOffer!.toStringAsFixed(2)} / unit',
                          style:
                              const TextStyle(
                            color: Colors.orange,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (counterTotal != null) ...[
                      const SizedBox(height: 5),
                      Align(
                        alignment:
                            Alignment.centerRight,
                        child: Text(
                          'Total: ₵${counterTotal.toStringAsFixed(2)}',
                          style:
                              TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    if (negotiation.status ==
                        'Countered') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          'Waiting for buyer response.',
                          style:
                              TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 11,
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ========================================
            // AGREED PRICE
            // ========================================

            if (negotiation.agreedPrice !=
                null) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.green.withValues(
                      alpha: 0.14,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .check_circle_outline,
                              size: 18,
                              color: Colors.green,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Agreed Price',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₵${negotiation.agreedPrice!.toStringAsFixed(2)} / unit',
                          style:
                              const TextStyle(
                            color: Colors.green,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (agreedTotal != null) ...[
                      const SizedBox(height: 5),
                      Align(
                        alignment:
                            Alignment.centerRight,
                        child: Text(
                          'Total: ₵${agreedTotal.toStringAsFixed(2)}',
                          style:
                              TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ========================================
            // ACTIONS
            // ========================================

            if (negotiation.status ==
                'Pending') ...[
              const SizedBox(height: 17),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _actionButtons(
                negotiation,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================================================
  // HEADER
  // ==================================================

  Widget _buildHeader(
    List<Negotiation> negotiations,
  ) {
    final pendingCount = negotiations
        .where((n) => n.status == 'Pending')
        .length;

    final counteredCount = negotiations
        .where((n) => n.status == 'Countered')
        .length;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Negotiations',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Manage buyer offers and agree on fair prices.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.09,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.handshake_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _summaryChip(
                icon: Icons.hourglass_empty,
                label: 'Pending',
                value: pendingCount,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryChip(
                icon: Icons.swap_horiz,
                label: 'Countered',
                value: counteredCount,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryChip(
                icon: Icons.receipt_long_outlined,
                label: 'Total',
                value: negotiations.length,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================================================
  // SUMMARY CHIP
  // ==================================================

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(height: 7),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10.5,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Negotiations Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              'When buyers make offers on your '
              'negotiable products, their requests '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final currentFarmerName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : 'Farmer';
    final currentFarmerId = currentUser?.uid ?? '';
    final negotiations = NegotiationStore.negotiations.where((n) {
      return n.farmerId == currentFarmerId ||
          n.farmerName.toLowerCase() == currentFarmerName.toLowerCase() ||
          n.farmerName.toLowerCase() == 'farmer' ||
          n.farmerName.toLowerCase() == 'demo farmer';
    }).toList();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F6),
      body: SafeArea(
        child: negotiations.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),
                  children: [
                    _buildHeader(
                      negotiations,
                    ),

                    const SizedBox(height: 22),

                    ...negotiations.map(
                      _buildNegotiationCard,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}