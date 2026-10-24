// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/invoice_model.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static const _dbName    = 'a1_battery_billing.db';
  static const _dbVersion = 2;

  // Table names
  static const tInvoices = 'invoices';
  static const tProducts = 'products';

  // Singleton
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Initialise ────────────────────────────────────────────────
  Future<Database> _initDb() async {
    final dir  = await getDatabasesPath();
    final path = p.join(dir, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tInvoices (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no       INTEGER UNIQUE NOT NULL,
        date_time        TEXT    NOT NULL,
        customer_name    TEXT    NOT NULL,
        customer_address TEXT    DEFAULT '',
        customer_phone   TEXT    DEFAULT '',
        customer_district TEXT   DEFAULT '',
        customer_pincode  TEXT   DEFAULT '',
        customer_gstin    TEXT   DEFAULT '',
        customer_state    TEXT   DEFAULT '',
        total_amount     REAL    NOT NULL,
        invoice_json     TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tProducts (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    // Seed default products
    final batch = db.batch();
    for (final product in AppConstants.defaultProducts) {
      batch.insert(tProducts, {'name': product},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('ALTER TABLE $tInvoices ADD COLUMN customer_district TEXT DEFAULT ""');
      await db.execute('ALTER TABLE $tInvoices ADD COLUMN customer_pincode TEXT DEFAULT ""');
      await db.execute('ALTER TABLE $tInvoices ADD COLUMN customer_gstin TEXT DEFAULT ""');
      await db.execute('ALTER TABLE $tInvoices ADD COLUMN customer_state TEXT DEFAULT ""');
    }
  }

  // ── Invoice Number ────────────────────────────────────────────
  /// Returns next suggested invoice number (numeric max + 1) or "1" if table is empty.
  Future<String> getNextInvoiceNo() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT invoice_no FROM $tInvoices');
    int maxNo = 0;
    for (final r in rows) {
      final v = r['invoice_no'];
      if (v is int) {
        if (v > maxNo) maxNo = v;
      } else if (v != null) {
        final parsed = int.tryParse(v.toString());
        if (parsed != null && parsed > maxNo) {
          maxNo = parsed;
        }
      }
    }
    return (maxNo + 1).toString();
  }

  /// Checks if an invoice number already exists in the database
  Future<bool> checkInvoiceNoExists(String invoiceNo, {int? excludeId}) async {
    final clean = invoiceNo.trim();
    if (clean.isEmpty) return false;
    final db = await database;
    final intVal = int.tryParse(clean);

    final query = excludeId != null
        ? 'SELECT id FROM $tInvoices WHERE (invoice_no = ? OR invoice_no = ?) AND id != ? LIMIT 1'
        : 'SELECT id FROM $tInvoices WHERE (invoice_no = ? OR invoice_no = ?) LIMIT 1';
    final args = excludeId != null
        ? [clean, intVal ?? clean, excludeId]
        : [clean, intVal ?? clean];

    final res = await db.rawQuery(query, args);
    return res.isNotEmpty;
  }

  // ── Save Invoice ──────────────────────────────────────────────
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    final id = await db.insert(
      tInvoices,
      invoice.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // ── Fetch All Invoices (newest first) ─────────────────────────
  Future<List<Invoice>> getAllInvoices() async {
    final db   = await database;
    final rows = await db.query(
      tInvoices,
      orderBy: 'id DESC',
    );
    return rows.map(Invoice.fromDbMap).toList();
  }

  // ── Search Invoices ───────────────────────────────────────────
  Future<List<Invoice>> searchInvoices(String query) async {
    final db   = await database;
    final q    = '%$query%';
    final rows = await db.query(
      tInvoices,
      where: 'customer_name LIKE ? OR invoice_no LIKE ?',
      whereArgs: [q, q],
      orderBy: 'id DESC',
    );
    return rows.map(Invoice.fromDbMap).toList();
  }

  // ── Fetch Single Invoice ─────────────────────────────────────
  Future<Invoice?> getInvoiceByNo(dynamic invoiceNo) async {
    final db   = await database;
    final str  = invoiceNo.toString();
    final intVal = int.tryParse(str);
    final rows = await db.query(
      tInvoices,
      where: 'invoice_no = ? OR invoice_no = ?',
      whereArgs: [str, intVal ?? str],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Invoice.fromDbMap(rows.first);
  }

  // ── Delete Invoice ────────────────────────────────────────────
  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete(tInvoices, where: 'id = ?', whereArgs: [id]);
  }

  // ── Products ──────────────────────────────────────────────────
  Future<List<String>> getProducts() async {
    final db   = await database;
    final rows = await db.query(tProducts, orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> addProduct(String name) async {
    final db = await database;
    await db.insert(
      tProducts,
      {'name': name.trim()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteProduct(String name) async {
    final db = await database;
    await db.delete(tProducts, where: 'name = ?', whereArgs: [name]);
  }

  // ── Stats ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt, SUM(total_amount) as total FROM $tInvoices',
    );
    return {
      'count': countResult.first['cnt'] ?? 0,
      'total': countResult.first['total'] ?? 0.0,
    };
  }

  // ── Recent Invoices (for home screen) ─────────────────────────
  Future<List<Invoice>> getRecentInvoices({int limit = 5}) async {
    final db   = await database;
    final rows = await db.query(
      tInvoices,
      orderBy: 'invoice_no DESC',
      limit: limit,
    );
    return rows.map(Invoice.fromDbMap).toList();
  }

  // ── Raw DB Path (for backup) ──────────────────────────────────
  Future<String> getDatabasePath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, _dbName);
  }

  // ── Close ─────────────────────────────────────────────────────
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
