class AppConstants {
  static const String appName = 'Facture';
  static const String appVersion = '1.0.0';
  static const String dbName = 'facture.db';
  static const int dbVersion = 1;

  static const String reniecApiUrl = 'https://api.reniec.com/v1';
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
