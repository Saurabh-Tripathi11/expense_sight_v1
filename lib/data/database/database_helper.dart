// lib/data/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/category.dart';
import '../../domain/models/expense.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._();
  static const String dbName = 'expense_sight.db';

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), dbName);
    print('Database path: $path'); // Debug print

    return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // Create expenses table
          await db.execute('''
          CREATE TABLE expenses (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            categoryId TEXT NOT NULL,
            date INTEGER NOT NULL,
            note TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isSynced INTEGER DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          )
        ''');

          // Create expenses table
          await db.execute('''
          CREATE TABLE expenses (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            categoryId TEXT NOT NULL,
            date INTEGER NOT NULL,
            note TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isSynced INTEGER DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          )
        ''');

          // Create analytics table for caching
          await db.execute('''
          CREATE TABLE analytics_cache (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            data TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            validUntil INTEGER NOT NULL
          )
        ''');

          // Create settings table
          await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');

          // Create indexes
          await db.execute('CREATE INDEX idx_expenses_category ON expenses(categoryId)');
          await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
          await db.execute('CREATE INDEX idx_expenses_synced ON expenses(isSynced)');
          await db.execute('CREATE INDEX idx_categories_parent ON categories(parentId)');
        });
  }

  // Expense Operations

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      {...expense.toMap(), 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }


  // Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      print('DatabaseHelper: Deleting expense with ID: $id'); // Debug print
      final db = await database;
      final rowsDeleted = await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Rows deleted: $rowsDeleted'); // Debug print
      if (rowsDeleted == 0) {
        throw Exception('Expense not found');
      }
    } catch (e) {
      print('DatabaseHelper: Error deleting expense: $e'); // Debug print
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );
      print('DatabaseHelper: Found ${maps.length} expenses'); // Debug print
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } catch (e) {
      print('DatabaseHelper: Error getting expenses: $e'); // Debug print
      throw Exception('Failed to get expenses: $e');
    }
  }


  // Category Operations
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings Operations
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Analytics Cache Operations
  Future<void> cacheAnalyticsData(String type, String data, Duration validity) async {
    final db = await database;
    final now = DateTime.now();
    await db.insert(
      'analytics_cache',
      {
        'id': '${type}_${now.millisecondsSinceEpoch}',
        'type': type,
        'data': data,
        'createdAt': now.millisecondsSinceEpoch,
        'validUntil': now.add(validity).millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getAnalyticsCache(String type) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'analytics_cache',
      where: 'type = ? AND validUntil > ?',
      whereArgs: [type, now],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['data'] as String;
  }

  // Cleanup Operations
  Future<void> cleanupOldData() async {
    final db = await database;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));

    // Clean old analytics cache
    await db.delete(
      'analytics_cache',
      where: 'validUntil < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }
}