import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
