import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../services/reniec_service.dart';
import '../services/settings_service.dart';
import '../utils/api_result.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ReniecService _reniec = ReniecService();
  final SettingsService _settings = SettingsService();
  List<Customer> _customers = [];
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  String? _lastError;

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  CustomerProvider() {
    _reniec.setOnRecord((stats) {
      _db.insertConsultationStats(stats);
    });
  }

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

      final apiinti = await _settings.getApiintiToken();
      final jsonpe = await _settings.getJsonpeToken();
      _reniec.setTokens(apiinti: apiinti, jsonpe: jsonpe);

      final result = await _reniec.consultDNI(dni);
      if (result.isSuccess && result.data != null) {
        final apiCustomer = result.data!.copyWith(fromApi: true);
        final saved = await _db.insertCustomer(apiCustomer);
        final savedCustomer = apiCustomer.copyWith(id: saved);
        await loadCustomers();
        return ApiResult.success(savedCustomer);
      }
      return result;
    } catch (e) {
      return ApiResult.failure('Error al consultar DNI: $e');
    }
  }

  Future<ApiResult<Customer>> searchByRUC(String ruc) async {
    try {
      final existing = await _db.getCustomerByDocument('RUC', ruc);
      if (existing != null) return ApiResult.success(existing);

      final apiinti = await _settings.getApiintiToken();
      final jsonpe = await _settings.getJsonpeToken();
      _reniec.setTokens(apiinti: apiinti, jsonpe: jsonpe);

      final result = await _reniec.consultRUC(ruc);
      if (result.isSuccess && result.data != null) {
        final apiCustomer = result.data!.copyWith(fromApi: true);
        final saved = await _db.insertCustomer(apiCustomer);
        final savedCustomer = apiCustomer.copyWith(id: saved);
        await loadCustomers();
        return ApiResult.success(savedCustomer);
      }
      return result;
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
