import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class CompanyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Company? _currentCompany;
  List<Company> _companies = [];
  bool _isLoading = false;

  Company? get currentCompany => _currentCompany;
  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  bool get hasCompany => _currentCompany != null;

  Future<void> loadCompanies() async {
    _isLoading = true;
    notifyListeners();
    _companies = await _db.getCompanies();
    _currentCompany = await _db.getActiveCompany();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> saveCompany(Company company) async {
    try {
      if (company.id != null) {
        await _db.updateCompany(company);
      } else {
        await _db.insertCompany(company);
      }
      await loadCompanies();
      SyncService.instance.sync();
      return 'ok';
    } catch (e) {
      return 'Error al guardar: $e';
    }
  }

  Future<void> selectCompany(Company company) async {
    _currentCompany = company;
    notifyListeners();
  }
}
