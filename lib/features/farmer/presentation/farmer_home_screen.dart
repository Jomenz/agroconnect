import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/product/models/product.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/authentication/presentation/login_screen.dart';
import 'package:agroconnect/features/order/models/order.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      FarmerHomePage(
        onNavigate: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const AddProductPage(),
      const FarmerOrdersPage(),
      const FarmerProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// FARMER HOME
// --------------------------------------------------

class FarmerHomePage extends StatelessWidget {
  final Function(int) onNavigate;

  const FarmerHomePage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final productCount = ProductStore.products.length;
    final orderCount = OrderStore.orders.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Welcome, Farmer 👨‍🌾',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your farm products and orders.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: _DashboardCard(
                    title: 'Products',
                    value: '$productCount',
                    icon: Icons.inventory_2,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _DashboardCard(
                    title: 'Orders',
                    value: '$orderCount',
                    icon: Icons.shopping_bag,
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

            // ADD PRODUCT
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.add_circle,
                  color: AppColors.primary,
                  size: 35,
                ),
                title: const Text(
                  'Add New Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'List your farm produce for buyers.',
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

            // VIEW ORDERS
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
                  'Check orders from customers.',
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
      ),
    );
  }
}

// --------------------------------------------------
// DASHBOARD CARD
// --------------------------------------------------

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({
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
// ADD PRODUCT
// --------------------------------------------------

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  void _addProduct() {
    final String name = nameController.text.trim();

    final double? price =
        double.tryParse(priceController.text.trim());

    final int? quantity =
        int.tryParse(quantityController.text.trim());

    final String description =
        descriptionController.text.trim();

    if (name.isEmpty ||
        price == null ||
        quantity == null ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all product details.',
          ),
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Price must be greater than 0.',
          ),
        ),
      );
      return;
    }

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quantity must be greater than 0.',
          ),
        ),
      );
      return;
    }

    final product = Product(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      name: name,
      price: price,
      quantity: quantity,
      description: description,
      farmerName: 'Farmer',
    );

    ProductStore.addProduct(product);

    nameController.clear();
    priceController.clear();
    quantityController.clear();
    descriptionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Product added successfully!',
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Add Product',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'List your farm produce for buyers.',
              style: TextStyle(
                color: AppColors.grey,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                prefixIcon: const Icon(
                  Icons.shopping_basket_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: '₵ ',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                prefixIcon: const Icon(
                  Icons.inventory_2_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 55),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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

// --------------------------------------------------
// ORDERS
// --------------------------------------------------

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key});

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> {
  void _updateOrderStatus(Order order, String newStatus) {
    setState(() {
      order.status = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order status updated to $newStatus.',
        ),
      ),
    );
  }

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

  List<Widget> _statusButtons(Order order) {
    switch (order.status) {
      case 'Pending':
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Rejected',
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(
                  color: Colors.red,
                ),
              ),
              child: const Text('Reject'),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Accepted',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Accept'),
            ),
          ),
        ];

      case 'Accepted':
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Preparing',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Start Preparing'),
            ),
          ),
        ];

      case 'Preparing':
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Ready',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Mark as Ready'),
            ),
          ),
        ];

      case 'Ready':
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(
                  order,
                  'Completed',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Complete Order'),
            ),
          ),
        ];

      case 'Completed':
      case 'Rejected':
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderStore.orders;

    if (orders.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: AppColors.primary,
              ),

              SizedBox(height: 20),

              Text(
                'No Orders Yet',
                style: TextStyle(
                  fontSize: 24,
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
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,

        itemBuilder: (context, index) {
          final order = orders[index];

          final statusColor = _statusColor(
            order.status,
          );

          final buttons = _statusButtons(
            order,
          );

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
                  // ORDER HEADER
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        'Order #${order.id.substring(order.id.length - 6)}',

                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration: BoxDecoration(
                          color: statusColor
                              .withOpacity(0.15),

                          borderRadius:
                              BorderRadius.circular(20),
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

                  // PRODUCTS
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

                  // TOTAL
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      const Text(
                        'Order Total',
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

                  const SizedBox(height: 10),

                  // DELIVERY ADDRESS
                  Text(
                    'Delivery: ${order.deliveryAddress}',

                    style:
                        const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  // STATUS BUTTONS
                  if (buttons.isNotEmpty) ...[
                    const SizedBox(height: 15),

                    Row(
                      children: buttons,
                    ),
                  ],
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
// PROFILE
// --------------------------------------------------

class FarmerProfilePage extends StatelessWidget {
  const FarmerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Farmer Profile',
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
              Icons.person,
              size: 55,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'Farmer',
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
                  subtitle: Text('Farmer'),
                ),

                const Divider(height: 1),

                const ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Email'),
                  subtitle: Text('farmer@example.com'),
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