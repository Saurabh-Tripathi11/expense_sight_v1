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
    if (_amount == '0') {
      _showErrorDialog('Invalid Amount', 'Please enter an amount greater than 0');
      return;
    }

    if (_selectedCategoryId == null) {
      _showErrorDialog('Category Required', 'Please select a category for your expense');
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      // Convert amount string to actual decimal value
      final double actualAmount = double.parse(_amount) / 100; // Convert to decimal

      await context.read<ExpenseProvider>().addExpense(
        amount: actualAmount,
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

  void _showErrorDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

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
          padding: EdgeInsets.only(top: MediaQuery
              .of(context)
              .padding
              .top),
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
              SizedBox(height: MediaQuery
                  .of(context)
                  .padding
                  .bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () async {
              await _animationController.reverse();
              if (mounted) Navigator.pop(context);
            },
          ),
          Text(
            'Add Expense',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
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
              color: isDark ? Colors.grey[400] : Colors.grey[800],
            ),
            onPressed: _saveExpense, // Remove the _canSave check here
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Convert string amount to display format
    String formattedAmount = '';
    if (_amount.length <= 2) {
      formattedAmount = '0.${_amount.padLeft(2, '0')}';
    } else {
      final wholeNumber = _amount.substring(0, _amount.length - 2);
      final decimal = _amount.substring(_amount.length - 2);
      formattedAmount = '$wholeNumber.$decimal';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$$formattedAmount',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
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
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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

        return Padding(
          padding: const EdgeInsets.only(top: 16), // Added top padding
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == _selectedCategoryId;

                return Padding(
                  padding: const EdgeInsets.all(4),
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
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected ? category.color : Colors
                                .grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.calendar_today,
        size: 20,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      title: Text(
        DateFormat('EEEE, MMMM d').format(_selectedDate),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: isDark
                  ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  surface: Color(0xFF1E1E1E),
                ),
              )
                  : ThemeData.light(),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
    );
  }

  Widget _buildNoteField() {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: 'Add note (optional)',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.note,
            size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
        maxLines: 1,
        textInputAction: TextInputAction.done,
      ),
    );
  }


// Update the NumberPad to use a smaller aspect ratio
  Widget _buildNumberPad() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2.0,
      // Increased aspect ratio to make buttons shorter
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
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateAmount(number),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _deleteLastDigit,
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => _amount = '0');
        },
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}