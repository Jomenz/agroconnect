import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/authentication/presentation/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
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

    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// ADMIN DASHBOARD
// --------------------------------------------------

class AdminDashboardPage extends StatelessWidget {
  final Function(int) onNavigate;

  const AdminDashboardPage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final productCount = ProductStore.products.length;
    final orderCount = OrderStore.orders.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Monitor and manage Agroconect.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: _AdminDashboardCard(
                  title: 'Products',
                  value: '$productCount',
                  icon: Icons.inventory_2_outlined,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _AdminDashboardCard(
                  title: 'Orders',
                  value: '$orderCount',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2,
                color: AppColors.primary,
                size: 35,
              ),
              title: const Text(
                'View Products',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Review products listed on Agroconect.',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                onNavigate(1);
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
                size: 35,
              ),
              title: const Text(
                'View Orders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Monitor customer orders and statuses.',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                onNavigate(2);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// DASHBOARD CARD
// --------------------------------------------------

class _AdminDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AdminDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 32,
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// ADMIN PRODUCTS
// --------------------------------------------------

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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Product'),
          content: Text(
            'Are you sure you want to remove "$productName" from Agroconect?',
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
                ProductStore.deleteProduct(productId);

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$productName removed successfully.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductStore.products;

    return SafeArea(
      child: products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 20),

                  Text(
                    'No Products',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'No products have been listed yet.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                color:
                                    AppColors.primary,
                                size: 30,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    product.name,
                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '₵${product.price.toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(
                                      color:
                                          AppColors.primary,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _deleteProduct(
                                  product.id,
                                  product.name,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          product.description,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              'Available: ${product.quantity} units',
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Farmer: ${product.farmerName}',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --------------------------------------------------
// ADMIN ORDERS
// --------------------------------------------------

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

  @override
  Widget build(BuildContext context) {
    final orders = OrderStore.orders;

    return SafeArea(
      child: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 20),

                  Text(
                    'No Orders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Customer orders will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final statusColor =
                    _statusColor(order.status);

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                          children: [
                            Text(
                              'Order #${order.id.substring(order.id.length - 6)}',
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius
                                        .circular(20),
                              ),

                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          'Products',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ...order.items.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 6,
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} × ${item.quantity}',
                                  ),
                                ),

                                Text(
                                  '₵${item.total.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              '₵${order.total.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Fulfillment: ${order.fulfillmentMethod}',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Address: ${order.deliveryAddress}',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --------------------------------------------------
// ADMIN PROFILE
// --------------------------------------------------

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Admin Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.admin_panel_settings,
              size: 55,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'Administrator',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Name'),
                  subtitle: Text('Administrator'),
                ),

                const Divider(height: 1),

                const ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Email'),
                  subtitle: Text('admin@agroconect.com'),
                ),

                const Divider(height: 1),

                const ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Location'),
                  subtitle: Text('Ghana'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),

              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
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