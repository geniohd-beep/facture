import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/customer.dart';
import '../utils/api_result.dart';

class ReniecService {
  String? _apiToken;

  void setToken(String token) {
    _apiToken = token;
  }

  bool get isConfigured => _apiToken != null;

  Future<ApiResult<Customer>> consultDNI(String dni) async {
    if (_apiToken == null) {
      return ApiResult.failure('API de RENIEC no configurada');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.reniecApiUrl}/dni/$dni'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success(Customer(
          documentType: 'DNI',
          documentNumber: dni,
          firstName: data['nombres'] ?? '',
          lastName: '${data['apellidoPaterno'] ?? ''} ${data['apellidoMaterno'] ?? ''}'.trim(),
          fullName: '${data['nombres'] ?? ''} ${data['apellidoPaterno'] ?? ''} ${data['apellidoMaterno'] ?? ''}'.trim(),
          address: data['direccion'] ?? '',
        ));
      }

      if (response.statusCode == 404) {
        return ApiResult.failure('DNI no encontrado en RENIEC');
      }

      return ApiResult.failure('Error al consultar RENIEC: ${response.statusCode}');
    } catch (e) {
      return ApiResult.failure('Error de conexión con RENIEC: $e');
    }
  }

  Future<ApiResult<Customer>> consultRUC(String ruc) async {
    if (_apiToken == null) {
      return ApiResult.failure('API de SUNAT no configurada');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.sunatApiUrl}/ruc/$ruc'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success(Customer(
          documentType: 'RUC',
          documentNumber: ruc,
          fullName: data['razonSocial'] ?? '',
          address: data['direccion'] ?? '',
          firstName: data['nombreComercial'] ?? '',
        ));
      }

      if (response.statusCode == 404) {
        return ApiResult.failure('RUC no encontrado en SUNAT');
      }

      return ApiResult.failure('Error al consultar SUNAT: ${response.statusCode}');
    } catch (e) {
      return ApiResult.failure('Error de conexión con SUNAT: $e');
    }
  }
}
