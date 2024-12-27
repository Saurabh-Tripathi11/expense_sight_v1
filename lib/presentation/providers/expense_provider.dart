// lib/presentation/providers/expense_provider.dart
import 'package:flutter/material.dart';
import '../../domain/models/expense.dart';
import 'package:uuid/uuid.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  final _uuid = const Uuid();

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

    // Sort by date descending (newest first)
    return Map.fromEntries(
        grouped.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
    );

    _expenses.add(expense);
    notifyListeners();
  }

  double get totalAmount => _expenses.fold(
      0,
          (total, expense) => total + expense.amount
  );

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
}