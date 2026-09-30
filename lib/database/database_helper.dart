import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/debtor_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

/// Singleton Database Helper for managing SQLite database operations across Web, Mobile & Desktop.
class DatabaseHelper {
  static const String _dbName = 'qarz_khaata.db';
  static const int _dbVersion = 3;

  // Table names
  static const String tableDebtors = 'debtors';
  static const String tableTransactions = 'transactions';
  static const String tableUsers = 'users';

  // Private Singleton Constructor
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Returns the existing Database instance or initializes a new one.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database.
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Initialize IndexedDB/Wasm SQLite factory for Web (Chrome/Edge)
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI SQLite for Desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable Foreign Key Support
  Future<void> _onConfigure(Database db) async {
    // Foreign keys PRAGMA on web/native
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      debugPrint('Foreign keys PRAGMA skipped or not supported: $e');
    }
  }

  /// Create Database Tables
  Future<void> _onCreate(Database db, int version) async {
    // Create debtors table
    await db.execute('''
      CREATE TABLE $tableDebtors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtor_id INTEGER NOT NULL,
        item_details TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        due_date TEXT,
        FOREIGN KEY (debtor_id) REFERENCES $tableDebtors (id) ON DELETE CASCADE
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Database upgrade migration
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          image_path TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableTransactions ADD COLUMN due_date TEXT');
      } catch (e) {
        debugPrint('Column due_date already exists or upgrade error: $e');
      }
    }
  }

  // ===========================================================================
  // DEBTOR OPERATIONS
  // ===========================================================================

  /// Insert a new debtor into the database.
  Future<int> insertDebtor(Debtor debtor) async {
    final db = await database;
    return await db.insert(tableDebtors, debtor.toMap());
  }

  /// Update an existing debtor's info (e.g. name, phone).
  Future<int> updateDebtor(Debtor debtor) async {
    final db = await database;
    return await db.update(
      tableDebtors,
      debtor.toMap(),
      where: 'id = ?',
      whereArgs: [debtor.id],
    );
  }

  /// Delete a debtor and all their associated transactions (via CASCADE).
  Future<int> deleteDebtor(int debtorId) async {
    final db = await database;
    return await db.delete(
      tableDebtors,
      where: 'id = ?',
      whereArgs: [debtorId],
    );
  }

  /// Fetch all debtors along with their calculated net balance.
  /// Balance formula: SUM(GAVE) - SUM(GOT)
  Future<List<Debtor>> getDebtorsWithBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        d.id,
        d.name,
        d.phone,
        d.created_at,
        COALESCE(SUM(CASE WHEN t.type = 'GAVE' THEN t.amount WHEN t.type = 'GOT' THEN -t.amount ELSE 0 END), 0.0) as net_balance
      FROM $tableDebtors d
      LEFT JOIN $tableTransactions t ON d.id = t.debtor_id
      GROUP BY d.id
      ORDER BY d.id DESC
    ''');

    return List.generate(maps.length, (i) {
      return Debtor.fromMap(
        maps[i],
        calculatedNetBalance: (maps[i]['net_balance'] as num).toDouble(),
      );
    });
  }

  /// Fetch a single debtor by ID with updated net balance.
  Future<Debtor?> getDebtorById(int debtorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        d.id,
        d.name,
        d.phone,
        d.created_at,
        COALESCE(SUM(CASE WHEN t.type = 'GAVE' THEN t.amount WHEN t.type = 'GOT' THEN -t.amount ELSE 0 END), 0.0) as net_balance
      FROM $tableDebtors d
      LEFT JOIN $tableTransactions t ON d.id = t.debtor_id
      WHERE d.id = ?
      GROUP BY d.id
    ''', [debtorId]);

    if (maps.isNotEmpty) {
      return Debtor.fromMap(
        maps.first,
        calculatedNetBalance: (maps.first['net_balance'] as num).toDouble(),
      );
    }
    return null;
  }

  // ===========================================================================
  // USER OPERATIONS (SQLite)
  // ===========================================================================

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    await db.delete(tableUsers); // Only keep 1 active local user profile
    return await db.insert(tableUsers, user.toMap());
  }

  Future<UserModel?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableUsers, limit: 1);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // ===========================================================================
  // TRANSACTION OPERATIONS
  // ===========================================================================

  /// Insert a new ledger transaction for a debtor.
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(tableTransactions, transaction.toMap());
  }

  /// Update an existing transaction entry.
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete a transaction by ID.
  Future<int> deleteTransaction(int transactionId) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Fetch all transactions for a specific debtor ordered by date (newest first).
  Future<List<TransactionModel>> getTransactionsForDebtor(int debtorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'debtor_id = ?',
      whereArgs: [debtorId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
