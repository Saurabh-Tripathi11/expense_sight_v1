// lib/presentation/widgets/expense/expense_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_bag,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          expense.note ?? 'No description',
          style: AppTheme.subtitle1,
        ),
        subtitle: Text(
          expense.date.hour == 0 && expense.date.minute == 0
              ? 'All day'
              : '${expense.date.hour.toString().padLeft(2, '0')}:${expense.date.minute.toString().padLeft(2, '0')}',
          style: AppTheme.subtitle1.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        trailing: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: AppTheme.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}