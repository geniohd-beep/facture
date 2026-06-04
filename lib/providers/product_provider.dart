import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

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
        final existing = await _db.getProductByCode(product.code);
        await _db.updateProduct(product);
        if (existing != null && existing.stock != product.stock) {
          await _db.recordKardexFromAdjustment(
            productId: product.id!,
            productCode: product.code,
            productName: product.name,
            oldStock: existing.stock,
            newStock: product.stock,
          );
        }
      } else {
        final newId = await _db.insertProduct(product);
        if (product.stock > 0) {
          await _db.recordKardexFromAdjustment(
            productId: newId,
            productCode: product.code,
            productName: product.name,
            oldStock: 0,
            newStock: product.stock,
          );
        }
      }
      await loadProducts();
      SyncService.instance.sync();
      return 'ok';
    } catch (e) {
      return 'Error al guardar: $e';
    }
  }

  Future<void> searchProducts(String query) async {
    _searchResults = await _db.searchProducts(query);
    notifyListeners();
  }

  Future<String> exportProductsToJson() async {
    final all = await _db.getAllProducts();
    final list = all.map((p) => {
      'code': p.code,
      'name': p.name,
      'description': p.description,
      'category': p.category,
      'purchase_price': p.purchasePrice,
      'sale_price': p.salePrice,
      'stock': p.stock,
      'unit_type': p.unitType,
      'is_active': p.isActive ? 1 : 0,
    }).toList();
    final json = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'products': list,
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<String> importProductsFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = data['products'] as List<dynamic>;
      int imported = 0;
      for (final item in list) {
        final product = Product(
          code: item['code'],
          name: item['name'],
          description: item['description'] ?? '',
          category: item['category'] ?? '',
          purchasePrice: (item['purchase_price'] ?? 0).toDouble(),
          salePrice: (item['sale_price'] ?? 0).toDouble(),
          stock: item['stock'] ?? 0,
          unitType: item['unit_type'] ?? 'UNIDAD',
          isActive: (item['is_active'] ?? 1) == 1,
        );
        await _db.insertProductIfNotExists(product);
        imported++;
      }
      await loadProducts();
      return 'Importados $imported productos correctamente';
    } catch (e) {
      return 'Error al importar: $e';
    }
  }
}
