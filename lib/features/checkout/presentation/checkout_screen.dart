import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/cart/data/cart_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/order/data/order_firestore_service.dart';
import 'package:agroconnect/features/order/models/order.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';
import 'package:agroconnect/features/buyer/presentation/buyer_home_screen.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController addressController =
      TextEditingController();

  String fulfillmentMethod = 'Delivery';

  bool isPlacingOrder = false;

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  // ==================================================
  // CART ITEMS
  // ==================================================

  List<CartItem> get cartItems {
    return CartStore.itemsForCurrentUser.toList();
  }

  // ==================================================
  // ITEMS ELIGIBLE FOR CHECKOUT
  // ==================================================
  //
  // No negotiation:
  //     -> allowed
  //
  // Accepted:
  //     -> allowed using negotiated price
  //
  // Rejected:
  //     -> allowed using original price
  //
  // Pending:
  //     -> locked
  //
  // Countered:
  //     -> locked

  List<CartItem> get checkoutItems {
    return CartStore.itemsForCurrentUser.where((cartItem) {
      return NegotiationStore.canCheckoutProduct(
        cartItem.product.id,
      );
    }).toList();
  }

  // ==================================================
  // PENDING / COUNTERED ITEMS
  // ==================================================

  List<CartItem> get waitingItems {
    return CartStore.itemsForCurrentUser.where((cartItem) {
      return NegotiationStore.hasPendingNegotiation(
        cartItem.product.id,
      );
    }).toList();
  }

  // ==================================================
  // CHECKOUT TOTAL
  // ==================================================

  double get checkoutTotal {
    return checkoutItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  // ==================================================
  // SHOW MESSAGE
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

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
        ),
      );
  }

  // ==================================================
  // PLACE ORDER
  // ==================================================

  Future<void> _placeOrder() async {
    if (isPlacingOrder) {
      return;
    }

    // --------------------------------------------------
    // 1. GET ELIGIBLE ITEMS
    // --------------------------------------------------

    final itemsToCheckout = checkoutItems;

    if (itemsToCheckout.isEmpty) {
      _showMessage(
        waitingItems.isNotEmpty
            ? 'Your products with pending or countered '
                'negotiations must be resolved before checkout.'
            : 'There are no products currently available '
                'for checkout.',
      );
      return;
    }

    // --------------------------------------------------
    // 2. CHECK DELIVERY ADDRESS
    // --------------------------------------------------

    final address = addressController.text.trim();

    if (fulfillmentMethod == 'Delivery' &&
        address.isEmpty) {
      _showMessage(
        'Please enter your delivery address.',
      );
      return;
    }

    // --------------------------------------------------
    // 3. RECHECK NEGOTIATION STATUS
    // --------------------------------------------------
    //
    // The negotiation may have changed while the buyer
    // was on the checkout screen.

    for (final cartItem in itemsToCheckout) {
      final allowed =
          NegotiationStore.canCheckoutProduct(
        cartItem.product.id,
      );

      if (!allowed) {
        _showMessage(
          NegotiationStore.checkoutBlockMessage(
            cartItem.product.id,
          ),
        );
        return;
      }
    }

    // --------------------------------------------------
    // 4. VALIDATE NEGOTIATED PRICES
    // --------------------------------------------------
    //
    // Firebase is the source of truth for product stock.
    // ProductStore is used here only when the product is
    // also available locally.

    for (final cartItem in itemsToCheckout) {
      if (!cartItem.isNegotiated) {
        continue;
      }

      final negotiatedPrice =
          cartItem.negotiatedPrice;

      if (negotiatedPrice == null) {
        continue;
      }

      final localProduct =
          ProductStore.getProduct(
        cartItem.product.id,
      );

      // Firebase-only products may not exist in the
      // local ProductStore. Do not block checkout for
      // that reason.
      if (localProduct == null) {
        continue;
      }

      final valid =
          ProductStore.isNegotiatedPriceValid(
        cartItem.product.id,
        negotiatedPrice,
      );

      if (!valid) {
        _showMessage(
          'The negotiated price for '
          '${cartItem.product.name} is no longer valid.',
        );
        return;
      }
    }

    // --------------------------------------------------
    // 5. CHECK AUTHENTICATED BUYER
    // --------------------------------------------------

    final currentUser =
        AuthService.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Your session has expired. Please log in again.',
      );
      return;
    }

    // --------------------------------------------------
    // 6. CREATE ORDER ITEMS
    // --------------------------------------------------
    //
    // productId identifies the Firebase product.
    // farmerId identifies the farmer who owns it.
    // farmerName is stored as a snapshot for display.
    //
    // effectivePrice automatically gives:
    //
    // negotiated price -> when accepted
    // original price   -> otherwise

    final orderItems =
        itemsToCheckout.map(
      (cartItem) {
        return OrderItem(
          productId:
              cartItem.product.id,
          productName:
              cartItem.product.name,
          farmerId:
              cartItem.product.farmerId,
          farmerName:
              cartItem.product.farmerName,
          price:
              cartItem.effectivePrice,
          quantity:
              cartItem.quantity,
        );
      },
    ).toList();

    // --------------------------------------------------
    // 7. CALCULATE ORDER TOTAL
    // --------------------------------------------------

    final orderTotal =
        orderItems.fold<double>(
      0,
      (sum, item) =>
          sum + item.total,
    );

    // --------------------------------------------------
    // 8. CREATE ORDER
    // --------------------------------------------------

    final order = Order(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      buyerId:
          currentUser.uid,
      buyerName:
          currentUser.name.isNotEmpty
              ? currentUser.name
              : 'Buyer',
      items:
          orderItems,
      total:
          orderTotal,
      deliveryAddress:
          fulfillmentMethod == 'Delivery'
              ? address
              : 'Customer will pick up',
      fulfillmentMethod:
          fulfillmentMethod,
      status:
          'Pending',
      date:
          DateTime.now(),
    );

    // --------------------------------------------------
    // 9. START PLACING ORDER
    // --------------------------------------------------

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // ------------------------------------------------
      // 10. SAVE ORDER + REDUCE FIREBASE STOCK
      // ------------------------------------------------
      //
      // This transaction performs the authoritative stock
      // validation and stock reduction in Firebase.
      //
      // That prevents checkout from depending on a stale
      // local ProductStore quantity.

      await OrderFirestoreService.instance
          .createOrder(order);

      // ------------------------------------------------
      // 11. UPDATE LOCAL PRODUCT STORE
      // ------------------------------------------------
      //
      // Keep the old local state synchronized when the
      // product exists locally.
      //
      // Firebase-only products simply skip this step.

      for (final cartItem in itemsToCheckout) {
        final localProduct =
            ProductStore.getProduct(
          cartItem.product.id,
        );

        if (localProduct != null) {
          ProductStore.reduceStock(
            cartItem.product.id,
            cartItem.quantity,
          );
        }
      }

      // ------------------------------------------------
      // 12. KEEP LOCAL ORDER STORE SYNCHRONIZED
      // ------------------------------------------------

      OrderStore.addOrder(order);

      // ------------------------------------------------
      // 13. REMOVE ONLY CHECKED-OUT ITEMS
      // ------------------------------------------------
      //
      // Pending/countered negotiation items stay in cart.

      for (final cartItem in itemsToCheckout) {
        CartStore.removeItem(cartItem);
      }

      // ------------------------------------------------
      // 14. STOP LOADING
      // ------------------------------------------------

      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }

      // ------------------------------------------------
      // 15. SUCCESS MESSAGE
      // ------------------------------------------------

      _showMessage(
        'Order placed successfully.',
      );

      // ------------------------------------------------
      // 16. RETURN TO BUYER HOME
      // ------------------------------------------------

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const BuyerHomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      // ------------------------------------------------
      // FIREBASE FAILURE
      // ------------------------------------------------

      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }

      final error =
          e.toString().toLowerCase();

      if (error.contains('not enough stock')) {
        _showMessage(
          'There is not enough stock available for '
          'one or more products.',
        );
      } else if (error.contains('out of stock')) {
        _showMessage(
          'One or more products are out of stock.',
        );
      } else if (error.contains('product not found')) {
        _showMessage(
          'One of the products is no longer available.',
        );
      } else if (error.contains('permission-denied')) {
        _showMessage(
          'You do not have permission to place this order.',
        );
      } else if (error.contains('network')) {
        _showMessage(
          'Please check your internet connection and try again.',
        );
      } else {
        _showMessage(
          'Unable to place order. Please try again.',
        );
      }
    }
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final items = checkoutItems;

    final pendingItems = waitingItems;

    final bool isDelivery =
        fulfillmentMethod == 'Delivery';

    final bool hasCheckoutItems =
        items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
        ),
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            AppColors.white,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // PENDING / COUNTERED NEGOTIATIONS
            // ==================================================

            if (pendingItems.isNotEmpty) ...[
              _buildWaitingItemsCard(
                pendingItems,
              ),

              const SizedBox(
                height: 25,
              ),
            ],

            // ==================================================
            // NO ELIGIBLE ITEMS
            // ==================================================

            if (!hasCheckoutItems) ...[
              _buildNoEligibleItems(
                pendingItems,
              ),
            ] else ...[
              // ==================================================
              // FULFILLMENT METHOD
              // ==================================================

              const Text(
                'Fulfillment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // DELIVERY
              // ==================================================

              Card(
                child:
                    RadioListTile<String>(
                  value:
                      'Delivery',
                  groupValue:
                      fulfillmentMethod,
                  onChanged:
                      isPlacingOrder
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                fulfillmentMethod =
                                    value;
                              });
                            },
                  title:
                      const Text(
                    'Delivery',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Have your order delivered to you.',
                  ),
                  secondary:
                      const Icon(
                    Icons
                        .local_shipping_outlined,
                    color:
                        AppColors.primary,
                  ),
                ),
              ),

              // ==================================================
              // PICKUP
              // ==================================================

              Card(
                child:
                    RadioListTile<String>(
                  value:
                      'Pickup',
                  groupValue:
                      fulfillmentMethod,
                  onChanged:
                      isPlacingOrder
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                fulfillmentMethod =
                                    value;
                              });
                            },
                  title:
                      const Text(
                    'Pickup',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Collect your order from the farmer.',
                  ),
                  secondary:
                      const Icon(
                    Icons
                        .storefront_outlined,
                    color:
                        AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // DELIVERY ADDRESS
              // ==================================================

              if (isDelivery) ...[
                const Text(
                  'Delivery Address',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller:
                      addressController,
                  enabled:
                      !isPlacingOrder,
                  maxLines:
                      3,
                  textInputAction:
                      TextInputAction.newline,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter your delivery address',
                    prefixIcon:
                        const Icon(
                      Icons
                          .location_on_outlined,
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
                  height: 30,
                ),
              ],

              // ==================================================
              // PICKUP INFORMATION
              // ==================================================

              if (!isDelivery) ...[
                Card(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.08,
                  ),
                  child:
                      const Padding(
                    padding:
                        EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront,
                          color:
                              AppColors.primary,
                          size:
                              30,
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child:
                              Text(
                            'You will collect this order directly from the farmer.',
                            style:
                                TextStyle(
                              fontSize:
                                  15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],

              // ==================================================
              // ORDER SUMMARY
              // ==================================================

              const Text(
                'Order Summary',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ...items.map(
                (item) {
                  final bool negotiated =
                      item.isNegotiated;

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,

                    title:
                        Text(
                      item.product.name,
                    ),

                    subtitle:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity} × '
                          '₵${item.effectivePrice.toStringAsFixed(2)}',
                        ),

                        if (negotiated)
                          const Text(
                            'Negotiated price',
                            style:
                                TextStyle(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.w600,
                              fontSize:
                                  12,
                            ),
                          ),
                      ],
                    ),

                    trailing:
                        Text(
                      '₵${item.totalPrice.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),

              const Divider(),

              // ==================================================
              // TOTAL
              // ==================================================

              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                title:
                    const Text(
                  'Total',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                trailing:
                    Text(
                  '₵${checkoutTotal.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // PLACE ORDER
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height:
                    55,

                child:
                    ElevatedButton(
                  onPressed:
                      isPlacingOrder
                          ? null
                          : _placeOrder,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        AppColors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade400,
                  ),

                  child:
                      isPlacingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    AppColors.white,
                              ),
                            )
                          : Text(
                              'Place Order • '
                              '₵${checkoutTotal.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                fontSize:
                                    17,
                              ),
                            ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================================================
  // NO ELIGIBLE ITEMS
  // ==================================================

  Widget _buildNoEligibleItems(
    List<CartItem> pendingItems,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(22),

      decoration:
          BoxDecoration(
        color:
            Colors.orange.withValues(
          alpha: 0.06,
        ),

        borderRadius:
            BorderRadius.circular(16),

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
        children: [
          const Icon(
            Icons.lock_outline,
            size:
                65,
            color:
                Colors.orange,
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'Checkout Locked',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            pendingItems.isNotEmpty
                ? 'All products in your cart have '
                  'pending or countered negotiations. '
                  'Wait for those negotiations to be resolved '
                  'before placing an order.'
                : 'There are no products available '
                  'for checkout.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.grey,
              height:
                  1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // WAITING ITEMS CARD
  // ==================================================

  Widget _buildWaitingItemsCard(
    List<CartItem> pendingItems,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
        color:
            Colors.orange.withValues(
          alpha: 0.08,
        ),

        borderRadius:
            BorderRadius.circular(14),

        border:
            Border.all(
          color:
              Colors.orange.withValues(
            alpha: 0.22,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color:
                    Colors.orange,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    Text(
                  'Negotiations in progress',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.orange,
                    fontSize:
                        16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'These products remain in your cart, but '
            'they cannot be checked out until the '
            'negotiation is resolved.',
            style:
                TextStyle(
              color:
                  Colors.grey,
              height:
                  1.4,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          ...pendingItems.map(
            (item) {
              final negotiation =
                  NegotiationStore
                      .findByProduct(
                item.product.id,
              );

              final String status =
                  negotiation?.status ??
                      'Pending';

              final String quantityText =
                  '${item.quantity} unit'
                  '${item.quantity == 1 ? '' : 's'}';

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 8,
                ),

                padding:
                    const EdgeInsets.all(10),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    Row(
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size:
                          20,
                      color:
                          Colors.orange,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            quantityText,
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

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.orange
                                .withValues(
                          alpha: 0.1,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child:
                          Text(
                        status,
                        style:
                            const TextStyle(
                          color:
                              Colors.orange,
                          fontWeight:
                              FontWeight.w600,
                          fontSize:
                              12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}