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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    // All sensitive fields stored encrypted as TEXT
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
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Re-encrypt: type and date are now encrypted too
      // Drop indexes that no longer work on encrypted data
      await db.execute('DROP INDEX IF EXISTS idx_transactions_type');
      await db.execute('DROP INDEX IF EXISTS idx_transactions_date');
      
      // Migrate existing data: encrypt type and date fields
      final rows = await db.query('transactions');
      final enc = EncryptionService.instance;
      for (final row in rows) {
        final id = row['id'];
        final type = row['type'] as String;
        final date = row['date'] as String;
        
        // Only encrypt if not already encrypted (plain values are short)
        if (type == 'income' || type == 'expense') {
          await db.update(
            'transactions',
            {
              'type': enc.encryptData(type),
              'date': enc.encryptData(date),
              'created_at': enc.encryptData(row['created_at'] as String),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    }
  }

  // Transaction CRUD operations (with full encryption)
  Future<int> createTransaction(model.Transaction transaction) async {
    final db = await instance.database;
    final enc = EncryptionService.instance;

    final encryptedMap = {
      'type': enc.encryptData(transaction.type),
      'amount': enc.encryptAmount(transaction.amount),
      'category': enc.encryptData(transaction.category),
      'description': enc.encryptData(transaction.description),
      'image_path': transaction.imagePath,
      'date': enc.encryptData(transaction.date),
      'created_at': enc.encryptData(transaction.createdAt),
    };

    return await db.insert('transactions', encryptedMap);
  }

  model.Transaction _decryptTransaction(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return model.Transaction(
      id: map['id'],
      type: enc.decryptData(map['type'] as String),
      amount: enc.decryptAmount(map['amount'] as String),
      category: enc.decryptData(map['category'] as String),
      description: enc.decryptData(map['description'] as String),
      imagePath: map['image_path'],
      date: enc.decryptData(map['date'] as String),
      createdAt: enc.decryptData(map['created_at'] as String),
    );
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    final transactions = result.map((map) => _decryptTransaction(map)).toList();
    // Sort by date descending after decryption
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<List<model.Transaction>> getTransactionsByType(String type) async {
    // All fields are encrypted, so filter in app layer
    final all = await getAllTransactions();
    return all.where((t) => t.type == type).toList();
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await instance.database;
    final enc = EncryptionService.instance;

    final encryptedMap = {
      'type': enc.encryptData(transaction.type),
      'amount': enc.encryptAmount(transaction.amount),
      'category': enc.encryptData(transaction.category),
      'description': enc.encryptData(transaction.description),
      'image_path': transaction.imagePath,
      'date': enc.encryptData(transaction.date),
      'created_at': enc.encryptData(transaction.createdAt),
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

  Future<void> deleteAllTransactions() async {
    final db = await instance.database;
    await db.delete('transactions');
    // Close and reset so next access gets fresh connection
    await db.close();
    _database = null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
