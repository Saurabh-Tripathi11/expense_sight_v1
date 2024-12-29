// lib/presentation/providers/expense_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/expense.dart';
import '../../data/database/database_helper.dart';


class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _db;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  double get totalAmount => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  ExpenseProvider(this._db) {
    _loadExpenses();
  }

  Future<bool> deleteExpenseById(String id) async {
    try {
      print('Provider: Starting deletion process for ID: $id');
      _isLoading = true;
      notifyListeners();

      // First try to delete from database
      final success = await _db.deleteExpenseFromDB(id);

      if (success) {
        print('Provider: Database deletion successful, updating state');
        // If database deletion successful, update local state
        _expenses.removeWhere((expense) => expense.id == id);
        _error = null;

        print('Provider: Local state updated, expense count: ${_expenses.length}');
      } else {
        print('Provider: Database deletion failed');
        _error = 'Failed to delete expense';
      }

      _isLoading = false;
      notifyListeners();

      return success;

    } catch (e) {
      print('Provider: Error during deletion: $e');
      _error = 'Error deleting expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAllExpenses() async {
    try {
      print('Provider: Loading all expenses');
      _isLoading = true;
      notifyListeners();

      _expenses = await _db.getAllExpenses();
      _error = null;

      print('Provider: Loaded ${_expenses.length} expenses');

    } catch (e) {
      print('Provider: Error loading expenses: $e');
      _error = 'Error loading expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize and load expenses
  Future<void> _loadExpenses() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _expenses = await _db.getAllExpenses();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load expenses: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      print('ExpenseProvider: Deleting expense with ID: $id'); // Debug log

      // First remove from local state
      _expenses.removeWhere((expense) => expense.id == id);
      // Notify listeners immediately for UI update
      notifyListeners();

      // Then delete from database
      await _db.deleteExpense(id);

      print('ExpenseProvider: Expense deleted successfully'); // Debug log
    } catch (e) {
      print('ExpenseProvider: Error deleting expense: $e'); // Debug log

      // On error, refresh expenses from database to ensure consistent state
      await _loadExpenses();

      rethrow; // Rethrow to handle in UI
    }
  }

  // Add method to force refresh expenses
  Future<void> refreshExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      _expenses = await _db.getAllExpenses();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh expenses: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }


  // Group expenses by date
  Map<DateTime, List<Expense>> get groupedExpenses {
    final Map<DateTime, List<Expense>> grouped = {};

    for (final expense in _expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(expense);
    }

    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  // Add new expense
  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    try {
      final expense = Expense(
        id: _uuid.v4(),
        amount: amount,
        categoryId: categoryId,
        date: date,
        note: note,
      );

      await _db.insertExpense(expense);
      _expenses.add(expense);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add expense: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Update existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await _db.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update expense: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Get expenses for a specific date
  List<Expense> getExpensesForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _expenses.where((expense) {
      final expenseDay = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDay == day;
    }).toList();
  }

  // Get expenses for date range
  Future<List<Expense>> getExpensesForDateRange(DateTime start, DateTime end) async {
    try {
      return await _db.getExpensesByDateRange(start, end);
    } catch (e) {
      _error = 'Failed to get expenses: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // Calculate total for a specific category
  double getTotalForCategory(String categoryId) {
    return _expenses
        .where((expense) => expense.categoryId == categoryId)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Get expense statistics for a time period
  Future<Map<String, double>> getExpenseStatistics({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final expenses = await getExpensesForDateRange(start, end);

      final total = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
      final daysInPeriod = end.difference(start).inDays + 1;

      return {
        'total': total,
        'average_per_day': total / daysInPeriod,
        'max_single_expense': expenses.isEmpty
            ? 0
            : expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      _error = 'Failed to calculate statistics: ${e.toString()}';
      notifyListeners();
      return {};
    }
  }

  // Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Export expenses as CSV
  Future<String> exportAsCSV() async {
    final buffer = StringBuffer();

    // Add header
    buffer.writeln('Date,Amount,Category,Note,Created At');

    // Add data
    for (final expense in _expenses) {
      buffer.writeln(
          '${expense.date.toIso8601String()},${expense.amount},${expense.categoryId},${expense.note ?? ""},${expense.createdAt.toIso8601String()}'
      );
    }

    return buffer.toString();
  }

  // Import expenses from CSV
  Future<void> importFromCSV(String csvContent) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final lines = csvContent.split('\n');
      if (lines.length <= 1) throw Exception('Invalid CSV format');

      // Skip header
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 4) continue;

        final expense = Expense(
          id: _uuid.v4(),
          amount: double.parse(parts[1]),
          categoryId: parts[2],
          date: DateTime.parse(parts[0]),
          note: parts[3].isEmpty ? null : parts[3],
        );

        await _db.insertExpense(expense);
      }

      await _loadExpenses();
    } catch (e) {
      _error = 'Failed to import expenses: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}