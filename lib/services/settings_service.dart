import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySunatToken = 'sunat_api_token';
  static const _keyReniecToken = 'reniec_api_token';

  Future<String?> getSunatToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySunatToken);
  }

  Future<void> setSunatToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySunatToken, token);
  }

  Future<String?> getReniecToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReniecToken);
  }

  Future<void> setReniecToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReniecToken, token);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySunatToken);
    await prefs.remove(_keyReniecToken);
  }
}
