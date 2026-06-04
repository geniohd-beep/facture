import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/constants.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/document.dart';
import '../models/user.dart';

class DatabaseService {
  static Database? _database;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruc TEXT NOT NULL,
        business_name TEXT NOT NULL,
        trade_name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT DEFAULT '',
        email TEXT DEFAULT '',
        logo_path TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_type TEXT NOT NULL,
        document_number TEXT NOT NULL,
        first_name TEXT DEFAULT '',
        last_name TEXT DEFAULT '',
        full_name TEXT DEFAULT '',
        address TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        email TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        category TEXT DEFAULT '',
        purchase_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        stock INTEGER DEFAULT 0,
        unit_type TEXT DEFAULT 'UNIDAD',
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        customer_id INTEGER,
        document_type TEXT NOT NULL,
        series TEXT NOT NULL,
        number INTEGER NOT NULL,
        customer_doc_type TEXT NOT NULL,
        customer_doc_number TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_address TEXT DEFAULT '',
        issue_date TEXT NOT NULL,
        subtotal REAL DEFAULT 0,
        igv REAL DEFAULT 0,
        total REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'Efectivo',
        status TEXT DEFAULT 'EMITIDO',
        sunat_ticket TEXT,
        sunat_cdr TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE document_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_type TEXT DEFAULT 'UNIDAD',
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        igv REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT DEFAULT 'VENDEDOR',
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.insert('users', {
      'username': 'admin',
      'password': _hashPassword('admin'),
      'full_name': 'Administrador',
      'role': 'ADMIN',
      'is_active': 1,
    });

