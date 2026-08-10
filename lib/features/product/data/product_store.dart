import '../models/product.dart';

class ProductStore {
  ProductStore._();

  static final List<Product> products = [
    Product(
      id: 'demo_001',
      name: 'Tomatoes',
      price: 25.00,
      quantity: 20,
      description: 'Fresh farm tomatoes.',
      farmerName: 'Demo Farmer',
    ),
    Product(
      id: 'demo_002',
      name: 'Maize',
      price: 18.00,
      quantity: 30,
      description: 'Quality locally grown maize.',
      farmerName: 'Demo Farmer',
    ),
    Product(
      id: 'demo_003',
      name: 'Mangoes',
      price: 15.00,
      quantity: 25,
      description: 'Fresh and sweet mangoes.',
      farmerName: 'Demo Farmer',
    ),
    Product(
      id: 'demo_004',
      name: 'Potatoes',
      price: 20.00,
      quantity: 40,
      description: 'Fresh farm potatoes.',
      farmerName: 'Demo Farmer',
    ),
  ];

  static void addProduct(Product product) {
    products.add(product);
  }
}