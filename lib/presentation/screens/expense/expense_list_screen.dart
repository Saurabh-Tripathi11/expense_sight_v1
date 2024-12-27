// lib/presentation/screens/expense/expense_list_screen.dart
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/expense/empty_expense_list.dart';
import '../../widgets/expense/expense_list_item.dart';
import '../../widgets/expense/expense_date_header.dart';
import '../../widgets/expense/quick_actions_sheet.dart';
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

            // Pull to refresh
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await context.read<ExpenseProvider>().refreshExpenses();
              },
            ),

            // Expenses list
            Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, _) {
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
                      final expenses = groupedExpenses[date]!;

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
                            return RepaintBoundary(
                              child: ExpenseListItem(
                                key: ValueKey(expense.id),
                                expense: expense,
                                category: context
                                    .read<CategoryProvider>()
                                    .getCategoryById(expense.categoryId)!,
                                onTap: () {
                                  // Show expense details
                                },
                                onLongPress: () {
                                  // Show quick actions
                                  _showQuickActions(context, expense);
                                },
                              ),
                            );
                          }),
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
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.9),
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

  Widget _buildFAB(BuildContext context) {
    return Hero(
      tag: 'fab_add_expense',
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddExpenseSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
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