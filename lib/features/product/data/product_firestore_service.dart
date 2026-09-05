import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agroconnect/features/product/models/product.dart';

class ProductFirestoreService {
  ProductFirestoreService._();

  static final ProductFirestoreService instance =
      ProductFirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<void> addProduct(Product product) async {
    await _products.doc(product.id).set({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'quantity': product.quantity,
      'description': product.description,
      'farmerName': product.farmerName,
      'farmerId': product.farmerId,
      'allowNegotiation': product.allowNegotiation,
      'minimumPrice': product.minimumPrice,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(Product product) async {
    await _products.doc(product.id).update({
      'name': product.name,
      'price': product.price,
      'quantity': product.quantity,
      'description': product.description,
      'farmerName': product.farmerName,
      'farmerId': product.farmerId,
      'allowNegotiation': product.allowNegotiation,
      'minimumPrice': product.minimumPrice,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  Stream<List<Product>> get productsStream {
    return _products.snapshots().map(_mapSnapshot);
  }

  Stream<List<Product>> farmerProductsStream(String farmerId) {
    return _products
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map(_mapSnapshot);
  }

  List<Product> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (doc) => _fromFirestore(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  Product _fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return Product(
      id: documentId,
      name: data['name']?.toString() ?? '',
      price: _toDouble(data['price']),
      quantity: _toInt(data['quantity']),
      description: data['description']?.toString() ?? '',
      farmerName: data['farmerName']?.toString() ?? 'Farmer',
      farmerId: data['farmerId']?.toString() ?? '',
      allowNegotiation: data['allowNegotiation'] == true,
      minimumPrice: data['minimumPrice'] == null
          ? null
          : _toDouble(data['minimumPrice']),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
