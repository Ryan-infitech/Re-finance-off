import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart' as model;
import 'encryption_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    // Create transactions table (sensitive fields stored encrypted as TEXT)
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        type $textType,
        amount $textType,
        category $textType,
        description $textType,
        image_path $textTypeNullable,
        date $textType,
        created_at $textType
      )
    ''');

    // Indexes for query performance
    await db.execute(
        'CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date DESC)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migration: drop old tables and recreate (single-user, no user_id)
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
    }
  }

  // Transaction CRUD operations (with encryption)
  Future<int> createTransaction(model.Transaction transaction) async {
    final db = await instance.database;
    final enc = EncryptionService.instance;

    final encryptedMap = {
      'type': transaction.type,
      'amount': enc.encryptAmount(transaction.amount),
      'category': enc.encryptData(transaction.category),
      'description': enc.encryptData(transaction.description),
      'image_path': transaction.imagePath,
      'date': transaction.date,
      'created_at': transaction.createdAt,
    };

    return await db.insert('transactions', encryptedMap);
  }

  model.Transaction _decryptTransaction(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return model.Transaction(
      id: map['id'],
      type: map['type'],
      amount: enc.decryptAmount(map['amount'] as String),
      category: enc.decryptData(map['category'] as String),
      description: enc.decryptData(map['description'] as String),
      imagePath: map['image_path'],
      date: map['date'],
      createdAt: map['created_at'],
    );
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return result.map((map) => _decryptTransaction(map)).toList();
  }

  Future<List<model.Transaction>> getTransactionsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return result.map((map) => _decryptTransaction(map)).toList();
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await instance.database;
    final enc = EncryptionService.instance;

    final encryptedMap = {
      'type': transaction.type,
      'amount': enc.encryptAmount(transaction.amount),
      'category': enc.encryptData(transaction.category),
      'description': enc.encryptData(transaction.description),
      'image_path': transaction.imagePath,
      'date': transaction.date,
      'created_at': transaction.createdAt,
    };

    return await db.update(
      'transactions',
      encryptedMap,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total income (decrypt each row)
  Future<double> getTotalIncome() async {
    final transactions = await getTransactionsByType('income');
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }

  // Get total expense (decrypt each row)
  Future<double> getTotalExpense() async {
    final transactions = await getTransactionsByType('expense');
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }

  // Get balance
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
