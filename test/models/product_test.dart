import 'package:flutter_test/flutter_test.dart';
import 'package:facture/models/product.dart';

void main() {
  group('Product', () {
    test('fromMap and toMap roundtrip', () {
      final product = Product(
        id: 1,
        code: 'P001',
        name: 'LAPTOP',
        description: 'Laptop HP',
        category: 'EQUIPOS',
        purchasePrice: 2500.00,
        salePrice: 3500.00,
        stock: 10,
        unitType: 'UNIDAD',
      );

      final map = product.toMap();
      final restored = Product.fromMap(map);

      expect(restored.code, product.code);
      expect(restored.name, product.name);
      expect(restored.salePrice, product.salePrice);
      expect(restored.stock, product.stock);
      expect(restored.isActive, true);
    });

    test('default values', () {
      final product = Product(
        code: 'P001',
        name: 'Test',
        purchasePrice: 100,
        salePrice: 200,
      );

      expect(product.stock, 0);
      expect(product.unitType, 'UNIDAD');
      expect(product.isActive, true);
      expect(product.description, '');
    });

    test('copyWith overrides only specified fields', () {
      final product = Product(
        id: 1,
        code: 'P001',
        name: 'ORIGINAL',
        purchasePrice: 100,
        salePrice: 200,
      );

      final copy = product.copyWith(name: 'MODIFIED', salePrice: 300);
      expect(copy.name, 'MODIFIED');
      expect(copy.salePrice, 300);
      expect(copy.code, 'P001');
      expect(copy.purchasePrice, 100);
    });
  });
}
