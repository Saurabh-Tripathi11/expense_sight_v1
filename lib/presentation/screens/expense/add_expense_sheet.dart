// lib/presentation/screens/expense/add_expense_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({Key? key}) : super(key: key);

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  String _amount = '0';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
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
      } else if (_amount.length < 10) { // Prevent too large numbers
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
    return _amount != '0' && _selectedCategoryId != null;
  }

  Future<void> _saveExpense() async {
    if (!_canSave) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      await context.read<ExpenseProvider>().addExpense(
        amount: double.parse(_amount),
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildAmountDisplay(),
                const Divider(),
                _buildCategorySelector(),
                _buildDateSelector(),
                _buildNoteField(),
                const Divider(),
                _buildNumberPad(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _animationController.reverse();
              if (mounted) Navigator.pop(context);
            },
          ),
          const Text(
            'Add Expense',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          _isProcessing
              ? const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          )
              : IconButton(
            icon: Icon(
              Icons.check,
              color: _canSave ? Colors.blue : Colors.grey,
            ),
            onPressed: _canSave ? _saveExpense : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final formattedAmount = '\$${_formatAmount(_amount)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            formattedAmount,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedCategoryId != null) ...[
            const SizedBox(height: 8),
            Consumer<CategoryProvider>(
              builder: (context, provider, _) {
                final category = provider.getCategoryById(_selectedCategoryId!);
                return Text(
                  category?.name ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    if (amount.length > 2) {
      final decimalStr = amount.substring(amount.length - 2);
      final wholeStr = amount.substring(0, amount.length - 2);
      return '$wholeStr.$decimalStr';
    }
    return '0.${amount.padLeft(2, '0')}';
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
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = category.id);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color
                              : category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
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
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? category.color : Colors.grey[600],
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
      leading: const Icon(Icons.calendar_today),
      title: Text(
        DateFormat('EEEE, MMMM d').format(_selectedDate),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'Add note (optional)',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.note),
        ),
        maxLines: 1,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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