import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/customer.dart';
import '../models/api_consultation_stats.dart';
import '../utils/api_result.dart';

class ReniecService {
  String? _apiintiToken;
  String? _jsonpeToken;
  void Function(ApiConsultationStats)? _onRecord;

  void setTokens({String? apiinti, String? jsonpe}) {
    if (apiinti != null) _apiintiToken = apiinti;
    if (jsonpe != null) _jsonpeToken = jsonpe;
  }

  void setOnRecord(void Function(ApiConsultationStats) onRecord) {
    _onRecord = onRecord;
  }

  void _record(String provider, String docType, String docNumber, bool success) {
    _onRecord?.call(ApiConsultationStats(
      provider: provider,
      documentType: docType,
      documentNumber: docNumber,
      success: success,
    ));
  }

  Future<ApiResult<Customer>> consultDNI(String dni) async {
    late ApiResult<Customer> result;

    if (_apiintiToken != null) {
      result = await _tryApiintiDNI(dni);
      _record('API Inti', 'DNI', dni, result.isSuccess);
      if (result.isSuccess) return result;
    }

    if (_jsonpeToken != null) {
      result = await _tryJsonpeDNI(dni);
      _record('json.pe', 'DNI', dni, result.isSuccess);
      if (result.isSuccess) return result;
    }

    result = await _tryGraphperuDNI(dni);
    _record('GraphPeru', 'DNI', dni, result.isSuccess);

    return result;
  }

  Future<ApiResult<Customer>> consultRUC(String ruc) async {
    late ApiResult<Customer> result;

    if (_apiintiToken != null) {
      result = await _tryApiintiRUC(ruc);
      _record('API Inti', 'RUC', ruc, result.isSuccess);
      if (result.isSuccess) return result;
    }

    if (_jsonpeToken != null) {
      result = await _tryJsonpeRUC(ruc);
      _record('json.pe', 'RUC', ruc, result.isSuccess);
      if (result.isSuccess) return result;
    }

    result = await _tryGraphperuRUC(ruc);
    _record('GraphPeru', 'RUC', ruc, result.isSuccess);

    return result;
  }

  Future<ApiResult<Customer>> _tryApiintiDNI(String dni) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiintiBaseUrl}/dni/$dni'),
        headers: {
          'Authorization': 'Bearer $_apiintiToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('API Inti: ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      final raw = body['data'];
      final data = (raw is Map<String, dynamic>) ? raw : body;
      return ApiResult.success(Customer(
        documentType: 'DNI',
        documentNumber: dni,
        firstName: data['nombres'] ?? '',
        lastName:
            '${data['apellidoPaterno'] ?? ''} ${data['apellidoMaterno'] ?? ''}'
                .trim(),
        fullName:
            '${data['nombres'] ?? ''} ${data['apellidoPaterno'] ?? ''} ${data['apellidoMaterno'] ?? ''}'
                .trim(),
        address: data['direccion'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('API Inti: $e');
    }
  }

  Future<ApiResult<Customer>> _tryApiintiRUC(String ruc) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiintiBaseUrl}/ruc/$ruc'),
        headers: {
          'Authorization': 'Bearer $_apiintiToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('API Inti: ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      final raw = body['data'];
      final data = (raw is Map<String, dynamic>) ? raw : body;
      return ApiResult.success(Customer(
        documentType: 'RUC',
        documentNumber: ruc,
        fullName: data['razonSocial'] ?? '',
        address: data['direccion'] ?? '',
        firstName: data['nombreComercial'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('API Inti: $e');
    }
  }

  Future<ApiResult<Customer>> _tryJsonpeDNI(String dni) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.jsonpeBaseUrl}/dni'),
        headers: {
          'Authorization': 'Bearer $_jsonpeToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'dni': dni}),
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('json.pe: ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        return ApiResult.failure(body['message'] ?? 'json.pe: error');
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ApiResult.success(Customer(
        documentType: 'DNI',
        documentNumber: dni,
        firstName: data['nombres'] ?? '',
        lastName:
            '${data['apellido_paterno'] ?? ''} ${data['apellido_materno'] ?? ''}'
                .trim(),
        fullName: data['nombre_completo'] ?? '',
        address: data['direccion'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('json.pe: $e');
    }
  }

  Future<ApiResult<Customer>> _tryJsonpeRUC(String ruc) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.jsonpeBaseUrl}/ruc'),
        headers: {
          'Authorization': 'Bearer $_jsonpeToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ruc': ruc}),
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('json.pe: ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        return ApiResult.failure(body['message'] ?? 'json.pe: error');
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ApiResult.success(Customer(
        documentType: 'RUC',
        documentNumber: ruc,
        fullName: data['nombre_o_razon_social'] ?? '',
        address: data['direccion'] ?? '',
        firstName: data['nombre_comercial'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('json.pe: $e');
    }
  }

  Future<ApiResult<Customer>> _tryGraphperuDNI(String dni) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.graphperuBaseUrl}/query/$dni'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('GraphPeru: ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      return ApiResult.success(Customer(
        documentType: 'DNI',
        documentNumber: dni,
        firstName: data['nombres'] ?? data['name'] ?? '',
        lastName: data['surnames'] ?? data['apellidos'] ?? '',
        fullName: data['fullName'] ??
            data['nombre_completo'] ??
            '${data['nombres'] ?? ''} ${data['surnames'] ?? ''}'.trim(),
        address: data['direccion'] ?? data['address'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('GraphPeru: $e');
    }
  }

  Future<ApiResult<Customer>> _tryGraphperuRUC(String ruc) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.graphperuBaseUrl}/query/$ruc'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        return ApiResult.failure('GraphPeru: ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      return ApiResult.success(Customer(
        documentType: 'RUC',
        documentNumber: ruc,
        fullName: data['name'] ?? data['razonSocial'] ?? '',
        address: data['address'] ?? data['direccion'] ?? '',
      ));
    } catch (e) {
      return ApiResult.failure('GraphPeru: $e');
    }
  }
}
