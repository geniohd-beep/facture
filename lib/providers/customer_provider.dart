import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../services/reniec_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ReniecService _reniec = ReniecService();
  List<Customer> _customers = [];
  List<Customer> _searchResults = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _customers = await _db.getCustomers();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> saveCustomer(Customer customer) async {
    try {
      final existing = await _db.getCustomerByDocument(
          customer.documentType, customer.documentNumber);
      if (existing != null) {
        await _db.updateCustomer(customer.copyWith(id: existing.id));
      } else {
        await _db.insertCustomer(customer);
      }
      await loadCustomers();
      return 'ok';
    } catch (e) {
      return 'Error al guardar: $e';
    }
  }

  Future<Customer?> searchByDNI(String dni) async {
    final existing = await _db.getCustomerByDocument('DNI', dni);
    if (existing != null) return existing;

    return await _reniec.consultDNI(dni);
  }

  Future<Customer?> searchByRUC(String ruc) async {
    final existing = await _db.getCustomerByDocument('RUC', ruc);
    if (existing != null) return existing;

    return await _reniec.consultRUC(ruc);
  }

  Future<void> searchCustomers(String query) async {
    _searchResults = await _db.searchCustomers(query);
    notifyListeners();
  }
}
