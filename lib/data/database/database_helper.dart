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
  Future<bool> deleteExpenseFromDB(String expenseId) async {
    final db = await database;

    try {
      print('DB Helper: Starting deletion for expense ID: $expenseId');

      // Verify expense exists first
      final List<Map<String, dynamic>> expense = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (expense.isEmpty) {
        print('DB Helper: No expense found with ID: $expenseId');
        return false;
      }

      // Perform deletion
      final deletedRows = await db.rawDelete(
        'DELETE FROM expenses WHERE id = ?',
        [expenseId],
      );

      print('DB Helper: Deleted $deletedRows rows');

      return deletedRows > 0;
    } catch (e) {
      print('DB Helper: Error during deletion: $e');
      throw Exception('Failed to delete expense: $e');
    }
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
    try {
      final db = await database;
      final startTimestamp = DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
      final endTimestamp = DateTime(end.year, end.month, end.day, 23, 59, 59).millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: 'date DESC',
      );

      print('DatabaseHelper: Found ${maps.length} expenses in date range');
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } catch (e) {
      print('DatabaseHelper: Error getting expenses by date range: $e');
      throw Exception('Failed to get expenses by date range: $e');
    }
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
      final db = await database;

      print('DatabaseHelper: Beginning delete transaction for ID: $id');

      await db.transaction((txn) async {
        final rowsDeleted = await txn.delete(
          'expenses',
          where: 'id = ?',
          whereArgs: [id],
        );

        print('DatabaseHelper: Rows deleted: $rowsDeleted');

        if (rowsDeleted == 0) {
          throw Exception('No expense found with ID: $id');
        }
      });

      print('DatabaseHelper: Delete transaction completed successfully');
    } catch (e) {
      print('DatabaseHelper: Error in delete transaction: $e');
      rethrow;
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
  // Add analytics caching support
  Future<void> cacheAnalyticsData(String type, String data, Duration validity) async {
    final db = await database;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'analytics_cache',
        {
          'type': type,
          'data': data,
          'timestamp': now,
          'valid_until': now + validity.inMilliseconds,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error caching analytics data: $e');
      throw Exception('Failed to cache analytics data');
    }
  }

  Future<String?> getAnalyticsCache(String type) async {
    final db = await database;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final List<Map<String, dynamic>> maps = await db.query(
        'analytics_cache',
        where: 'type = ? AND valid_until > ?',
        whereArgs: [type, now],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return maps.first['data'] as String;
    } catch (e) {
      print('Error getting analytics cache: $e');
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getAnalyticsSummary(DateTime startDate, DateTime endDate) async {
    final db = await database;
    try {
      // Get total expenses and categories for the period
      final result = await db.rawQuery('''
        SELECT 
          SUM(amount) as totalAmount,
          COUNT(*) as totalTransactions,
          categoryId,
          MIN(date) as firstTransaction,
          MAX(date) as lastTransaction
        FROM expenses
        WHERE date >= ? AND date <= ?
        GROUP BY categoryId
      ''', [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);

      return result;
    } catch (e) {
      print('Error getting analytics summary: $e');
      throw Exception('Failed to get analytics summary');
    }
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(DateTime startDate, DateTime endDate) async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT 
          date,
          SUM(amount) as dailyTotal,
          categoryId,
          COUNT(*) as transactionCount
        FROM expenses
        WHERE date >= ? AND date <= ?
        GROUP BY date, categoryId
        ORDER BY date ASC
      ''', [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);

      return result;
    } catch (e) {
      print('Error getting daily expenses: $e');
      throw Exception('Failed to get daily expenses');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryTrends(DateTime startDate, DateTime endDate) async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT 
          categoryId,
          strftime('%Y-%m', datetime(date/1000, 'unixepoch')) as month,
          SUM(amount) as monthlyTotal,
          COUNT(*) as transactionCount
        FROM expenses
        WHERE date >= ? AND date <= ?
        GROUP BY categoryId, month
        ORDER BY month ASC
      ''', [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);

      return result;
    } catch (e) {
      print('Error getting category trends: $e');
      throw Exception('Failed to get category trends');
    }
  }

  Future<Category> getCategoryById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw Exception('Category not found');
      }

      return Category.fromMap(maps.first);
    } catch (e) {
      print('Error getting category by ID: $e');
      throw Exception('Failed to get category');
    }
  }


  Future<void> clearAnalyticsCache() async {
    final db = await database;
    try {
      await db.delete('analytics_cache');
    } catch (e) {
      print('Error clearing analytics cache: $e');
      throw Exception('Failed to clear analytics cache');
    }
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
