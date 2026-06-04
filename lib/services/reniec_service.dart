import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/customer.dart';

class ReniecService {
  String? _apiToken;

  void setToken(String token) {
    _apiToken = token;
  }

  Future<Customer?> consultDNI(String dni) async {
    if (_apiToken == null) return null;

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
        return Customer(
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
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Customer?> consultRUC(String ruc) async {
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
        return Customer(
          documentType: 'RUC',
          documentNumber: ruc,
          fullName: data['razonSocial'] ?? '',
          address: data['direccion'] ?? '',
          firstName: data['nombreComercial'] ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
