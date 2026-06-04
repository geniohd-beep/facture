import 'package:flutter_test/flutter_test.dart';
import 'package:facture/models/document.dart';

void main() {
  group('InvoiceDocument', () {
    test('fromMap and toMap roundtrip', () {
      final doc = InvoiceDocument(
        id: 1,
        companyId: 1,
        customerId: 1,
        documentType: 'Factura Electrónica',
        series: 'F001',
        number: 1,
        customerDocType: 'DNI',
        customerDocNumber: '12345678',
        customerName: 'Juan Perez',
        customerAddress: 'Av. Lima 123',
        subtotal: 100.00,
        igv: 18.00,
        total: 118.00,
        paymentMethod: 'Efectivo',
        status: 'EMITIDO',
      );

      final map = doc.toMap();
      final restored = InvoiceDocument.fromMap(map);

      expect(restored.id, doc.id);
      expect(restored.documentType, doc.documentType);
      expect(restored.documentNumber, 'F001-1');
      expect(restored.subtotal, doc.subtotal);
      expect(restored.igv, doc.igv);
      expect(restored.total, doc.total);
      expect(restored.status, doc.status);
    });

    test('statusLabel returns correct labels', () {
      InvoiceDocument makeDoc(String status) => InvoiceDocument(
        companyId: 1, documentType: 'B', series: 'S', number: 1,
        customerDocType: 'DNI', customerDocNumber: '1', customerName: 'T',
        status: status,
      );

      expect(makeDoc('BORRADOR').statusLabel, 'Borrador');
      expect(makeDoc('EMITIDO').statusLabel, 'Emitido');
      expect(makeDoc('ENVIADO').statusLabel, 'Enviado a SUNAT');
      expect(makeDoc('ACEPTADO').statusLabel, 'Aceptado por SUNAT');
      expect(makeDoc('RECHAZADO').statusLabel, 'Rechazado por SUNAT');
    });

    test('documentNumber format', () {
      final doc = InvoiceDocument(
        companyId: 1,
        documentType: 'Factura Electrónica',
        series: 'F001',
        number: 42,
        customerDocType: 'DNI',
        customerDocNumber: '12345678',
        customerName: 'Test',
      );
      expect(doc.documentNumber, 'F001-42');
    });
  });

  group('DocumentItem', () {
    test('fromMap and toMap roundtrip', () {
      final item = DocumentItem(
        documentId: 1,
        productId: 1,
        productCode: 'P001',
        productName: 'LAPTOP',
        quantity: 2,
        unitPrice: 100.00,
        subtotal: 200.00,
        igv: 36.00,
        total: 236.00,
      );

      final map = item.toMap();
      final restored = DocumentItem.fromMap(map);

      expect(restored.productName, item.productName);
      expect(restored.quantity, item.quantity);
      expect(restored.total, item.total);
    });

    test('copyWith preserves fields', () {
      final item = DocumentItem(
        documentId: 1,
        productId: 1,
        productCode: 'P001',
        productName: 'ORIGINAL',
        quantity: 1,
        unitPrice: 100,
        subtotal: 100,
        igv: 18,
        total: 118,
      );

      final copy = item.copyWith(quantity: 3, total: 354);
      expect(copy.quantity, 3);
      expect(copy.total, 354);
      expect(copy.productName, 'ORIGINAL');
    });
  });
}
