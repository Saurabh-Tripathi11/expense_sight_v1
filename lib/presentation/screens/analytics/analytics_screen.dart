// lib/presentation/screens/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildOverviewTab() {
    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, _) {
        return FutureBuilder<Map<String, double>>(
          future: expenseProvider.getExpenseStatistics(
            start: _startDate,
            end: _endDate,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  title: 'Total Expenses',
                  value: '\${stats['total']?.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.account_balance_wallet,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Daily Average',
                  value: '\${stats['average_per_day']?.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.trending_up,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Largest Expense',
                  value: '\${stats['max_single_expense']?.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.arrow_upward,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, _) {
        return FutureBuilder<List<Expense>>(
          future: expenseProvider.getExpensesForDateRange(
            _startDate,
            _endDate,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = snapshot.data!;
            final categoryStats = categoryProvider.getCategoryStatistics(expenses);
            final totalAmount = categoryStats.values.fold<double>(
              0,
                  (sum, amount) => sum + amount,
            );

            final items = categoryStats.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final entry = items[index];
                final category = categoryProvider.getCategoryById(entry.key)!;
                final percentage = totalAmount > 0
                    ? (entry.value / totalAmount * 100)
                    : 0.0;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<Expense>>(
          future: provider.getExpensesForDateRange(
            _startDate,
            _endDate,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Build trend chart here
            return const Center(
              child: Text('Trends coming soon!'),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }