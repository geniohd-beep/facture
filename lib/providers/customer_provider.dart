import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../services/reniec_service.dart';
import '../utils/api_result.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ReniecService _reniec = ReniecService();
  List<Customer> _customers = [];
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  String? _lastError;

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await _db.getCustomers();
      _lastError = null;
    } catch (e) {
      _lastError = 'Error al cargar clientes: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String> saveCustomer(Customer customer) async {
    try {
      final existing = await _db.getCustomerByDocument(
          customer.documentType, customer.documentNumber);
      if (existing != null && customer.id == null) {
        await _db.updateCustomer(customer.copyWith(id: existing.id));
      } else if (customer.id != null) {
        await _db.updateCustomer(customer);
      } else {
        await _db.insertCustomer(customer);
      }
      await loadCustomers();
      _lastError = null;
      return 'ok';
    } catch (e) {
      _lastError = 'Error al guardar: $e';
      return _lastError!;
    }
  }

  Future<ApiResult<Customer>> searchByDNI(String dni) async {
    try {
      final existing = await _db.getCustomerByDocument('DNI', dni);
      if (existing != null) return ApiResult.success(existing);
      return await _reniec.consultDNI(dni);
    } catch (e) {
      return ApiResult.failure('Error al consultar DNI: $e');
    }
  }

  Future<ApiResult<Customer>> searchByRUC(String ruc) async {
    try {
      final existing = await _db.getCustomerByDocument('RUC', ruc);
      if (existing != null) return ApiResult.success(existing);
      return await _reniec.consultRUC(ruc);
    } catch (e) {
      return ApiResult.failure('Error al consultar RUC: $e');
    }
  }

  Future<void> searchCustomers(String query) async {
    try {
      _searchResults = await _db.searchCustomers(query);
    } catch (e) {
      _lastError = 'Error al buscar: $e';
    }
    notifyListeners();
  }
}
