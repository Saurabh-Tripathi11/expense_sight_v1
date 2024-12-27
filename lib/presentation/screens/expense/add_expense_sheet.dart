// lib/presentation/screens/expense/add_expense_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/expense/custom_number_pad.dart';
import '../../widgets/expense/category_selector.dart';
import '../../widgets/expense/date_selector.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({Key? key}) : super(key: key);

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amount = '0';
  String _selectedCategoryId = '';
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  void _updateAmount(String value) {
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }

  void _deleteLastDigit() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  Future<void> _saveExpense() async {
    if (_amount == '0' || _selectedCategoryId.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      await context.read<ExpenseProvider>().addExpense(
        amount: double.parse(_amount),
        categoryId: _selectedCategoryId,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Add Expense',
                  style: AppTheme.headline2.copyWith(fontSize: 20),
                ),
                _isProcessing
                    ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                )
                    : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveExpense,
                ),
              ],
            ),
          ),

          // Amount Display
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerRight,
            child: Text(
              '\$$_amount',
              style: AppTheme.headline1.copyWith(
                fontSize: 48,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Category Selector
          CategorySelector(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (categoryId) {
              setState(() => _selectedCategoryId = categoryId);
            },
          ),

          // Date Selector
          DateSelector(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),

          // Note Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Add note (optional)',
                border: UnderlineInputBorder(),
              ),
            ),
          ),

          // Number Pad
          CustomNumberPad(
            onNumberSelected: _updateAmount,
            onDelete: _deleteLastDigit,
          ),
        ],
      ),
    );
  }
}