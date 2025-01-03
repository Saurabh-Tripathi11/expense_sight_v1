// File: lib/presentation/screens/expense/expense_list_screen.dart

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
import '../analytics/analytics_screen.dart';
import '../category/category_list_screen.dart';
import 'add_expense_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';

class OptimizedExpenseList extends StatelessWidget {
  const OptimizedExpenseList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.expenses.isEmpty) {
          return const Center(child: Text('No expenses'));
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          cacheExtent: 1000, // Increase cache for smoother scrolling
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final expense = provider.expenses[index];

                  // Use RepaintBoundary to optimize rendering
                  return RepaintBoundary(
                    child: _ExpenseItem(
                      expense: expense,
                      // Use const constructor where possible
                      key: ValueKey(expense.id),
                    ),
                  );
                },
                childCount: provider.expenses.length,
                // Add custom config for better performance
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseItem({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Optimize rebuild with const where possible
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Card(
        child: ListTile(
          title: Text(expense.amount.toString()),
          subtitle: Text(expense.date.toString()),
        ),
      ),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _ExpenseListContent(),
    AnalyticsScreen(),
    CategoryListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final selectedColor = isDark ? Colors.white : primaryColor;
    final unselectedColor = isDark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(isDark ? 0.3 : 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildNavigationDestination(
            selectedIcon: Icons.account_balance_wallet,
            unselectedIcon: Icons.account_balance_wallet_outlined,
            label: 'Expenses',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            isSelected: _selectedIndex == 0,
          ),
          _buildNavigationDestination(
            selectedIcon: Icons.analytics,
            unselectedIcon: Icons.analytics_outlined,
            label: 'Analytics',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            isSelected: _selectedIndex == 1,
          ),
          _buildNavigationDestination(
            selectedIcon: Icons.category,
            unselectedIcon: Icons.category_outlined,
            label: 'Categories',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            isSelected: _selectedIndex == 2,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddExpenseSheet(context);
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  NavigationDestination _buildNavigationDestination({
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required Color selectedColor,
    required Color? unselectedColor,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Icon(
        unselectedIcon,
        color: unselectedColor,
        size: 24,
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: selectedColor,
        size: 24,
      ),
      label: label,
    );
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

// Create a separate widget for the expense list content
class _ExpenseListContent extends StatelessWidget {
  const _ExpenseListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
}