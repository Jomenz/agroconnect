import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/data/product_firestore_service.dart'
    as product_firestore;
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/cart/presentation/cart_screen.dart';
import 'package:agroconnect/features/order/presentation/orders_screen.dart';
import 'package:agroconnect/features/product/presentation/product_details_screen.dart';
import 'package:agroconnect/features/authentication/presentation/login_screen.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';
import 'package:agroconnect/features/negotiation/presentation/negotiation_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() =>
      _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const BuyerHomePage(),
      const CartScreen(),
      const OrdersScreen(),
      const NegotiationScreen(),
      const BuyerProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        elevation: 8,
        height: 70,
        indicatorColor: AppColors.primary.withValues(
          alpha: 0.12,
        ),
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.shopping_cart_outlined,
            ),
            selectedIcon: Icon(
              Icons.shopping_cart,
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.handshake_outlined,
            ),
            selectedIcon: Icon(
              Icons.handshake,
            ),
            label: 'Negotiations',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// BUYER HOME PAGE
// ======================================================

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({
    super.key,
  });

  @override
  State<BuyerHomePage> createState() =>
      _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream:
          product_firestore.ProductFirestoreService.instance.productsStream,
      builder: (context, snapshot) {
        // --------------------------------------------------
        // LOADING
        // --------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --------------------------------------------------
        // ERROR
        // --------------------------------------------------

        if (snapshot.hasError) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 60,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your internet connection '
                      'and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // --------------------------------------------------
        // FIRESTORE PRODUCTS
        // --------------------------------------------------

        final List<Product> products =
            (snapshot.data ?? [])
                .where(
                  (product) => product.name
                      .toLowerCase()
                      .contains(
                        searchQuery.toLowerCase(),
                      ),
                )
                .toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              28,
            ),
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back 👋',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find fresh produce',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CartScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                      ),
                      color: AppColors.primary,
                      tooltip: 'Open cart',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'Shop quality farm produce directly '
                'from trusted farmers.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // SEARCH
              // ==================================================

              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                textInputAction:
                    TextInputAction.search,
                decoration: InputDecoration(
                  hintText:
                      'Search for tomatoes, maize, mangoes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon:
                      searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            )
                          : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // MARKETPLACE BANNER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fresh from the farm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Discover produce listed by farmers '
                            'and negotiate prices on eligible products.',
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.88,
                              ),
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.14,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // SECTION HEADER
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Products',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${products.length} '
                    '${products.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // PRODUCTS
              // ==================================================

              if (products.isEmpty)
                _buildEmptyProductsState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.69,
                  ),
                  itemCount: products.length,
                  itemBuilder:
                      (context, index) {
                    final product =
                        products[index];

                    return ProductCard(
                      product: product,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ======================================================
  // EMPTY PRODUCTS
  // ======================================================

  Widget _buildEmptyProductsState() {
    final bool isSearching =
        searchQuery.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(
        top: 15,
      ),
      padding: const EdgeInsets.all(
        28,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No products found'
                : 'No products available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching for a different product.'
                : 'Farmers have not added any products yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// PRODUCT CARD
// ======================================================

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final bool outOfStock =
        product.quantity <= 0;

    final bool negotiable =
        ProductStore.canNegotiate(
      product.id,
    );

    return Card(
      elevation: 1.5,
      shadowColor:
          Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailsScreen(
                product: product,
              ),
            ),
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGE AREA
              // ==================================================

              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .primary
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child:
                          const Center(
                        child: Icon(
                          Icons.agriculture,
                          size: 52,
                          color:
                              AppColors.primary,
                        ),
                      ),
                    ),

                    // ------------------------------------------
                    // NEGOTIABLE BADGE
                    // ------------------------------------------

                    if (negotiable)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            'Negotiable',
                            style: TextStyle(
                              color: Colors
                                  .orange
                                  .shade800,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ),

                    // ------------------------------------------
                    // OUT OF STOCK BADGE
                    // ------------------------------------------

                    if (outOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .red
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            'Out of stock',
                            style: TextStyle(
                              color:
                                  Colors.red.shade700,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // PRODUCT NAME
              // ==================================================

              Text(
                product.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // PRICE
              // ==================================================

              Text(
                'GH₵${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color:
                      AppColors.primary,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              // ==================================================
              // STOCK
              // ==================================================

              Row(
                children: [
                  Icon(
                    outOfStock
                        ? Icons.cancel_outlined
                        : Icons
                            .inventory_2_outlined,
                    size: 13,
                    color: outOfStock
                        ? Colors.red
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      outOfStock
                          ? 'Currently unavailable'
                          : '${product.quantity} available',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: outOfStock
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // VIEW PRODUCT
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 37,
                child:
                    OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(
                          product: product,
                        ),
                      ),
                    );
                  },
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                    side: BorderSide(
                      color: AppColors
                          .primary
                          .withValues(
                        alpha: 0.7,
                      ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    padding:
                        EdgeInsets.zero,
                  ),
                  child:
                      const Text(
                    'View Product',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// BUYER PROFILE
// ======================================================

class BuyerProfilePage
    extends StatelessWidget {
  const BuyerProfilePage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser =
        AuthService.instance.currentUser;

    final displayName =
        currentUser?.name.isNotEmpty == true
            ? currentUser!.name
            : 'Buyer';

    final displayEmail =
        currentUser?.email.isNotEmpty == true
            ? currentUser!.email
            : 'buyer@example.com';

    final displayPhone =
        currentUser?.phone.isNotEmpty == true
            ? currentUser!.phone
            : 'Not provided';

    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          22,
          20,
          30,
        ),
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Manage your account',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // ==================================================
          // PROFILE HEADER
          // ==================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
              20,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppColors.primary,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child:
                Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons.person,
                    size: 48,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  displayName,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'AgroConnect Customer',
                  style:
                      TextStyle(
                    color: Colors
                        .white
                        .withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // ==================================================
          // ACCOUNT INFORMATION
          // ==================================================

          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Card(
            elevation: 1,
            margin:
                EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              side: BorderSide(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child:
                Column(
              children: [
                _ProfileInfoTile(
                  icon:
                      Icons.person_outline,
                  title:
                      'Full Name',
                  value:
                      displayName,
                ),

                Divider(
                  height: 1,
                  indent: 55,
                  color:
                      Colors.grey.shade200,
                ),

                _ProfileInfoTile(
                  icon:
                      Icons.email_outlined,
                  title:
                      'Email',
                  value:
                      displayEmail,
                ),

                Divider(
                  height: 1,
                  indent: 55,
                  color:
                      Colors.grey.shade200,
                ),

                _ProfileInfoTile(
                  icon:
                      Icons.phone_outlined,
                  title:
                      'Phone',
                  value:
                      displayPhone,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // ==================================================
          // LOGOUT
          // ==================================================

          Card(
            elevation: 1,
            margin:
                EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              side: BorderSide(
                color:
                    Colors.red.shade100,
              ),
            ),
            child:
                ListTile(
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading:
                  Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color: Colors.red
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    const Icon(
                  Icons.logout,
                  color:
                      Colors.red,
                ),
              ),
              title:
                  const Text(
                'Log Out',
                style:
                    TextStyle(
                  color:
                      Colors.red,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  const Text(
                'Sign out of your AgroConnect account',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
                  fontSize:
                      12,
                ),
              ),
              trailing:
                  const Icon(
                Icons
                    .arrow_forward_ios,
                color:
                    Colors.red,
                size:
                    16,
              ),
              onTap: () async {
                await AuthService
                    .instance
                    .signOut();

                if (!context.mounted) {
                  return;
                }

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// PROFILE INFO TILE
// ======================================================

class _ProfileInfoTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading:
          Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(
          color:
              AppColors.primary
                  .withValues(
            alpha: 0.08,
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
          size: 21,
        ),
      ),
      title:
          Text(
        title,
        style:
            const TextStyle(
          fontSize: 12,
          color:
              Colors.grey,
        ),
      ),
      subtitle:
          Padding(
        padding:
            const EdgeInsets.only(
          top: 2,
        ),
        child:
            Text(
          value,
          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}