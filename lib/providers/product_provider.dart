import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> saveProduct(Product product) async {
    try {
      if (product.id != null) {
        await _db.updateProduct(product);
      } else {
        await _db.insertProduct(product);
      }
      await loadProducts();
      return 'ok';
    } catch (e) {
      return 'Error al guardar: $e';
    }
  }

  Future<void> searchProducts(String query) async {
    _searchResults = await _db.searchProducts(query);
    notifyListeners();
  }
}
