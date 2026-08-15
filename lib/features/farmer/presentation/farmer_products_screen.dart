import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/product/models/product.dart';

class FarmerProductsScreen extends StatefulWidget {
  const FarmerProductsScreen({super.key});

  @override
  State<FarmerProductsScreen> createState() =>
      _FarmerProductsScreenState();
}

class _FarmerProductsScreenState
    extends State<FarmerProductsScreen> {

  void _showEditProductDialog(Product product) {
    final nameController =
        TextEditingController(text: product.name);

    final priceController =
        TextEditingController(
      text: product.price.toString(),
    );

    final quantityController =
        TextEditingController(
      text: product.quantity.toString(),
    );

    final descriptionController =
        TextEditingController(
      text: product.description,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Product',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: const Icon(
                      Icons.shopping_basket_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

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
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Available Quantity',
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 35),
                      child: Icon(
                        Icons.description_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
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
              onPressed: () {

                final name =
                    nameController.text.trim();

                final price =
                    double.tryParse(
                  priceController.text.trim(),
                );

                final quantity =
                    int.tryParse(
                  quantityController.text.trim(),
                );

                final description =
                    descriptionController.text.trim();

                if (name.isEmpty ||
                    price == null ||
                    quantity == null ||
                    description.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill in all product details.',
                      ),
                    ),
                  );

                  return;
                }

                if (price <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Price must be greater than 0.',
                      ),
                    ),
                  );

                  return;
                }

                if (quantity <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Quantity must be greater than 0.',
                      ),
                    ),
                  );

                  return;
                }

                final updatedProduct = Product(
                  id: product.id,
                  name: name,
                  price: price,
                  quantity: quantity,
                  description: description,
                  farmerName: product.farmerName,
                );

                ProductStore.updateProduct(
                  updatedProduct,
                );

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Product updated successfully!',
                    ),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    AppColors.white,
              ),

              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(Product product) {

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Product?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'Are you sure you want to delete '
            '"${product.name}"? This action cannot be undone.',
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

                ProductStore.deleteProduct(
                  product.id,
                );

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '${product.name} deleted successfully.',
                    ),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final products = ProductStore.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),

      body: products.isEmpty
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
                    'No Products Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Products you add will appear here.',
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

                  elevation: 2,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              width: 60,
                              height: 60,

                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),

                              child: const Icon(
                                Icons.agriculture,
                                size: 32,
                                color:
                                    AppColors.primary,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  Text(
                                    product.name,
                                    style:
                                        const TextStyle(
                                      fontSize: 19,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    '₵${product.price.toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(
                                      color:
                                          AppColors.primary,
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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

                            const SizedBox(width: 6),

                            Text(
                              'Available: '
                              '${product.quantity} units',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        const Divider(),

                        const SizedBox(height: 5),

                        Row(
                          children: [

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showEditProductDialog(
                                    product,
                                  );
                                },

                                icon: const Icon(
                                  Icons.edit_outlined,
                                ),

                                label: const Text(
                                  'Edit',
                                ),

                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.primary,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _deleteProduct(
                                    product,
                                  );
                                },

                                icon: const Icon(
                                  Icons.delete_outline,
                                ),

                                label: const Text(
                                  'Delete',
                                ),

                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.red,
                                  side:
                                      const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
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