import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'facture.db');
  print('Database path: $path');

  final exists = await databaseExists(path);
  if (!exists) {
    print('Database not found. Run the app first.');
    return;
  }

  final db = await openDatabase(path);

  final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'));
  print('\nTotal productos: $count');

  final products = await db.query('products', orderBy: 'name ASC');
  print('\n${products.length} productos encontrados:');
  print('=' * 100);
  print('${'ID'.padRight(5)} ${'CÓDIGO'.padRight(15)} ${'NOMBRE'.padRight(35)} ${'STOCK'.padRight(8)} ${'P. VENTA'.padRight(12)} ${'CATEGORÍA'}');
  print('=' * 100);
  for (final p in products) {
    final id = p['id'];
    final code = (p['code'] as String?) ?? '';
    final name = (p['name'] as String?) ?? '';
    final stock = p['stock'] ?? 0;
    final price = (p['sale_price'] ?? 0).toDouble();
    final cat = (p['category'] as String?) ?? '';
    print('${'$id'.padRight(5)} ${code.padRight(15)} ${name.padRight(35)} ${'$stock'.padRight(8)} ${price.toStringAsFixed(2).padLeft(10)}   ${cat}');
  }

  await db.close();
}
