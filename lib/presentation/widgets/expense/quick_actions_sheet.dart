// lib/presentation/widgets/expense/quick_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';

class QuickActionsSheet extends StatelessWidget {
  final Expense expense;

  const QuickActionsSheet({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          _buildActionItem(
            context,
            icon: Icons.edit,
            label: 'Edit',
            onTap: () {
              Navigator.pop(context);
              // Show edit expense sheet
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.content_copy,
            label: 'Duplicate',
            onTap: () {
              Navigator.pop(context);
              // Duplicate expense
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.delete,
            label: 'Delete',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    final color = isDestructive ? Colors.red : Colors.black;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
              ),
            ),
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

    if (confirmed == true) {
      // Delete expense
      context.read<ExpenseProvider>().deleteExpense(expense.id);
    }
  }
}