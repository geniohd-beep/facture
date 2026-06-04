# Facture

Sistema de facturación electrónica para SUNAT Perú.

## Características

- Gestión de empresas (RUC, razón social)
- Registro de clientes con consulta RENIEC/SUNAT
- Catálogo de productos con control de stock
- Emisión de facturas, boletas y notas de venta
- Envío a SUNAT (API externa)
- Generación de PDF para impresión
- Reportes de ventas por período
- Autenticación de usuarios
- Modo oscuro

## Stack

- **Framework**: Flutter
- **Lenguaje**: Dart
- **State Management**: Provider
- **Base de datos**: SQLite (sqflite)
- **PDF**: pdf + printing

## Instalación

```bash
flutter pub get
flutter run
```

Usuario por defecto: `admin` / `admin`
