class AppConstants {
  static const String appName = 'Facture';
  static const String appVersion = '1.0.0';
  static const String dbName = 'facture.db';
  static const int dbVersion = 4;

  static const String apiintiBaseUrl = 'https://api.apiinti.dev/api/v1';
  static const String jsonpeBaseUrl = 'https://api.json.pe/api';
  static const String graphperuBaseUrl = 'https://graphperu.daustinn.com/api';
  static const String sunatApiUrl = 'https://api.sunat.com/v1';

  static const List<String> documentTypes = [
    'Boleta Electrónica',
    'Factura Electrónica',
    'Nota de Venta',
    'Nota de Crédito',
    'Nota de Débito',
    'Guía de Remisión',
  ];

  static const List<String> paymentMethods = [
    'Efectivo',
    'Tarjeta Débito',
    'Tarjeta Crédito',
    'Yape',
    'Plin',
    'Transferencia',
    'Contraentrega',
  ];

  static const List<String> taxRates = [
    'IGV 18%',
    'Exonerado',
    'Inafecto',
  ];
}
