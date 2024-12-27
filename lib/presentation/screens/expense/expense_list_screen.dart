// lib/presentation/screens/expense/expense_list_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/expense/empty_expense_list.dart';
import '../../widgets/expense/expense_list_item.dart';
import '../../widgets/expense/expense_date_header.dart';
import 'add_expense_sheet.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Glass effect app bar
            SliverPersistentHeader(
              floating: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60,
                maxHeight: 60,
                child: _buildAppBar(context),
              ),
            ),

            // Expenses list
            Consumer2<ExpenseProvider, CategoryProvider>(
              builder: (context, expenseProvider, categoryProvider, _) {
                final groupedExpenses = expenseProvider.groupedExpenses;

                if (groupedExpenses.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyExpenseList(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final date = groupedExpenses.keys.elementAt(index);
                      final expenses = groupedExpenses[date];

                      if (expenses == null || expenses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Date header
                          RepaintBoundary(
                            child: ExpenseDateHeader(
                              date: date,
                              totalAmount: expenses.fold<double>(
                                0,
                                    (sum, expense) => sum + expense.amount,
                              ),
                            ),
                          ),

                          // Expense items
                          ...expenses.map((expense) {
                            final category = categoryProvider.getCategoryById(expense.categoryId);

                            // Skip if category is not found
                            if (category == null) {
                              return const SizedBox.shrink();
                            }

                            return RepaintBoundary(
                              child: ExpenseListItem(
                                key: ValueKey(expense.id),
                                expense: expense,
                                category: category,
                                onTap: () {
                                  // Show expense details
                                  _showExpenseDetails(context, expense, category);
                                },
                                onLongPress: () {
                                  _showQuickActions(context, expense);
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                    childCount: groupedExpenses.length,
                  ),
                );
              },
            ),

            // Bottom padding for FAB
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  // Show search
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Show filters
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense, Category category) {
    // TODO: Implement expense details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense details coming soon!'),
      ),
    );
  }

  void _showQuickActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsSheet(expense: expense),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class QuickActionsSheet extends StatelessWidget {
  final Expense expense;

  const QuickActionsSheet({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show edit expense sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement duplicate functionality
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<ExpenseProvider>().deleteExpense(expense.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete expense: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}