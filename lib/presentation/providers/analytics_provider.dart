// lib/presentation/providers/analytics_provider.dart

import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../domain/models/analytics_data.dart';
import '../../domain/models/expense.dart';

class AnalyticsProvider with ChangeNotifier {
  final DatabaseHelper _db;
  bool _isLoading = false;
  String? _error;

  AnalyticsSummary? _summary;
  List<CategoryAnalytics> _categoryAnalytics = [];
  List<ExpenseTrend> _trends = [];
  Map<String, double> _categoryTotals = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AnalyticsSummary? get summary => _summary;
  List<CategoryAnalytics> get categoryAnalytics => _categoryAnalytics;
  List<ExpenseTrend> get trends => _trends;
  Map<String, double> get categoryTotals => _categoryTotals;

  AnalyticsProvider(this._db);

  Future<void> loadAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    try {
      _setLoading(true);

      // Fetch expenses for the date range
      final expenses = await _db.getExpensesByDateRange(startDate, endDate);

      // Process analytics data
      await _processAnalyticsData(expenses, startDate, endDate);

      _error = null;
    } catch (e) {
      _error = 'Failed to load analytics: ${e.toString()}';
      debugPrint('Analytics error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _processAnalyticsData(
      List<Expense> expenses,
      DateTime startDate,
      DateTime endDate,
      ) async {
    // Calculate base metrics
    final totalExpenses = expenses.fold<double>(
      0,
          (sum, expense) => sum + expense.amount,
    );

    final days = endDate.difference(startDate).inDays + 1;
    final dailyAverage = totalExpenses / days;

    // Process category data
    await _processCategoryData(expenses, totalExpenses);

    // Process trend data
    _processTrendData(expenses, startDate, endDate);

    // Calculate monthly change
    final monthlyChange = await _calculateMonthlyChange(expenses, startDate, endDate);

    // Find top category
    final topCategory = _findTopCategory();

    // Create summary
    _summary = AnalyticsSummary(
      totalExpenses: totalExpenses,
      dailyAverage: dailyAverage,
      monthlyChange: monthlyChange,
      topCategory: topCategory,
      startDate: startDate,
      endDate: endDate,
    );

    notifyListeners();
  }

  Future<void> _processCategoryData(List<Expense> expenses, double totalExpenses) async {
    _categoryTotals = {};
    final categoryAnalyticsList = <CategoryAnalytics>[];

    // Group expenses by category
    for (final expense in expenses) {
      _categoryTotals[expense.categoryId] =
          (_categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }

    // Create category analytics objects
    for (final entry in _categoryTotals.entries) {
      try {
        final category = await _db.getCategoryById(entry.key);
        final amount = entry.value;
        final percentage = (amount / totalExpenses * 100);

        categoryAnalyticsList.add(CategoryAnalytics(
          categoryId: entry.key,
          categoryName: category.name,
          amount: amount,
          percentage: percentage,
          icon: category.icon,
          color: category.color,
        ));
      } catch (e) {
        debugPrint('Error processing category ${entry.key}: $e');
      }
    }

    // Sort by amount descending
    categoryAnalyticsList.sort((a, b) => b.amount.compareTo(a.amount));
    _categoryAnalytics = categoryAnalyticsList;
  }


  Future<double> _calculateMonthlyChange(
      List<Expense> expenses,
      DateTime startDate,
      DateTime endDate,
      ) async {
    // Calculate the duration of the current period
    final periodDuration = endDate.difference(startDate);

    // Get expenses for the previous period of the same duration
    final previousPeriodStart = startDate.subtract(periodDuration);
    final previousPeriodEnd = startDate.subtract(const Duration(days: 1));

    final previousExpenses = await _db.getExpensesByDateRange(
      previousPeriodStart,
      previousPeriodEnd,
    );

    // Calculate totals
    final currentTotal = expenses.fold<double>(
      0,
          (sum, expense) => sum + expense.amount,
    );

    final previousTotal = previousExpenses.fold<double>(
      0,
          (sum, expense) => sum + expense.amount,
    );

    // Calculate percentage change
    if (previousTotal == 0) {
      return currentTotal > 0 ? 100 : 0;
    }

    return ((currentTotal - previousTotal) / previousTotal * 100);
  }

  String _findTopCategory() {
    if (_categoryAnalytics.isEmpty) {
      return '';
    }
    return _categoryAnalytics.first.categoryId;
  }

  // Additional analytics methods

  Future<Map<String, double>> getAveragesPerCategory() async {
    if (_categoryTotals.isEmpty) return {};

    final averages = <String, double>{};
    for (final entry in _categoryTotals.entries) {
      averages[entry.key] = entry.value / (_trends.length);
    }
    return averages;
  }

  Future<List<DailyExpense>> getDailyBreakdown() async {
    return _trends.map((trend) {
      return DailyExpense(
        date: trend.date,
        amount: trend.amount,
        categoryAmounts: trend.categoryAmounts,
      );
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // In AnalyticsProvider class, update the _processTrendData method:

  // ... other code remains same ...

  void _processTrendData(List<Expense> expenses, DateTime startDate, DateTime endDate) {
  print('Processing trend data for ${expenses.length} expenses');
  final trendsList = <ExpenseTrend>[];

  if (expenses.isEmpty) {
  print('No expenses to process');
  _trends = [];
  return;
  }

  // Create a map to store daily totals
  final Map<DateTime, double> dailyTotals = {};

  // Initialize all dates in range with 0
  // Modify this part to include the end date properly
  DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
  final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

  while (currentDate.isBefore(endDateTime) || currentDate.isAtSameMomentAs(endDateTime)) {
  final normalizedDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
  dailyTotals[normalizedDate] = 0;
  currentDate = currentDate.add(const Duration(days: 1));
  }

  // Add up expenses for each day
  for (final expense in expenses) {
  final normalizedDate = DateTime(
  expense.date.year,
  expense.date.month,
  expense.date.day,
  );
  dailyTotals[normalizedDate] = (dailyTotals[normalizedDate] ?? 0) + expense.amount;
  }

  // Convert to trend objects
  dailyTotals.forEach((date, amount) {
  print('Creating trend for date: $date with amount: $amount'); // Debug print
  trendsList.add(ExpenseTrend(
  date: date,
  amount: amount,
  categoryAmounts: _getCategoryAmountsForDate(expenses, date),
  ));
  });

  // Sort by date
  trendsList.sort((a, b) => a.date.compareTo(b.date));

  print('Generated ${trendsList.length} trend data points');
  trendsList.forEach((trend) {
  print('Date: ${trend.date}, Amount: ${trend.amount}');
  });

  _trends = trendsList;
  notifyListeners();
  }

  Map<String, double> _getCategoryAmountsForDate(List<Expense> expenses, DateTime date) {
  final categoryAmounts = <String, double>{};

  final dayExpenses = expenses.where((expense) {
  final expenseDate = DateTime(
  expense.date.year,
  expense.date.month,
  expense.date.day,
  );
  // Use isAtSameMomentAs instead of == for date comparison
  return expenseDate.isAtSameMomentAs(date);
  });

  for (final expense in dayExpenses) {
  categoryAmounts[expense.categoryId] =
  (categoryAmounts[expense.categoryId] ?? 0) + expense.amount;
  }

  return categoryAmounts;
  }


  // Method to export analytics data
  Map<String, dynamic> exportAnalytics() {
    return {
      'summary': _summary != null ? {
        'totalExpenses': _summary!.totalExpenses,
        'dailyAverage': _summary!.dailyAverage,
        'monthlyChange': _summary!.monthlyChange,
        'startDate': _summary!.startDate.toIso8601String(),
        'endDate': _summary!.endDate.toIso8601String(),
      } : null,
      'categoryAnalytics': _categoryAnalytics.map((ca) => {
        'categoryId': ca.categoryId,
        'amount': ca.amount,
        'percentage': ca.percentage,
      }).toList(),
      'trends': _trends.map((trend) => {
        'date': trend.date.toIso8601String(),
        'amount': trend.amount,
        'categoryAmounts': trend.categoryAmounts,
      }).toList(),
    };
  }
}
