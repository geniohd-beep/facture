import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/document.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/sunat_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SunatService _sunat = SunatService();
  List<InvoiceDocument> _documents = [];
  final List<DocumentItem> _currentItems = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  bool _isSendingToSunat = false;

  List<InvoiceDocument> get documents => _documents;
  List<DocumentItem> get currentItems => _currentItems;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isSendingToSunat => _isSendingToSunat;

  Future<void> loadDocuments({
    String? docType,
    String? status,
    DateTime? from,
    DateTime? to,
    int? companyId,
  }) async {
    _isLoading = true;
    notifyListeners();
    _documents = await _db.getDocuments(
      docType: docType,
      status: status,
      from: from,
      to: to,
      companyId: companyId,
    );
    _isLoading = false;
    notifyListeners();
  }

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addItem(Product product, double quantity) {
    final subtotal = product.salePrice * quantity;
    final igv = subtotal * 0.18;
    final total = subtotal + igv;

    _currentItems.add(DocumentItem(
      documentId: 0,
      productId: product.id!,
      productCode: product.code,
      productName: product.name,
      quantity: quantity,
      unitType: product.unitType,
      unitPrice: product.salePrice,
      subtotal: subtotal,
      igv: igv,
      total: total,
    ));
    notifyListeners();
  }

  void removeItem(int index) {
    _currentItems.removeAt(index);
    notifyListeners();
  }

  void clearItems() {
    _currentItems.clear();
    _selectedCustomer = null;
    notifyListeners();
  }

  double get subtotal =>
      _currentItems.fold(0, (sum, item) => sum + item.subtotal);
  double get igv => _currentItems.fold(0, (sum, item) => sum + item.igv);
  double get total => _currentItems.fold(0, (sum, item) => sum + item.total);

  Future<InvoiceDocument?> createDocument({
    required Company company,
    required String documentType,
    required String series,
    required String paymentMethod,
    String? notes,
  }) async {
    if (_selectedCustomer == null && documentType != 'Nota de Venta') {
      return null;
    }

    final number =
        await _db.getNextNumber(company.id!, documentType, series);

    final doc = InvoiceDocument(
      companyId: company.id!,
      customerId: _selectedCustomer?.id,
      documentType: documentType,
      series: series,
      number: number,
      customerDocType: _selectedCustomer?.documentType ?? 'DNI',
      customerDocNumber: _selectedCustomer?.documentNumber ?? '00000000',
      customerName: _selectedCustomer?.displayName ?? 'CLIENTE VARIOS',
      customerAddress: _selectedCustomer?.address ?? '',
      subtotal: subtotal,
      igv: igv,
      total: total,
      paymentMethod: paymentMethod,
      status: 'EMITIDO',
      notes: notes,
    );

    final docId = await _db.insertDocument(doc);

    for (final item in _currentItems) {
      await _db.insertDocumentItem(item.copyWith(
        documentId: docId,
      ));
    }

    await _db.updateDocumentSeries(
        company.id!, documentType, series, number);

    clearItems();
    await loadDocuments(companyId: company.id);
    return doc.copyWith(id: docId);
  }

  Future<Map<String, dynamic>> sendToSunat(
      InvoiceDocument document, Company company) async {
    _isSendingToSunat = true;
    notifyListeners();

    final items = await _db.getDocumentItems(document.id!);
    final result = await _sunat.sendDocument(document, items, company);

    if (result['success']) {
      await _db.updateDocument(document.copyWith(
        status: 'ENVIADO',
        sunatTicket: result['ticket'],
      ));
    }

    _isSendingToSunat = false;
    notifyListeners();
    return result;
  }

  Future<void> printDocument(InvoiceDocument document, Company company) async {
    final items = await _db.getDocumentItems(document.id!);
    await _sunat.generateAndPrintDocument(document, items, company);
  }

  Future<InvoiceDocument?> getDocumentById(int id) async {
    return await _db.getDocument(id);
  }

  Future<List<DocumentItem>> getDocumentItems(int docId) async {
    return await _db.getDocumentItems(docId);
  }

  Future<Map<String, double>> getSalesSummary(
      int companyId, DateTime from, DateTime to) async {
    return await _db.getSalesSummary(companyId, from, to);
  }
}
