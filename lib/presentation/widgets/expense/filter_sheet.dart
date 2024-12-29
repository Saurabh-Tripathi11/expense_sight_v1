
// lib/presentation/widgets/expense/filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../providers/search_filter_provider.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({Key? key}) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ExpenseFilter _currentFilter;
  late ExpenseSortOption _currentSortOption;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SearchFilterProvider>();
    _currentFilter = provider.filter;
    _currentSortOption = provider.sortOption;
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDateRangeSection(),
                const Divider(),
                _buildSortSection(),
                const Divider(),
                _buildAmountRangeSection(),
                const Divider(),
                _buildCategorySection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _currentFilter.startDate != null
                      ? DateFormat('MMM d, y').format(_currentFilter.startDate!)
                      : 'Start Date',
                ),
                onPressed: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _currentFilter.endDate != null
                      ? DateFormat('MMM d, y').format(_currentFilter.endDate!)
                      : 'End Date',
                ),
                onPressed: () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExpenseSortOption.values.map((option) {
            String label;
            switch (option) {
              case ExpenseSortOption.dateDesc:
                label = 'Latest First';
                break;
              case ExpenseSortOption.dateAsc:
                label = 'Oldest First';
                break;
              case ExpenseSortOption.amountDesc:
                label = 'Highest Amount';
                break;
              case ExpenseSortOption.amountAsc:
                label = 'Lowest Amount';
                break;
            }

            return ChoiceChip(
              label: Text(label),
              selected: _currentSortOption == option,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _currentSortOption = option);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      minAmount: double.tryParse(value),
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      maxAmount: double.tryParse(value),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categoryProvider.categories.map((category) {
                return FilterChip(
                  label: Text(category.name),
                  selected: _currentFilter.categoryIds.contains(category.id),
                  onSelected: (selected) {
                    setState(() {
                      final List<String> newCategories = List.from(_currentFilter.categoryIds);
                      if (selected) {
                        newCategories.add(category.id);
                      } else {
                        newCategories.remove(category.id);
                      }
                      _currentFilter = _currentFilter.copyWith(categoryIds: newCategories);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _currentFilter.startDate ?? DateTime.now() : _currentFilter.endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      setState(() {
        _currentFilter = _currentFilter.copyWith(
          startDate: isStartDate ? date : _currentFilter.startDate,
          endDate: isStartDate ? _currentFilter.endDate : date,
        );
      });
    }
  }

  void _applyFilters() {
    final provider = context.read<SearchFilterProvider>();
    provider.setFilter(_currentFilter);
    provider.setSortOption(_currentSortOption);
    Navigator.pop(context);
  }
}