    await db.execute('''
      CREATE TABLE document_series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        document_type TEXT NOT NULL,
        series TEXT NOT NULL,
        current_number INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_customers_doc ON customers(document_type, document_number)');
    await db.execute(
        'CREATE INDEX idx_documents_date ON documents(issue_date)');
    await db.execute(
        'CREATE INDEX idx_documents_company ON documents(company_id)');
  }

  Future<int> insertCompany(Company company) async {
    final db = await database;
    return await db.insert('companies', company.toMap());
  }

  Future<int> updateCompany(Company company) async {
    final db = await database;
    return await db.update(
      'companies',
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<Company?> getCompany(int id) async {
    final db = await database;
    final maps = await db.query('companies', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Company.fromMap(maps.first);
  }

  Future<List<Company>> getCompanies() async {
    final db = await database;
    final maps = await db.query('companies', orderBy: 'business_name ASC');
    return maps.map((m) => Company.fromMap(m)).toList();
  }

  Future<Company?> getActiveCompany() async {
    final db = await database;
    final maps =
        await db.query('companies', where: 'is_active = 1', limit: 1);
    if (maps.isEmpty) return null;
    return Company.fromMap(maps.first);
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<Customer?> getCustomerByDocument(
      String docType, String docNumber) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'document_type = ? AND document_number = ?',
      whereArgs: [docType, docNumber],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where:
          'full_name LIKE ? OR document_number LIKE ? OR first_name LIKE ? OR last_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'full_name ASC',
      limit: 20,
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'full_name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: '(name LIKE ? OR code LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 20,
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps =
        await db.query('products', where: 'is_active = 1', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductByCode(String code) async {
    final db = await database;
    final maps =
        await db.query('products', where: 'code = ?', whereArgs: [code]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Map<String, int>> getDocumentSeries(
      int companyId, String docType) async {
    final db = await database;
    final maps = await db.query(
      'document_series',
      where: 'company_id = ? AND document_type = ?',
      whereArgs: [companyId, docType],
    );
    if (maps.isEmpty) return <String, int>{};
    final map = maps.first;
    return <String, int>{map['series'] as String: map['current_number'] as int};
  }

  Future<void> updateDocumentSeries(
      int companyId, String docType, String series, int number) async {
    final db = await database;
    final existing = await db.query(
      'document_series',
      where: 'company_id = ? AND document_type = ? AND series = ?',
      whereArgs: [companyId, docType, series],
    );
    if (existing.isEmpty) {
      await db.insert('document_series', {
        'company_id': companyId,
        'document_type': docType,
        'series': series,
        'current_number': number,
        'is_active': 1,
      });
    } else {
      await db.update(
        'document_series',
        {'current_number': number},
        where: 'company_id = ? AND document_type = ? AND series = ?',
        whereArgs: [companyId, docType, series],
      );
    }
  }

  Future<int> insertDocument(InvoiceDocument doc) async {
    final db = await database;
    return await db.insert('documents', doc.toMap());
  }

  Future<int> updateDocument(InvoiceDocument doc) async {
    final db = await database;
    return await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> insertDocumentItem(DocumentItem item) async {
    final db = await database;
    return await db.insert('document_items', item.toMap());
  }

  Future<List<DocumentItem>> getDocumentItems(int documentId) async {
    final db = await database;
    final maps = await db.query(
      'document_items',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
    return maps.map((m) => DocumentItem.fromMap(m)).toList();
  }

  Future<List<InvoiceDocument>> getDocuments({
    String? docType,
    String? status,
    DateTime? from,
    DateTime? to,
    int? companyId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (docType != null) {
      conditions.add('document_type = ?');
      args.add(docType);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (from != null) {
      conditions.add('issue_date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('issue_date <= ?');
      args.add(to.toIso8601String());
    }
    if (companyId != null) {
      conditions.add('company_id = ?');
      args.add(companyId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final maps = await db.query(
      'documents',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'issue_date DESC, number DESC',
    );
    return maps.map((m) => InvoiceDocument.fromMap(m)).toList();
  }

  Future<InvoiceDocument?> getDocument(int id) async {
    final db = await database;
    final maps = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return InvoiceDocument.fromMap(maps.first);
  }

  Future<int> getNextNumber(int companyId, String docType, String series) async {
    final db = await database;
    final map = await db.rawQuery(
      'SELECT MAX(number) as max_num FROM documents WHERE company_id = ? AND document_type = ? AND series = ?',
      [companyId, docType, series],
    );
    final maxNum = map.first['max_num'];
    if (maxNum == null) return 1;
    return (maxNum as int) + 1;
  }

  Future<Map<String, double>> getSalesSummary(
      int companyId, DateTime from, DateTime to) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_docs,
        COALESCE(SUM(total), 0) as total_sales,
        COALESCE(SUM(CASE WHEN document_type = 'Factura Electrónica' THEN total ELSE 0 END), 0) as total_facturas,
        COALESCE(SUM(CASE WHEN document_type = 'Boleta Electrónica' THEN total ELSE 0 END), 0) as total_boletas
      FROM documents 
      WHERE company_id = ? 
        AND issue_date >= ? 
        AND issue_date <= ?
        AND status NOT IN ('BORRADOR', 'RECHAZADO')
    ''', [companyId, from.toIso8601String(), to.toIso8601String()]);

    final row = result.first;
    final totalDocs = (row['total_docs'] as num?)?.toDouble() ?? 0;
    final totalSales = (row['total_sales'] as num?)?.toDouble() ?? 0;
    final totalFacturas = (row['total_facturas'] as num?)?.toDouble() ?? 0;
    final totalBoletas = (row['total_boletas'] as num?)?.toDouble() ?? 0;
    return {
      'total_docs': totalDocs,
      'total_sales': totalSales,
      'total_facturas': totalFacturas,
      'total_boletas': totalBoletas,
    };
  }

  Future<int> insertUser(AppUser user, String password) async {
    final db = await database;
    return await db.insert('users', {
      ...user.toMap(),
      'password': _hashPassword(password),
    });
  }

  Future<AppUser?> authenticateUser(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, _hashPassword(password)],
    );
    if (maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
