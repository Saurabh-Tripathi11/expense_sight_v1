// lib/presentation/widgets/expense/quick_actions_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../screens/expense/edit_expense_sheet.dart';

class QuickActionsSheet extends StatelessWidget {
  final Expense expense;

  const QuickActionsSheet({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Edit Action
          ListTile(
            leading: Icon(
              Icons.edit,
              color: isDark ? Colors.white : Colors.black,
            ),
            title: Text(
              'Edit Expense',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showEditExpenseSheet(context);
            },
          ),

          // Delete Action
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Expense',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _deleteExpense(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditExpenseSheet(expense: expense),
    );
  }

  Future<void> _deleteExpense(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        print('Starting expense deletion process'); // Debug print
        final expenseProvider = Provider.of<ExpenseProvider>(
          context,
          listen: false,
        );

        print('Deleting expense: ${expense.id}'); // Debug print
        await expenseProvider.deleteExpense(expense.id);
        print('Delete operation completed'); // Debug print

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error during deletion: $e'); // Debug print
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete expense: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}