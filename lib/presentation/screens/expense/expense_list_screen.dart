// lib/presentation/screens/expense/expense_list_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/search_filter_provider.dart';
import '../../widgets/expense/empty_expense_list.dart';
import '../../widgets/expense/expense_list_item.dart';
import '../../widgets/expense/expense_date_header.dart';
import '../../widgets/expense/quick_actions_sheet.dart';
import '../../widgets/expense/search_bar.dart';
import '../../widgets/expense/filter_sheet.dart';
import 'add_expense_sheet.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Glass effect app bar with search and filter
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                  child: Column(
                    children: [
                      // App bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                context.read<SearchFilterProvider>().toggleSearch();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () => _showFilterSheet(context),
                            ),
                          ],
                        ),
                      ),
                      Consumer<SearchFilterProvider>(
                        builder: (context, provider, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: provider.isSearchActive
                                ? const ExpenseSearchBar()
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expense list
            Expanded(
              child: Consumer3<ExpenseProvider, CategoryProvider, SearchFilterProvider>(
                builder: (context, expenseProvider, categoryProvider, searchFilterProvider, _) {
                  if (expenseProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (expenseProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${expenseProvider.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => expenseProvider.refreshExpenses(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  var expenses = expenseProvider.expenses;
                  expenses = searchFilterProvider.filterExpenses(expenses);
                  expenses = searchFilterProvider.sortExpenses(expenses);

                  if (expenses.isEmpty) {
                    if (searchFilterProvider.searchQuery.isNotEmpty ||
                        searchFilterProvider.filter.categoryIds.isNotEmpty) {
                      return const Center(
                        child: Text('No expenses match your filters'),
                      );
                    }
                    return const EmptyExpenseList();
                  }

                  // Group expenses by date
                  final groupedExpenses = <DateTime, List<Expense>>{};
                  for (final expense in expenses) {
                    final date = DateTime(
                      expense.date.year,
                      expense.date.month,
                      expense.date.day,
                    );
                    groupedExpenses.putIfAbsent(date, () => []).add(expense);
                  }

                  return RefreshIndicator(
                    onRefresh: () => expenseProvider.refreshExpenses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: groupedExpenses.length,
                      itemBuilder: (context, index) {
                        final date = groupedExpenses.keys.elementAt(index);
                        final dayExpenses = groupedExpenses[date]!;
                        final totalAmount = dayExpenses.fold<double>(
                          0,
                              (sum, expense) => sum + expense.amount,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpenseDateHeader(
                              date: date,
                              totalAmount: totalAmount,
                            ),
                            ...dayExpenses.map((expense) {
                              final category = categoryProvider.getCategoryById(
                                expense.categoryId,
                              );
                              if (category == null) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ExpenseListItem(
                                  expense: expense,
                                  category: category,
                                  onTap: () => _showExpenseDetails(context, expense, category),
                                  onLongPress: () => _showQuickActions(context, expense),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddExpenseSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickActions(BuildContext context, Expense expense) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsSheet(expense: expense),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FilterSheet(),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense, Category category) {
    // TODO: Implement expense details view
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseSheet(),
    );
  }
}