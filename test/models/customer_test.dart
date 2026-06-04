import 'package:flutter_test/flutter_test.dart';
import 'package:facture/models/customer.dart';

void main() {
  group('Customer', () {
    test('fromMap and toMap roundtrip', () {
      final customer = Customer(
        id: 1,
        documentType: 'DNI',
        documentNumber: '12345678',
        firstName: 'Juan',
        lastName: 'Perez',
        fullName: 'Juan Perez',
        address: 'Av. Lima 123',
        phone: '999888777',
        email: 'juan@test.com',
      );

      final map = customer.toMap();
      final restored = Customer.fromMap(map);

      expect(restored.id, customer.id);
      expect(restored.documentType, customer.documentType);
      expect(restored.documentNumber, customer.documentNumber);
      expect(restored.firstName, customer.firstName);
      expect(restored.lastName, customer.lastName);
      expect(restored.fullName, customer.fullName);
      expect(restored.address, customer.address);
    });

    test('displayName returns fullName when available', () {
      final customer = Customer(
        documentType: 'DNI',
        documentNumber: '12345678',
        fullName: 'Juan Perez',
        firstName: 'Juan',
        lastName: 'Perez',
      );
      expect(customer.displayName, 'Juan Perez');
    });

    test('displayName falls back to firstName + lastName', () {
      final customer = Customer(
        documentType: 'DNI',
        documentNumber: '12345678',
        firstName: 'Juan',
        lastName: 'Perez',
      );
      expect(customer.displayName, 'Juan Perez');
    });

    test('copyWith preserves unchanged fields', () {
      final customer = Customer(
        id: 1,
        documentType: 'DNI',
        documentNumber: '12345678',
        firstName: 'Juan',
        lastName: 'Perez',
      );
      final copy = customer.copyWith(firstName: 'Pedro');
      expect(copy.firstName, 'Pedro');
      expect(copy.lastName, 'Perez');
      expect(copy.documentNumber, '12345678');
    });
  });
}
