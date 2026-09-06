import 'package:flutter/material.dart';

import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/order/models/order.dart';
import 'package:agroconnect/features/product/data/product_firestore_service.dart';
import 'package:agroconnect/features/order/data/order_firestore_service.dart';
import 'package:agroconnect/features/authentication/presentation/login_screen.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      AdminDashboardPage(
        onNavigate: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const AdminProductsPage(),
      const AdminOrdersPage(),
      const AdminProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboardPage extends StatelessWidget {
  final Function(int) onNavigate;

  const AdminDashboardPage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: ProductFirestoreService.instance.productsStream,
      builder: (context, productSnapshot) {
        return StreamBuilder<List<Order>>(
          stream: OrderFirestoreService.instance.adminOrdersStream(),
          builder: (context, orderSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting ||
                orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF7F8F6),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (productSnapshot.hasError || orderSnapshot.hasError) {
              return const Scaffold(
                backgroundColor: Color(0xFFF7F8F6),
                body: Center(
                  child: Text(
                    'Unable to load marketplace data.',
                  ),
                ),
              );
            }

            final products = productSnapshot.data ?? [];
            final orders = orderSnapshot.data ?? [];

            final productCount = products.length;
            final orderCount = orders.length;

            final pendingOrders = orders
                .where((order) => order.status == 'Pending')
                .length;

            final completedOrders = orders
                .where((order) => order.status == 'Completed')
                .length;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 6),
                          ],
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.primary,
                          size: 25,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Monitor and manage your AgroConnect marketplace.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _AdminDashboardCard(
                          title: 'Products',
                          value: '$productCount',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminDashboardCard(
                          title: 'Orders',
                          value: '$orderCount',
                          icon: Icons.receipt_long_outlined,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _AdminDashboardCard(
                          title: 'Pending',
                          value: '$pendingOrders',
                          icon: Icons.pending_actions_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminDashboardCard(
                          title: 'Completed',
                          value: '$completedOrders',
                          icon: Icons.task_alt,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Access the most important admin tools.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 13),

                  _QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'View Products',
                    subtitle:
                        'Review products currently listed on AgroConnect.',
                    onTap: () {
                      onNavigate(1);
                    },
                  ),

                  const SizedBox(height: 10),

                  _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'View Orders',
                    subtitle:
                        'Monitor customer orders and fulfillment status.',
                    onTap: () {
                      onNavigate(2);
                    },
                  ),

                  const SizedBox(height: 10),

                  _QuickActionCard(
                    icon: Icons.people_outline,
                    title: 'Marketplace Activity',
                    subtitle:
                        'Keep track of products and orders across the platform.',
                    onTap: () {
                      onNavigate(1);
                    },
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Use the admin dashboard to monitor '
                            'marketplace activity and keep products '
                            'and orders organized.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// DASHBOARD STAT CARD
// ============================================================

class _AdminDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION CARD
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN PRODUCTS
// ============================================================

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() =>
      _AdminProductsPageState();
}

class _AdminProductsPageState
    extends State<AdminProductsPage> {
  void _deleteProduct(
    String productId,
    String productName,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Remove Product',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove '
            '"$productName" from AgroConnect?',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ProductFirestoreService.instance
                      .deleteProduct(productId);

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(dialogContext);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        '$productName removed successfully.',
                      ),
                      behavior:
                          SnackBarBehavior.floating,
                    ),
                  );
                } catch (_) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(dialogContext);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to remove product.',
                      ),
                      behavior:
                          SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(11),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 50,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No products have been listed on '
              'AgroConnect yet.',
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

  Widget _productCard(Product product) {
    final isOutOfStock =
        product.quantity <= 0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            width: 58,
                            height: 58,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.agriculture_outlined,
                                color: AppColors.primary,
                                size: 29,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.agriculture_outlined,
                          color: AppColors.primary,
                          size: 29,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₵${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color:
                              AppColors.primary,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Farmer: ${product.farmerName}',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove product',
                  onPressed: () {
                    _deleteProduct(
                      product.id,
                      product.name,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                product.description,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _ProductInfoChip(
                    icon:
                        Icons.inventory_2_outlined,
                    label: isOutOfStock
                        ? 'Out of stock'
                        : '${product.quantity} units',
                    color: isOutOfStock
                        ? Colors.red
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ProductInfoChip(
                    icon:
                        Icons.handshake_outlined,
                    label: product.allowNegotiation
                        ? 'Negotiable'
                        : 'Fixed price',
                    color: product.allowNegotiation
                        ? Colors.orange
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (product.allowNegotiation &&
                product.minimumPrice != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.price_check_outlined,
                      size: 17,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Minimum negotiation price: '
                      '₵${product.minimumPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream:
          ProductFirestoreService.instance.productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFF7F8F6),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFF7F8F6),
            body: Center(
              child: Text(
                'Unable to load products.',
              ),
            ),
          );
        }

        final products = snapshot.data ?? [];

        return Scaffold(
          backgroundColor:
              const Color(0xFFF7F8F6),
          body: SafeArea(
            child: products.isEmpty
                ? _emptyState()
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      30,
                    ),
                    children: [
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review and manage products listed by farmers.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .inventory_2_outlined,
                              size: 18,
                              color:
                                  AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${products.length} '
                              'product${products.length == 1 ? '' : 's'} listed',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors.primary,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...products.map(_productCard),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ============================================================
// PRODUCT INFO CHIP
// ============================================================

class _ProductInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProductInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN ORDERS
// ============================================================

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() =>
      _AdminOrdersPageState();
}

class _AdminOrdersPageState
    extends State<AdminOrdersPage> {
  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blue;

      case 'Preparing':
        return Colors.orange;

      case 'Ready':
        return Colors.purple;

      case 'Completed':
        return Colors.green;

      case 'Rejected':
        return Colors.red;

      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle_outline;

      case 'Preparing':
        return Icons.inventory_2_outlined;

      case 'Ready':
        return Icons.local_shipping_outlined;

      case 'Completed':
        return Icons.task_alt;

      case 'Rejected':
        return Icons.cancel_outlined;

      case 'Pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String _shortOrderId(String id) {
    if (id.length <= 6) {
      return id;
    }

    return id.substring(id.length - 6);
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 105,
              width: 105,
              decoration:
                  BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 50,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Orders',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer orders will appear here '
              'when buyers place orders.',
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

  Widget _orderCard(Order order) {
    final statusColor =
        _statusColor(order.status);

    final statusIcon =
        _statusIcon(order.status);

    final isDelivery =
        order.fulfillmentMethod ==
            'Delivery';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      Icon(
                    statusIcon,
                    color: statusColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Order',
                        style:
                            TextStyle(
                          color: Colors.grey,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${_shortOrderId(order.id)}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    order.status,
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

            const SizedBox(height: 15),

            const Text(
              'Order Items',
              style:
                  TextStyle(
                fontSize: 13.5,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 9),

            ...order.items.map(
              (item) => Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 7,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} × ${item.quantity}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '₵${item.total.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 22),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Total',
                  style:
                      TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  '₵${order.total.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    color:
                        AppColors.primary,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(11),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDelivery
                        ? Icons
                            .local_shipping_outlined
                        : Icons
                            .storefront_outlined,
                    color:
                        AppColors.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivery
                              ? 'Delivery'
                              : 'Pickup',
                          style:
                              const TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDelivery
                              ? order.deliveryAddress
                              : 'Customer will collect the order from the farmer.',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream:
          OrderFirestoreService.instance.adminOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFF7F8F6),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFF7F8F6),
            body: Center(
              child: Text(
                'Unable to load orders.',
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        return Scaffold(
          backgroundColor:
              const Color(0xFFF7F8F6),
          body: SafeArea(
            child: orders.isEmpty
                ? _emptyState()
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      30,
                    ),
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitor customer orders and their fulfillment status.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.blue.withValues(
                            alpha: 0.06,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .receipt_long_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${orders.length} '
                              'order${orders.length == 1 ? '' : 's'}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.blue,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...orders.map(_orderCard),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ADMIN PROFILE
// ============================================================

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser =
        AuthService.instance.currentUser;

    final adminName =
        currentUser?.name.isNotEmpty == true
            ? currentUser!.name
            : 'Administrator';

    final adminEmail =
        currentUser?.email.isNotEmpty == true
            ? currentUser!.email
            : 'admin@agroconect.com';

    final adminPhone =
        currentUser?.phone.isNotEmpty == true
            ? currentUser!.phone
            : 'Ghana';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F6),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          children: [
            const Text(
              'Admin Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Manage administrator information and your session.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 20,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color:
                      Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.03,
                    ),
                    blurRadius: 8,
                    offset:
                        const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 86,
                    width: 86,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .admin_panel_settings_outlined,
                      color:
                          AppColors.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    adminName,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AgroConnect Admin',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color:
                      Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _ProfileInfoTile(
                    icon:
                        Icons.person_outline,
                    title: 'Name',
                    value: adminName,
                  ),
                  Divider(
                    height: 1,
                    color:
                        Colors.grey.shade200,
                  ),
                  _ProfileInfoTile(
                    icon:
                        Icons.email_outlined,
                    title: 'Email',
                    value: adminEmail,
                  ),
                  Divider(
                    height: 1,
                    color:
                        Colors.grey.shade200,
                  ),
                  _ProfileInfoTile(
                    icon:
                        Icons.phone_outlined,
                    title: 'Phone',
                    value: adminPhone,
                  ),
                  Divider(
                    height: 1,
                    color:
                        Colors.grey.shade200,
                  ),
                  const _ProfileInfoTile(
                    icon:
                        Icons.security_outlined,
                    title: 'Account Type',
                    value:
                        'Administrator',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Material(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(16),
                onTap: () async {
                  await AuthService.instance
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
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color:
                          Colors.red.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color:
                            Colors.red,
                        size: 21,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Log Out',
                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                                fontSize:
                                    13.5,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Return to the login screen.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons
                            .arrow_forward_ios,
                        color:
                            Colors.grey,
                        size: 15,
                      ),
                    ],
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

// ============================================================
// PROFILE INFO TILE
// ============================================================

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
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration:
                BoxDecoration(
              color:
                  AppColors.primary.withValues(
                alpha: 0.07,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color:
                  AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 13,
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