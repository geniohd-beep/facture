import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/document.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/sunat_service.dart';
import '../services/sync_service.dart';
import '../utils/api_result.dart';

class DocumentProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SunatService _sunat = SunatService();
  List<InvoiceDocument> _documents = [];
  final List<DocumentItem> _currentItems = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  bool _isSendingToSunat = false;
  int? _lastCreatedDocId;

  List<InvoiceDocument> get documents => _documents;
  List<DocumentItem> get currentItems => _currentItems;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isSendingToSunat => _isSendingToSunat;
  int? get lastCreatedDocId => _lastCreatedDocId;

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

  void addItem(Product product, double quantity, {String taxRegime = 'GENERAL'}) {
    final subtotal = product.salePrice * quantity;
    final igv = taxRegime == 'RUS' ? 0.0 : subtotal * 0.18;
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

  void updateItemQuantity(int index, double quantity, {String taxRegime = 'GENERAL'}) {
    final item = _currentItems[index];
    final newSubtotal = item.unitPrice * quantity;
    final newIgv = taxRegime == 'RUS' ? 0.0 : newSubtotal * 0.18;
    final newTotal = newSubtotal + newIgv;
    _currentItems[index] = item.copyWith(
      quantity: quantity,
      subtotal: newSubtotal,
      igv: newIgv,
      total: newTotal,
    );
    notifyListeners();
  }

  void clearItems() {
    _currentItems.clear();
    _selectedCustomer = null;
    _lastCreatedDocId = null;
    notifyListeners();
  }

  Future<void> loadItemsForEdit(int documentId) async {
    final items = await _db.getDocumentItems(documentId);
    _currentItems
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _currentItems
        .map((item) => {
              'productId': item.productId,
              'productCode': item.productCode,
              'productName': item.productName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'unitType': item.unitType,
              'subtotal': item.subtotal,
              'igv': item.igv,
              'total': item.total,
            })
        .toList();
    await prefs.setString('cart_items', jsonEncode(itemsJson));
    if (_selectedCustomer != null) {
      await prefs.setString('cart_customer', jsonEncode({
        'id': _selectedCustomer!.id,
        'documentType': _selectedCustomer!.documentType,
        'documentNumber': _selectedCustomer!.documentNumber,
        'firstName': _selectedCustomer!.firstName,
        'lastName': _selectedCustomer!.lastName,
        'fullName': _selectedCustomer!.fullName,
        'address': _selectedCustomer!.address,
        'phone': _selectedCustomer!.phone,
        'email': _selectedCustomer!.email,
      }));
    } else {
      await prefs.remove('cart_customer');
    }
  }

  Future<bool> get hasSavedCart async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('cart_items');
  }

  Future<void> restoreCart() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('cart_items');
    if (itemsJson == null) return;

    final items = (jsonDecode(itemsJson) as List)
        .map((e) => DocumentItem(
              documentId: 0,
              productId: e['productId'],
              productCode: e['productCode'],
              productName: e['productName'],
              quantity: (e['quantity'] as num).toDouble(),
              unitPrice: (e['unitPrice'] as num).toDouble(),
              unitType: e['unitType'] ?? 'UNIDAD',
              subtotal: (e['subtotal'] as num).toDouble(),
              igv: (e['igv'] as num).toDouble(),
              total: (e['total'] as num).toDouble(),
            ))
        .toList();
    _currentItems
      ..clear()
      ..addAll(items);

    final customerJson = prefs.getString('cart_customer');
    if (customerJson != null) {
      final c = jsonDecode(customerJson) as Map<String, dynamic>;
      _selectedCustomer = Customer(
        id: c['id'],
        documentType: c['documentType'],
        documentNumber: c['documentNumber'],
        firstName: c['firstName'] ?? '',
        lastName: c['lastName'] ?? '',
        fullName: c['fullName'] ?? '',
        address: c['address'] ?? '',
        phone: c['phone'] ?? '',
        email: c['email'] ?? '',
      );
    }

    notifyListeners();
  }

  Future<void> clearSavedCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    await prefs.remove('cart_customer');
  }

  double get subtotal =>
      _currentItems.fold(0, (sum, item) => sum + item.subtotal);
  double get igv => _currentItems.fold(0, (sum, item) => sum + item.igv);
  double get total => _currentItems.fold(0, (sum, item) => sum + item.total);

  Future<String?> createDocument({
    required Company company,
    required String documentType,
    required String series,
    required String paymentMethod,
    String? notes,
    String taxRegime = 'GENERAL',
    String paymentStatus = 'TOTAL',
    DateTime? deliveryDate,
    String deliveryAddress = '',
  }) async {
    if (_selectedCustomer == null &&
        documentType != 'Nota de Venta' &&
        documentType != 'Pedido') {
      return 'Seleccione un cliente';
    }

    for (final item in _currentItems) {
      final product = await _db.getProductByCode(item.productCode);
      if (product != null && product.stock < item.quantity) {
        return 'Stock insuficiente para ${item.productName}: disponible ${product.stock}, requerido ${item.quantity.toInt()}';
      }
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
      customerPhone: _selectedCustomer?.phone ?? '',
      customerEmail: _selectedCustomer?.email ?? '',
      subtotal: subtotal,
      igv: taxRegime == 'RUS' ? 0 : igv,
      total: taxRegime == 'RUS' ? subtotal : total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: documentType == 'Pedido' ? 'PEDIDO' : 'EMITIDO',
      notes: notes,
      taxRegime: taxRegime,
      deliveryDate: deliveryDate,
      deliveryAddress: deliveryAddress,
    );

    final docId = await _db.insertDocument(doc);
    _lastCreatedDocId = docId;

    for (final item in _currentItems) {
      await _db.insertDocumentItem(item.copyWith(
        documentId: docId,
      ));
      await _db.updateProductStock(item.productId, -item.quantity.toInt());
      await _db.recordKardexFromSale(
        productId: item.productId,
        productCode: item.productCode,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        documentNumber: doc.documentNumber,
        documentType: documentType,
      );
    }

    await _db.updateDocumentSeries(
        company.id!, documentType, series, number);

    await clearSavedCart();
    clearItems();
    await loadDocuments(companyId: company.id);
    SyncService.instance.sync();
    return null;
  }

  Future<String?> updateDocument({
    required int documentId,
    required Company company,
    required String documentType,
    required String series,
    required String paymentMethod,
    String? notes,
    String taxRegime = 'GENERAL',
    String paymentStatus = 'TOTAL',
    DateTime? deliveryDate,
    String deliveryAddress = '',
  }) async {
    if (_selectedCustomer == null &&
        documentType != 'Nota de Venta' &&
        documentType != 'Pedido') {
      return 'Seleccione un cliente';
    }

    for (final item in _currentItems) {
      final product = await _db.getProductByCode(item.productCode);
      if (product != null && product.stock < item.quantity) {
        return 'Stock insuficiente para ${item.productName}: disponible ${product.stock}, requerido ${item.quantity.toInt()}';
      }
    }

    final existing = await _db.getDocument(documentId);
    if (existing == null) return 'Documento no encontrado';

    final subtotal = _currentItems.fold(0.0, (s, i) => s + i.subtotal);
    final igv = _currentItems.fold(0.0, (s, i) => s + i.igv);
    final total = _currentItems.fold(0.0, (s, i) => s + i.total);

    final doc = existing.copyWith(
      documentType: documentType,
      series: series,
      customerId: _selectedCustomer?.id,
      customerDocType: _selectedCustomer?.documentType ?? existing.customerDocType,
      customerDocNumber: _selectedCustomer?.documentNumber ?? existing.customerDocNumber,
      customerName: _selectedCustomer?.displayName ?? existing.customerName,
      customerAddress: _selectedCustomer?.address ?? existing.customerAddress,
      customerPhone: _selectedCustomer?.phone ?? existing.customerPhone,
      customerEmail: _selectedCustomer?.email ?? existing.customerEmail,
      subtotal: subtotal,
      igv: taxRegime == 'RUS' ? 0 : igv,
      total: taxRegime == 'RUS' ? subtotal : total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      notes: notes,
      taxRegime: taxRegime,
      deliveryDate: deliveryDate,
      deliveryAddress: deliveryAddress,
    );

    await _db.updateDocument(doc);
    await _db.deleteDocumentItems(documentId);
    for (final item in _currentItems) {
      await _db.insertDocumentItem(item.copyWith(documentId: documentId));
    }

    await loadDocuments(companyId: company.id);
    SyncService.instance.sync();
    return null;
  }

  Future<ApiResult<Map<String, dynamic>>> sendToSunat(
      InvoiceDocument document, Company company) async {
    _isSendingToSunat = true;
    notifyListeners();

    try {
      final items = await _db.getDocumentItems(document.id!);
      final result = await _sunat.sendDocument(document, items, company);

      if (result.isSuccess && result.data != null) {
        await _db.updateDocument(document.copyWith(
          status: 'ENVIADO',
          sunatTicket: result.data!['ticket'],
        ));
      }

      return result;
    } catch (e) {
      return ApiResult.failure('Error al enviar a SUNAT: $e');
    } finally {
      _isSendingToSunat = false;
      notifyListeners();
    }
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

  Future<void> markDocumentSent(int docId,
      {required bool whatsapp, required bool email}) async {
    final doc = await _db.getDocument(docId);
    if (doc == null) return;
    await _db.updateDocument(doc.copyWith(
      sentWhatsapp: doc.sentWhatsapp || whatsapp,
      sentEmail: doc.sentEmail || email,
    ));
    SyncService.instance.sync();
  }

  Future<List<InvoiceDocument>> getDocumentsByCustomer({
    required int customerId,
    required int companyId,
  }) async {
    return await _db.getDocuments(customerId: customerId, companyId: companyId);
  }

  Future<Map<String, double>> getSalesSummary(
      int companyId, DateTime from, DateTime to) async {
    return await _db.getSalesSummary(companyId, from, to);
  }

  Future<List<Map<String, dynamic>>> getSalesSummaryByType(
      int companyId, DateTime from, DateTime to) async {
    return await _db.getSalesSummaryByType(companyId, from, to);
  }
}
