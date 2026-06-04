import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySunatToken = 'sunat_api_token';
  static const _keyApiintiToken = 'apiinti_token';
  static const _keyJsonpeToken = 'jsonpe_token';

  Future<String?> getSunatToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySunatToken);
  }

  Future<void> setSunatToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySunatToken, token);
  }

  Future<String?> getApiintiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiintiToken);
  }

  Future<void> setApiintiToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiintiToken, token);
  }

  Future<String?> getJsonpeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJsonpeToken);
  }

  Future<void> setJsonpeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJsonpeToken, token);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySunatToken);
    await prefs.remove(_keyApiintiToken);
    await prefs.remove(_keyJsonpeToken);
  }
}
