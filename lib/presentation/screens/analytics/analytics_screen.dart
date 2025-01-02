// File: lib/presentation/screens/analytics/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/analytics_data.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/category_provider.dart';
import 'components/summary_card.dart';
import 'components/trend_chart.dart';
import 'components/category_distribution.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule the load after the build
    Future.microtask(() {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AnalyticsProvider>(context, listen: false);
    await provider.loadAnalytics(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final summary = provider.summary;
          if (summary == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: isDark ? Colors.grey[400] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available for this period',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text('Change Date Range'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date Range Display
                _buildDateRangeChip(),
                const SizedBox(height: 16),

                // Summary Cards
                _buildSummaryCards(summary),
                const SizedBox(height: 24),

                // Trend Chart Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expense Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: TrendChart(trends: provider.trends),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Category Distribution
                CategoryDistributionChart(
                  categories: provider.categoryAnalytics,
                ),
                // Add extra padding at bottom for better scrolling experience
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeChip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        onSelected: (_) => _selectDateRange(context),
        selected: false,
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    final categoryProvider = context.read<CategoryProvider>();
    final topCategoryName = categoryProvider
        .getCategoryById(summary.topCategory)
        ?.name ?? 'Unknown';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Expenses',
                value: summary.totalExpenses,
                icon: Icons.account_balance_wallet,
                trend: summary.monthlyChange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: 'Daily Average',
                value: summary.dailyAverage,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SummaryCard(
          title: 'Most Spent Category',
          value: 0, // This will be hidden
          icon: Icons.category,
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topCategoryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Highest spending category this period',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            colorScheme: ColorScheme(
              primary: AppTheme.primaryColor,
              primaryContainer: AppTheme.primaryColor,
              secondary: AppTheme.accentColor,
              secondaryContainer: AppTheme.accentColor,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              background: isDark ? const Color(0xFF121212) : Colors.white,
              error: Colors.red,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
              onBackground: isDark ? Colors.white : Colors.black,
              onError: Colors.white,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            dialogBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }
}