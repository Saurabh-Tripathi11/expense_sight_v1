// lib/presentation/screens/expense/edit_expense_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

class EditExpenseSheet extends StatefulWidget {
  final Expense expense;

  const EditExpenseSheet({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  State<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<EditExpenseSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  late String _amount;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  late TextEditingController _noteController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );

    // Initialize with existing expense data
    _amount = widget.expense.amount.toStringAsFixed(2).replaceAll('.', '');
    _selectedCategoryId = widget.expense.categoryId;
    _selectedDate = widget.expense.date;
    _noteController = TextEditingController(text: widget.expense.note);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateAmount(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else if (_amount.length < 10) {
        _amount += value;
      }
    });
  }

  void _deleteLastDigit() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  bool get _canSave {
    final newAmount = double.parse(_amount) / 100;
    return newAmount > 0 && _selectedCategoryId.isNotEmpty;
  }

  Future<void> _saveExpense() async {
    if (!_canSave) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final updatedExpense = widget.expense.copyWith(
        amount: double.parse(_amount) / 100,
        categoryId: _selectedCategoryId,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      await context.read<ExpenseProvider>().updateExpense(updatedExpense);

      if (mounted) {
        await _animationController.reverse();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildAmountDisplay(),
                    Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                    _buildCategorySelector(),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildDateSelector(),
                    _buildNoteField(),
                  ],
                ),
              ),
              Divider(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              Expanded(
                flex: 3,
                child: _buildNumberPad(),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              await _animationController.reverse();
              if (mounted) Navigator.pop(context);
            },
          ),
          const Text(
            'Edit Expense',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          _isProcessing
              ? const SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: Icon(
              Icons.check,
              color: _canSave
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
            onPressed: _canSave ? _saveExpense : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '\$${(double.parse(_amount) / 100).toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == _selectedCategoryId;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = category.id);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color
                              : category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            category.icon,
                            style: TextStyle(
                              fontSize: 24,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? category.color : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      leading: const Icon(Icons.calendar_today, size: 20),
      title: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
    );
  }

  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'Add note (optional)',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.note, size: 20),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: [
        _buildNumberKey('1'),
        _buildNumberKey('2'),
        _buildNumberKey('3'),
        _buildNumberKey('4'),
        _buildNumberKey('5'),
        _buildNumberKey('6'),
        _buildNumberKey('7'),
        _buildNumberKey('8'),
        _buildNumberKey('9'),
        _buildNumberKey('00'),
        _buildNumberKey('0'),
        _buildDeleteKey(),
      ],
    );
  }

  Widget _buildNumberKey(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateAmount(number),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _deleteLastDigit,
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => _amount = '0');
        },
        child: const Center(
          child: Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }
}