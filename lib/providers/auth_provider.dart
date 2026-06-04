import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<String> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _db.authenticateUser(username, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return 'ok';
      }
      _isLoading = false;
      notifyListeners();
      return 'Usuario o contraseña incorrectos';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error de conexión: $e';
    }
  }

  Future<String> register(String username, String password, String fullName,
      {String role = 'VENDEDOR'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = AppUser(
        username: username,
        fullName: fullName,
        role: role,
      );
      await _db.insertUser(user, password);
      _isLoading = false;
      notifyListeners();
      return 'ok';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error al registrar: $e';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
