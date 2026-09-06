import 'dart:async';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ==================================================
  // ITEMS READY FOR CHECKOUT
  // ==================================================

  List<CartItem> get _checkoutItems {
    return CartStore.itemsForCurrentUser
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
    return CartStore.itemsForCurrentUser
        .where(
          _isQuantityLocked,
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
    final status = _getNegotiationStatus(item);

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
        builder: (_) => const CheckoutScreen(),
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
    if (_isQuantityLocked(item)) {
      _showMessage(
        'This product cannot be removed while '
        'the negotiation is unresolved.',
      );
      return;
    }

    final productName = item.product.name;

    CartStore.removeItem(item);

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '$productName removed from your cart.',
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

    if (item.quantity >= item.availableQuantity) {
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

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(
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
    final items = CartStore.itemsForCurrentUser;
    final waitingItems = _waitingItems;
    final checkoutItems = _checkoutItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const _EmptyCartState()
          : Column(
              children: [
                // ==================================================
                // NEGOTIATION WARNING
                // ==================================================

                if (waitingItems.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      8,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.hourglass_top,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${waitingItems.length} '
                            '${waitingItems.length == 1 ? 'item is' : 'items are'} '
                            'currently in negotiation. '
                            'Quantity changes and removal are locked '
                            'until the negotiation is resolved.',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              height: 1.4,
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      final negotiationLocked =
                          _isQuantityLocked(item);

                      final canCheckout =
                          NegotiationStore.canCheckoutProduct(
                        item.product.id,
                      );

                      final displayedPrice =
                          item.effectivePrice;

                      final status =
                          _getNegotiationStatus(item);

                      return _CartItemCard(
                        item: item,
                        negotiationLocked: negotiationLocked,
                        canCheckout: canCheckout,
                        displayedPrice: displayedPrice,
                        status: status,
                        waitingMessage:
                            _getWaitingMessage(item),
                        onRemove: () => _removeItem(item),
                        onDecrease: () =>
                            _decreaseQuantity(item),
                        onIncrease: () =>
                            _increaseQuantity(item),
                      );
                    },
                  ),
                ),

                // ==================================================
                // BOTTOM CHECKOUT SECTION
                // ==================================================

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.07,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        if (waitingItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ready for checkout',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${checkoutItems.length} '
                                  '${checkoutItems.length == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Checkout Total',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'GH₵${_checkoutTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: checkoutItems.isNotEmpty
                                ? _proceedToCheckout
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              disabledForegroundColor:
                                  Colors.grey.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                            ),
                            child: Text(
                              checkoutItems.isNotEmpty
                                  ? 'Proceed to Checkout'
                                  : waitingItems.isNotEmpty
                                      ? 'Waiting for Negotiation'
                                      : 'No Items Ready',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ======================================================
// CART ITEM CARD
// ======================================================

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool negotiationLocked;
  final bool canCheckout;
  final double displayedPrice;
  final String status;
  final String waitingMessage;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CartItemCard({
    required this.item,
    required this.negotiationLocked,
    required this.canCheckout,
    required this.displayedPrice,
    required this.status,
    required this.waitingMessage,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT INFORMATION
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      if (item.isNegotiated)
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Listed price: '
                              'GH₵${item.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration:
                                    TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Negotiated: '
                              'GH₵${displayedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'GH₵${displayedPrice.toStringAsFixed(2)} each',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 4),

                      Text(
                        'Farmer: ${item.product.farmerName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onRemove,
                  tooltip: negotiationLocked
                      ? 'Locked while negotiation is unresolved'
                      : 'Remove from cart',
                  icon: Icon(
                    negotiationLocked
                        ? Icons.lock_outline
                        : Icons.delete_outline,
                    color: negotiationLocked
                        ? Colors.grey
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // ==================================================
            // QUANTITY + TOTAL
            // ==================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:
                              negotiationLocked ||
                                      item.quantity <= 1
                                  ? null
                                  : onDecrease,
                          icon: const Icon(
                            Icons.remove,
                            size: 18,
                          ),
                          visualDensity:
                              VisualDensity.compact,
                        ),

                        Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 30,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (negotiationLocked)
                                const Padding(
                                  padding: EdgeInsets.only(
                                    right: 4,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 13,
                                    color: Colors.orange,
                                  ),
                                ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed:
                              negotiationLocked ||
                                      item.quantity >=
                                          item.availableQuantity
                                  ? null
                                  : onIncrease,
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                          visualDensity:
                              VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Text(
                    'GH₵${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // NEGOTIATION STATUS
            // ==================================================

            if (negotiationLocked)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status == 'Countered'
                          ? Icons.reply_outlined
                          : Icons.hourglass_top,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            waitingMessage,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
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

            if (!negotiationLocked && !canCheckout)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'This item is not currently available for checkout.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// EMPTY CART STATE
// ======================================================

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 94,
              width: 94,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add products to your cart to continue shopping.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}