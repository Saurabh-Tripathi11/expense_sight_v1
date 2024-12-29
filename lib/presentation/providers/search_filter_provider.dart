// lib/presentation/providers/search_filter_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';

enum ExpenseSortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

class ExpenseFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> categoryIds;
  final double? minAmount;
  final double? maxAmount;

  ExpenseFilter({
    this.startDate,
    this.endDate,
    this.categoryIds = const [],
    this.minAmount,
    this.maxAmount,
  });

  ExpenseFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    double? minAmount,
    double? maxAmount,
  }) {
    return ExpenseFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}

class SearchFilterProvider with ChangeNotifier {
  String _searchQuery = '';
  ExpenseFilter _filter = ExpenseFilter();
  ExpenseSortOption _sortOption = ExpenseSortOption.dateDesc;
  bool _isSearchActive = false;

  String get searchQuery => _searchQuery;
  ExpenseFilter get filter => _filter;
  ExpenseSortOption get sortOption => _sortOption;
  bool get isSearchActive => _isSearchActive;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearchActive = !_isSearchActive;
    if (!_isSearchActive) {
      _searchQuery = '';
    }
    notifyListeners();
  }

  void setFilter(ExpenseFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSortOption(ExpenseSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearAll() {
    _searchQuery = '';
    _filter = ExpenseFilter();
    _sortOption = ExpenseSortOption.dateDesc;
    notifyListeners();
  }

  List<Expense> filterExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!expense.note.toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Date range filter
      if (_filter.startDate != null && expense.date.isBefore(_filter.startDate!)) {
        return false;
      }
      if (_filter.endDate != null && expense.date.isAfter(_filter.endDate!)) {
        return false;
      }

      // Category filter
      if (_filter.categoryIds.isNotEmpty && !_filter.categoryIds.contains(expense.categoryId)) {
        return false;
      }

      // Amount range filter
      if (_filter.minAmount != null && expense.amount < _filter.minAmount!) {
        return false;
      }
      if (_filter.maxAmount != null && expense.amount > _filter.maxAmount!) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Expense> sortExpenses(List<Expense> expenses) {
    switch (_sortOption) {
      case ExpenseSortOption.dateDesc:
        return expenses..sort((a, b) => b.date.compareTo(a.date));
      case ExpenseSortOption.dateAsc:
        return expenses..sort((a, b) => a.date.compareTo(b.date));
      case ExpenseSortOption.amountDesc:
        return expenses..sort((a, b) => b.amount.compareTo(a.amount));
      case ExpenseSortOption.amountAsc:
        return expenses..sort((a, b) => a.amount.compareTo(b.amount));
    }
  }
}