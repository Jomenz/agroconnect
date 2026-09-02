import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/checkout/presentation/checkout_screen.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ==================================================
  // ITEMS READY FOR CHECKOUT
  // ==================================================

  List<CartItem> get _checkoutItems {
    return CartStore.items
        .where(
          (item) => NegotiationStore.canCheckoutProduct(
            item.product.id,
          ),
        )
        .toList();
  }

  // ==================================================
  // ITEMS WAITING FOR NEGOTIATION
  // ==================================================

  List<CartItem> get _waitingItems {
    return CartStore.items
        .where(
          (item) => _isQuantityLocked(item),
        )
        .toList();
  }

  // ==================================================
  // CHECKOUT TOTAL
  // ==================================================

  double get _checkoutTotal {
    return _checkoutItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  // ==================================================
  // GET NEGOTIATION
  // ==================================================

  dynamic _getNegotiation(CartItem item) {
    return NegotiationStore.findByProduct(
      item.product.id,
    );
  }

  // ==================================================
  // CHECK WHETHER QUANTITY IS LOCKED
  // ==================================================
  //
  // Quantity is locked ONLY while the negotiation is:
  //
  // Pending
  // Countered
  //
  // Once accepted or rejected, the controls become
  // available again.

  bool _isQuantityLocked(CartItem item) {
    final negotiation = _getNegotiation(item);

    if (negotiation == null) {
      return false;
    }

    return negotiation.status == 'Pending' ||
        negotiation.status == 'Countered';
  }

  // ==================================================
  // NEGOTIATION STATUS
  // ==================================================

  String _getNegotiationStatus(CartItem item) {
    final negotiation = _getNegotiation(item);

    return negotiation?.status ?? '';
  }

  // ==================================================
  // WAITING MESSAGE
  // ==================================================

  String _getWaitingMessage(CartItem item) {
    final status =
        _getNegotiationStatus(item);

    switch (status) {
      case 'Pending':
        return 'Waiting for farmer response';

      case 'Countered':
        return 'Farmer has made a counter-offer';

      default:
        return 'Negotiation in progress';
    }
  }

  // ==================================================
  // PROCEED TO CHECKOUT
  // ==================================================

  void _proceedToCheckout() {
    final readyItems = _checkoutItems;

    if (readyItems.isEmpty) {
      _showMessage(
        'No items are ready for checkout. '
        'Please resolve your pending negotiations first.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CheckoutScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ==================================================
  // REMOVE ITEM
  // ==================================================

  void _removeItem(CartItem item) {
    // Do not allow the buyer to remove a product
    // while its negotiation is still unresolved.
    if (_isQuantityLocked(item)) {
      _showMessage(
        'This product cannot be removed while '
        'the negotiation is unresolved.',
      );
      return;
    }

    CartStore.removeItem(item);

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '${item.product.name} removed from your cart.',
    );
  }

  // ==================================================
  // DECREASE QUANTITY
  // ==================================================

  void _decreaseQuantity(CartItem item) {
    if (_isQuantityLocked(item)) {
      _showMessage(
        'Quantity cannot be changed while the '
        'negotiation is unresolved.',
      );
      return;
    }

    if (item.quantity <= 1) {
      return;
    }

    setState(() {
      item.quantity--;
    });
  }

  // ==================================================
  // INCREASE QUANTITY
  // ==================================================

  void _increaseQuantity(CartItem item) {
    if (_isQuantityLocked(item)) {
      _showMessage(
        'Quantity cannot be changed while the '
        'negotiation is unresolved.',
      );
      return;
    }

    if (item.quantity >=
        item.availableQuantity) {
      _showMessage(
        'Maximum available quantity reached '
        '(${item.availableQuantity}).',
      );
      return;
    }

    setState(() {
      item.quantity++;
    });
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
          content: Text(message),
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

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final items =
        CartStore.items;

    final waitingItems =
        _waitingItems;

    final checkoutItems =
        _checkoutItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            AppColors.white,
      ),

      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .shopping_cart_outlined,
                    size: 80,
                    color:
                        Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add products to your cart '
                    'to continue shopping.',
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
            )
          : Column(
              children: [
                // ==================================================
                // NEGOTIATION WARNING
                // ==================================================

                if (waitingItems.isNotEmpty)
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
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.orange
                              .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.orange
                                .withValues(
                          alpha: 0.22,
                        ),
                      ),
                    ),
                    child:
                        Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Icon(
                          Icons
                              .hourglass_top,
                          color:
                              Colors.orange,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              Text(
                            '${waitingItems.length} '
                            '${waitingItems.length == 1 ? 'item is' : 'items are'} '
                            'currently in negotiation. '
                            'Quantity changes and removal are '
                            'locked until the negotiation is resolved.',
                            style:
                                const TextStyle(
                              color:
                                  Colors.orange,
                              fontSize:
                                  13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ==================================================
                // CART LIST
                // ==================================================

                Expanded(
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        items.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                          items[index];

                      final bool negotiationLocked =
                          _isQuantityLocked(
                        item,
                      );

                      final bool canCheckout =
                          NegotiationStore
                              .canCheckoutProduct(
                        item.product.id,
                      );

                      final double displayedPrice =
                          item.effectivePrice;

                      final String status =
                          _getNegotiationStatus(
                        item,
                      );

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        elevation: 2,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              // ==================================================
                              // PRODUCT INFORMATION
                              // ==================================================

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    width:
                                        65,
                                    height:
                                        65,
                                    decoration:
                                        BoxDecoration(
                                      color: AppColors
                                          .primary
                                          .withValues(
                                        alpha:
                                            0.08,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .agriculture,
                                      color:
                                          AppColors
                                              .primary,
                                      size:
                                          32,
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
                                          item.product
                                              .name,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                17,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height:
                                              5,
                                        ),

                                        // ----------------------------------------
                                        // PRICE
                                        // ----------------------------------------

                                        if (item
                                            .isNegotiated)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                'Listed price: '
                                                'GH₵${item.product.price.toStringAsFixed(2)}',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.grey,
                                                  decoration:
                                                      TextDecoration
                                                          .lineThrough,
                                                  fontSize:
                                                      12,
                                                ),
                                              ),
                                              Text(
                                                'Negotiated price: '
                                                'GH₵${displayedPrice.toStringAsFixed(2)}',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      AppColors
                                                          .primary,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            'GH₵${displayedPrice.toStringAsFixed(2)} each',
                                            style:
                                                const TextStyle(
                                              color:
                                                  AppColors
                                                      .primary,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),

                                        const SizedBox(
                                          height:
                                              4,
                                        ),

                                        Text(
                                          'Farmer: '
                                          '${item.product.farmerName}',
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

                                  // ----------------------------------------
                                  // REMOVE
                                  // ----------------------------------------

                                  IconButton(
                                    icon:
                                        Icon(
                                      Icons
                                          .delete_outline,
                                      color:
                                          negotiationLocked
                                              ? Colors
                                                  .grey
                                              : Colors
                                                  .red,
                                    ),
                                    tooltip:
                                        negotiationLocked
                                            ? 'Locked while negotiation is unresolved'
                                            : 'Remove from cart',
                                    onPressed:
                                        () =>
                                            _removeItem(
                                      item,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              // ==================================================
                              // QUANTITY CONTROLS
                              // ==================================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // ----------------------------------------
                                      // DECREASE
                                      // ----------------------------------------

                                      IconButton(
                                        onPressed:
                                            negotiationLocked ||
                                                    item.quantity <=
                                                        1
                                                ? null
                                                : () =>
                                                    _decreaseQuantity(
                                                      item,
                                                    ),
                                        icon:
                                            Icon(
                                          Icons
                                              .remove_circle_outline,
                                          color:
                                              negotiationLocked
                                                  ? Colors
                                                      .grey
                                                  : null,
                                        ),
                                      ),

                                      // ----------------------------------------
                                      // QUANTITY
                                      // ----------------------------------------

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              14,
                                          vertical:
                                              8,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              negotiationLocked
                                                  ? Colors
                                                      .orange
                                                      .withValues(
                                                      alpha:
                                                          0.10,
                                                    )
                                                  : Colors
                                                      .grey
                                                      .shade100,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            if (negotiationLocked)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(
                                                  right:
                                                      6,
                                                ),
                                                child:
                                                    Icon(
                                                  Icons
                                                      .lock_outline,
                                                  size:
                                                      15,
                                                  color:
                                                      Colors.orange,
                                                ),
                                              ),

                                            Text(
                                              '${item.quantity}',
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ----------------------------------------
                                      // INCREASE
                                      // ----------------------------------------

                                      IconButton(
                                        onPressed:
                                            negotiationLocked ||
                                                    item.quantity >=
                                                        item.availableQuantity
                                                ? null
                                                : () =>
                                                    _increaseQuantity(
                                                      item,
                                                    ),
                                        icon:
                                            Icon(
                                          Icons
                                              .add_circle_outline,
                                          color:
                                              negotiationLocked
                                                  ? Colors
                                                      .grey
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ----------------------------------------
                                  // TOTAL
                                  // ----------------------------------------

                                  Text(
                                    'GH₵${item.totalPrice.toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // ==================================================
                              // NEGOTIATION STATUS
                              // ==================================================

                              if (negotiationLocked)
                                Container(
                                  width:
                                      double.infinity,
                                  margin:
                                      const EdgeInsets.only(
                                    top: 8,
                                  ),
                                  padding:
                                      const EdgeInsets.all(
                                    10,
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
                                      8,
                                    ),
                                  ),
                                  child:
                                      Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Icon(
                                        status ==
                                                'Countered'
                                            ? Icons
                                                .reply
                                            : Icons
                                                .hourglass_top,
                                        size:
                                            18,
                                        color:
                                            Colors.orange,
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
                                              status,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.orange,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize:
                                                    12,
                                              ),
                                            ),
                                            const SizedBox(
                                              height:
                                                  2,
                                            ),
                                            Text(
                                              _getWaitingMessage(
                                                item,
                                              ),
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.orange
                                                        .shade900,
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
                              // NON-CHECKOUT STATUS
                              // ==================================================

                              if (!negotiationLocked &&
                                  !canCheckout)
                                Container(
                                  width:
                                      double.infinity,
                                  margin:
                                      const EdgeInsets.only(
                                    top: 8,
                                  ),
                                  padding:
                                      const EdgeInsets.all(
                                    10,
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
                                      8,
                                    ),
                                  ),
                                  child:
                                      const Text(
                                    'This item is not currently available for checkout.',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // BOTTOM CHECKOUT SECTION
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black
                                .withValues(
                          alpha:
                              0.08,
                        ),
                        blurRadius:
                            10,
                        offset:
                            const Offset(
                          0,
                          -3,
                        ),
                      ),
                    ],
                  ),
                  child:
                      Column(
                    children: [
                      if (waitingItems
                          .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom:
                                10,
                          ),
                          child:
                              Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'Ready for checkout',
                                style:
                                    TextStyle(
                                  fontSize:
                                      13,
                                  color:
                                      Colors.grey,
                                ),
                              ),
                              Text(
                                '${checkoutItems.length} '
                                '${checkoutItems.length == 1 ? 'item' : 'items'}',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      13,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            'Checkout Total',
                            style:
                                TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            'GH₵${_checkoutTotal.toStringAsFixed(2)}',
                            style:
                                const TextStyle(
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  AppColors
                                      .primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height:
                            52,
                        child:
                            ElevatedButton(
                          onPressed:
                              checkoutItems
                                      .isNotEmpty
                                  ? _proceedToCheckout
                                  : null,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                Colors.grey
                                    .shade300,
                            disabledForegroundColor:
                                Colors.grey
                                    .shade600,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child:
                              Text(
                            checkoutItems
                                    .isNotEmpty
                                ? 'Proceed to Checkout'
                                : waitingItems
                                        .isNotEmpty
                                    ? 'Waiting for Negotiation'
                                    : 'No Items Ready',
                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
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