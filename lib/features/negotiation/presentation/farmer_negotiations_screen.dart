import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/negotiation/models/negotiation.dart';
import 'package:agroconnect/features/product/data/product_store.dart';

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
  // --------------------------------------------------
  // SHOW MESSAGE
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
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
  // COUNTER OFFER DIALOG
  // --------------------------------------------------

  Future<void> _showCounterOfferDialog(
    Negotiation negotiation,
  ) async {
    String counterOfferText = '';

    final double? counterOffer = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Make Counter Offer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyer offered '
                '₵${negotiation.buyerOffer.toStringAsFixed(2)} '
                'per unit.',
              ),

              const SizedBox(height: 15),

              Text(
                'Listed price: '
                '₵${negotiation.originalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 15),

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
                  hintText: 'Enter amount',
                  prefixText: '₵ ',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'The buyer will see only your counter-offer, '
                'not your minimum acceptable price.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
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
                    'Counter offer cannot exceed '
                    'the listed price.',
                  );
                  return;
                }

                final product = ProductStore.getProduct(
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
                    'This product is no longer available '
                    'for negotiation.',
                  );
                  return;
                }

                if (parsed < product.minimumPrice!) {
                  _showMessage(
                    'Counter offer cannot be below '
                    'your minimum acceptable price.',
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
              ),
              child: const Text(
                'Send Counter Offer',
              ),
            ),
          ],
        );
      },
    );

    if (counterOffer == null) {
      return;
    }

    if (!mounted) {
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

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Counter offer of '
      '₵${counterOffer.toStringAsFixed(2)} '
      'sent to the buyer.',
    );
  }

  // --------------------------------------------------
  // ACCEPT NEGOTIATION
  // --------------------------------------------------

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
        'Not enough stock is available '
        'for this negotiation.',
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

    final agreedPrice = negotiation.agreedPrice;

    if (agreedPrice == null) {
      _showMessage(
        'Negotiation accepted, but no agreed '
        'price was found.',
      );
      return;
    }

    _showMessage(
      'Negotiation accepted at '
      '₵${agreedPrice.toStringAsFixed(2)} '
      'per unit.',
    );
  }

  // --------------------------------------------------
  // REJECT NEGOTIATION
  // --------------------------------------------------

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

  // --------------------------------------------------
  // ACTION BUTTONS
  // --------------------------------------------------

  List<Widget> _actionButtons(
    Negotiation negotiation,
  ) {
    if (negotiation.status != 'Pending') {
      return [];
    }

    return [
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
          ),
          child: const Text(
            'Reject',
          ),
        ),
      ),

      const SizedBox(width: 10),

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
          ),
          child: const Text(
            'Counter',
          ),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: ElevatedButton(
          onPressed: () {
            _acceptNegotiation(
              negotiation,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: const Text(
            'Accept',
          ),
        ),
      ),
    ];
  }

  // --------------------------------------------------
  // NEGOTIATION CARD
  // --------------------------------------------------

  Widget _buildNegotiationCard(
    Negotiation negotiation,
  ) {
    final statusColor =
        _statusColor(negotiation.status);

    final buttons =
        _actionButtons(negotiation);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ------------------------------------------
            // HEADER
            // ------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    negotiation.productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    negotiation.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ------------------------------------------
            // BUYER
            // ------------------------------------------

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              title: const Text(
                'Buyer',
              ),
              subtitle: Text(
                negotiation.buyerName,
              ),
            ),

            // ------------------------------------------
            // QUANTITY
            // ------------------------------------------

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Quantity',
              ),
              subtitle: Text(
                '${negotiation.quantity} units',
              ),
            ),

            const Divider(),

            // ------------------------------------------
            // LISTED PRICE
            // ------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Listed Price',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₵${negotiation.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ------------------------------------------
            // BUYER OFFER
            // ------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buyer Offer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₵${negotiation.buyerOffer.toStringAsFixed(2)} / unit',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Total buyer offer: '
              '₵${(negotiation.buyerOffer * negotiation.quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            // ------------------------------------------
            // COUNTER OFFER
            // ------------------------------------------

            if (negotiation.farmerCounterOffer !=
                null) ...[
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Counter Offer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₵${negotiation.farmerCounterOffer!.toStringAsFixed(2)} / unit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              if (negotiation.status ==
                  'Countered') ...[
                const SizedBox(height: 8),
                const Text(
                  'Waiting for the buyer to respond.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],

            // ------------------------------------------
            // AGREED PRICE
            // ------------------------------------------

            if (negotiation.agreedPrice !=
                null) ...[
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agreed Price',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₵${negotiation.agreedPrice!.toStringAsFixed(2)} / unit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Total agreed price: '
                '₵${(negotiation.agreedPrice! * negotiation.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],

            // ------------------------------------------
            // ACTIONS
            // ------------------------------------------

            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 18),

              Row(
                children: buttons,
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
  Widget build(BuildContext context) {
    final negotiations = [
      ...NegotiationStore.findByFarmer('Farmer'),
      ...NegotiationStore.findByFarmer('Demo Farmer'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Negotiations',
        ),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.black,
        elevation: 0,
      ),

      body: negotiations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),

                    SizedBox(height: 20),

                    Text(
                      'No Negotiations Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Buyer offers will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: negotiations.length,
              itemBuilder: (context, index) {
                return _buildNegotiationCard(
                  negotiations[index],
                );
              },
            ),
    );
  }
}