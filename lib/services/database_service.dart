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
import '../models/api_consultation_stats.dart';
import '../models/kardex_entry.dart';

String _nowUtcIso() => DateTime.now().toUtc().toIso8601String();

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
      onUpgrade: _onUpgrade,
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
        is_active INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL
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
        from_api INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        is_active INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL
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
        customer_phone TEXT DEFAULT '',
        customer_email TEXT DEFAULT '',
        sent_whatsapp INTEGER DEFAULT 0,
        sent_email INTEGER DEFAULT 0,
        issue_date TEXT NOT NULL,
        subtotal REAL DEFAULT 0,
        igv REAL DEFAULT 0,
        total REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'Efectivo',
        payment_status TEXT DEFAULT 'TOTAL',
        status TEXT DEFAULT 'EMITIDO',
        sunat_ticket TEXT,
        sunat_cdr TEXT,
        notes TEXT,
        tax_regime TEXT DEFAULT 'GENERAL',
        delivery_date TEXT,
        delivery_address TEXT DEFAULT '',
        updated_at TEXT NOT NULL
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
    await db.execute('''
      CREATE TABLE kardex (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        date TEXT NOT NULL,
        document_type TEXT NOT NULL,
        document_number TEXT,
        reference TEXT DEFAULT '',
        quantity_in REAL DEFAULT 0,
        quantity_out REAL DEFAULT 0,
        stock_balance INTEGER DEFAULT 0,
        unit_price REAL DEFAULT 0,
        total_value REAL DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_kardex_product ON kardex(product_id, date)');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER,
        operation TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_documents_date ON documents(issue_date)');
    await db.execute(
        'CREATE INDEX idx_documents_company ON documents(company_id)');
    await db.execute(
        'CREATE INDEX idx_sync_queue_pending ON sync_queue(synced, created_at)');
 
    await db.execute('''
      CREATE TABLE api_consultation_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT NOT NULL,
        document_type TEXT NOT NULL,
        document_number TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE documents ADD COLUMN tax_regime TEXT DEFAULT 'GENERAL'");
      await db.execute("ALTER TABLE documents ADD COLUMN delivery_date TEXT");
      await db.execute(
          "ALTER TABLE documents ADD COLUMN delivery_address TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE documents ADD COLUMN payment_status TEXT DEFAULT 'TOTAL'");
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE api_consultation_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          provider TEXT NOT NULL,
          document_type TEXT NOT NULL,
          document_number TEXT NOT NULL,
          success INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute("ALTER TABLE documents ADD COLUMN customer_phone TEXT DEFAULT ''");
        await db.execute("ALTER TABLE documents ADD COLUMN customer_email TEXT DEFAULT ''");
        await db.execute("ALTER TABLE documents ADD COLUMN sent_whatsapp INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE documents ADD COLUMN sent_email INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE customers ADD COLUMN from_api INTEGER DEFAULT 0");
      } catch (_) {}
    }
    if (oldVersion < 5) {
      for (final table in ['companies', 'customers', 'products', 'documents']) {
        try {
          await db.execute(
              "ALTER TABLE $table ADD COLUMN updated_at TEXT DEFAULT ''");
        } catch (_) {}
      }
      try {
        await db.execute("ALTER TABLE document_items ADD COLUMN updated_at TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE document_series ADD COLUMN updated_at TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN updated_at TEXT DEFAULT ''");
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id INTEGER,
          operation TEXT NOT NULL,
          data TEXT,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending ON sync_queue(synced, created_at)');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS kardex (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          date TEXT NOT NULL,
          document_type TEXT NOT NULL,
          document_number TEXT,
          reference TEXT DEFAULT '',
          quantity_in REAL DEFAULT 0,
          quantity_out REAL DEFAULT 0,
          stock_balance INTEGER DEFAULT 0,
          unit_price REAL DEFAULT 0,
          total_value REAL DEFAULT 0
        )
      ''');
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_kardex_product ON kardex(product_id, date)');
      } catch (_) {}
    }
  }

  Future<int> insertCompany(Company company) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = company.toMap();
    map['updated_at'] = now;
    final id = await db.insert('companies', map);
    await addToSyncQueue(
      tableName: 'companies',
      recordId: id,
      operation: 'INSERT',
      data: {...map, 'id': id},
    );
    return id;
  }

  Future<int> updateCompany(Company company) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = company.toMap();
    map['updated_at'] = now;
    final result = await db.update(
      'companies',
      map,
      where: 'id = ?',
      whereArgs: [company.id],
    );
    await addToSyncQueue(
      tableName: 'companies',
      recordId: company.id,
      operation: 'UPDATE',
      data: map,
    );
    return result;
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
    final now = _nowUtcIso();
    final map = customer.toMap();
    map['updated_at'] = now;
    final id = await db.insert('customers', map);
    await addToSyncQueue(
      tableName: 'customers',
      recordId: id,
      operation: 'INSERT',
      data: {...map, 'id': id},
    );
    return id;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = customer.toMap();
    map['updated_at'] = now;
    final result = await db.update(
      'customers',
      map,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    await addToSyncQueue(
      tableName: 'customers',
      recordId: customer.id,
      operation: 'UPDATE',
      data: map,
    );
    return result;
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
    final now = _nowUtcIso();
    final map = product.toMap();
    map['updated_at'] = now;
    final id = await db.insert('products', map);
    await addToSyncQueue(
      tableName: 'products',
      recordId: id,
      operation: 'INSERT',
      data: {...map, 'id': id},
    );
    return id;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = product.toMap();
    map['updated_at'] = now;
    final result = await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await addToSyncQueue(
      tableName: 'products',
      recordId: product.id,
      operation: 'UPDATE',
      data: map,
    );
    return result;
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

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> insertProductIfNotExists(Product product) async {
    final existing = await getProductByCode(product.code);
    if (existing == null) {
      await insertProduct(product);
    }
  }

  Future<void> updateProductStock(int productId, int delta) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock + ?) WHERE id = ?',
      [delta, productId],
    );
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
    final now = _nowUtcIso();
    final map = doc.toMap();
    map['updated_at'] = now;
    final id = await db.insert('documents', map);
    await addToSyncQueue(
      tableName: 'documents',
      recordId: id,
      operation: 'INSERT',
      data: {...map, 'id': id},
    );
    return id;
  }

  Future<int> updateDocument(InvoiceDocument doc) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = doc.toMap();
    map['updated_at'] = now;
    final result = await db.update(
      'documents',
      map,
      where: 'id = ?',
      whereArgs: [doc.id],
    );
    await addToSyncQueue(
      tableName: 'documents',
      recordId: doc.id,
      operation: 'UPDATE',
      data: map,
    );
    return result;
  }

  Future<int> insertDocumentItem(DocumentItem item) async {
    final db = await database;
    final now = _nowUtcIso();
    final map = item.toMap();
    map['updated_at'] = now;
    final id = await db.insert('document_items', map);
    await addToSyncQueue(
      tableName: 'document_items',
      recordId: id,
      operation: 'INSERT',
      data: {...map, 'id': id},
    );
    return id;
  }

  Future<void> upsertCustomer(Map<String, dynamic> data) async {
    final db = await database;
    final now = _nowUtcIso();
    data['updated_at'] = now;
    final existing = await db.query(
      'customers',
      where: 'document_type = ? AND document_number = ?',
      whereArgs: [data['document_type'], data['document_number']],
    );
    if (existing.isNotEmpty) {
      await db.update('customers', data,
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('customers', data);
    }
  }

  Future<void> upsertProduct(Map<String, dynamic> data) async {
    final db = await database;
    final now = _nowUtcIso();
    data['updated_at'] = now;
    final existing =
        await db.query('products', where: 'code = ?', whereArgs: [data['code']]);
    if (existing.isNotEmpty) {
      data['id'] = existing.first['id'];
      await db.update('products', data,
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      data.remove('id');
      await db.insert('products', data);
    }
  }

  Future<void> upsertCompany(Map<String, dynamic> data) async {
    final db = await database;
    final now = _nowUtcIso();
    data['updated_at'] = now;
    final existing =
        await db.query('companies', where: 'ruc = ?', whereArgs: [data['ruc']]);
    if (existing.isNotEmpty) {
      data['id'] = existing.first['id'];
      await db.update('companies', data,
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      data.remove('id');
      await db.insert('companies', data);
    }
  }

  Future<int> upsertDocument(Map<String, dynamic> data) async {
    final db = await database;
    final now = _nowUtcIso();
    data['updated_at'] = now;
    final existing = await db.query(
      'documents',
      where: 'company_id = ? AND document_type = ? AND series = ? AND number = ?',
      whereArgs: [
        data['company_id'],
        data['document_type'],
        data['series'],
        data['number']
      ],
    );
    if (existing.isNotEmpty) {
      data['id'] = existing.first['id'];
      await db.update('documents', data,
          where: 'id = ?', whereArgs: [existing.first['id']]);
      return existing.first['id'] as int;
    } else {
      data.remove('id');
      return await db.insert('documents', data);
    }
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

  Future<void> deleteDocumentItems(int documentId) async {
    final db = await database;
    await db.delete('document_items',
        where: 'document_id = ?', whereArgs: [documentId]);
  }

  Future<List<InvoiceDocument>> getDocuments({
    String? docType,
    String? status,
    DateTime? from,
    DateTime? to,
    int? companyId,
    int? customerId,
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
    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
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

  Future<List<Map<String, dynamic>>> getSalesSummaryByType(
      int companyId, DateTime from, DateTime to) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        document_type,
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as total
      FROM documents 
      WHERE company_id = ? 
        AND issue_date >= ? 
        AND issue_date <= ?
        AND status NOT IN ('BORRADOR', 'RECHAZADO')
      GROUP BY document_type
      ORDER BY total DESC
    ''', [companyId, from.toIso8601String(), to.toIso8601String()]);
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

  Future<void> insertConsultationStats(ApiConsultationStats stats) async {
    final db = await database;
    await db.insert('api_consultation_stats', stats.toMap());
  }

  Future<List<Map<String, dynamic>>> getConsultationStatsSummary() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        provider,
        document_type,
        COUNT(*) as total,
        SUM(success) as success_count,
        COUNT(*) - SUM(success) as failure_count
      FROM api_consultation_stats
      GROUP BY provider, document_type
      ORDER BY total DESC
    ''');
  }

  Future<void> insertKardexEntry(KardexEntry entry) async {
    final db = await database;
    await db.insert('kardex', entry.toMap());
  }

  Future<List<KardexEntry>> getKardexByProduct(int productId) async {
    final db = await database;
    final maps = await db.query(
      'kardex',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date ASC, id ASC',
    );
    return maps.map((m) => KardexEntry.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getKardexSummary(int productId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(quantity_in), 0) as total_in,
        COALESCE(SUM(quantity_out), 0) as total_out,
        COALESCE(SUM(total_value), 0) as total_value
      FROM kardex WHERE product_id = ?
    ''', [productId]);
    return result.first;
  }

  Future<void> recordKardexFromSale({
    required int productId,
    required String productCode,
    required String productName,
    required double quantity,
    required double unitPrice,
    required String documentNumber,
    required String documentType,
  }) async {
    final currentProduct = await getProductByCode(productCode);
    final currentStock = currentProduct?.stock ?? 0;
    final entry = KardexEntry(
      productId: productId,
      productCode: productCode,
      productName: productName,
      documentType: documentType,
      documentNumber: documentNumber,
      reference: 'Venta $documentType $documentNumber',
      quantityOut: quantity,
      stockBalance: currentStock,
      unitPrice: unitPrice,
      totalValue: quantity * unitPrice,
    );
    await insertKardexEntry(entry);
  }

  Future<void> recordKardexFromAdjustment({
    required int productId,
    required String productCode,
    required String productName,
    required int oldStock,
    required int newStock,
  }) async {
    final now = DateTime.now();
    final ref = 'Ajuste manual (${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute})';
    if (newStock > oldStock) {
      await insertKardexEntry(KardexEntry(
        productId: productId,
        productCode: productCode,
        productName: productName,
        documentType: 'AJUSTE',
        reference: ref,
        quantityIn: (newStock - oldStock).toDouble(),
        stockBalance: newStock,
      ));
    } else if (newStock < oldStock) {
      await insertKardexEntry(KardexEntry(
        productId: productId,
        productCode: productCode,
        productName: productName,
        documentType: 'AJUSTE',
        reference: ref,
        quantityOut: (oldStock - newStock).toDouble(),
        stockBalance: newStock,
      ));
    }
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> addToSyncQueue({
    required String tableName,
    int? recordId,
    required String operation,
    Map<String, dynamic>? data,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data != null ? jsonEncode(data) : null,
      'created_at': _nowUtcIso(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue',
        where: 'synced = 0', orderBy: 'created_at ASC', limit: 50);
  }

  Future<void> markSynced(int syncId) async {
    final db = await database;
    await db.update('sync_queue', {'synced': 1},
        where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> markAllSynced() async {
    final db = await database;
    await db.update('sync_queue', {'synced': 1}, where: 'synced = 0');
  }

  Future<List<Map<String, dynamic>>> clearSyncedQueue() async {
    final db = await database;
    return await db
        .rawQuery('DELETE FROM sync_queue WHERE synced = 1 RETURNING *');
  }

  Future<int> deleteSyncedQueue() async {
    final db = await database;
    return await db.delete('sync_queue', where: 'synced = 1');
  }

  Future<Map<String, int>> countPendingSync() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT table_name, COUNT(*) as count FROM sync_queue WHERE synced = 0 GROUP BY table_name');
    final map = <String, int>{};
    for (final row in result) {
      map[row['table_name'] as String] = row['count'] as int;
    }
    return map;
  }

  Future<DateTime?> getLastSyncTime() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT MAX(created_at) as last_sync FROM sync_queue WHERE synced = 1');
    final lastSync = result.first['last_sync'] as String?;
    if (lastSync == null) return null;
    return DateTime.tryParse(lastSync);
  }
}
