// File: lib/presentation/screens/analytics/components/summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final double? trend;
  final Color? backgroundColor;
  final Color? iconColor;
  final Widget? customContent; // Add this line

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend,
    this.backgroundColor,
    this.iconColor,
    this.customContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Value and Trend
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: trend! >= 0 ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: trend! >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCardGrid extends StatelessWidget {
  final List<Widget> cards;
  final int crossAxisCount;
  final double spacing;
  final EdgeInsets padding;

  const SummaryCardGrid({
    Key? key,
    required this.cards,
    this.crossAxisCount = 2,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.5,
        children: cards,
      ),
    );
  }
}

// Example Usage:
// SummaryCardGrid(
//   cards: [
//     SummaryCard(
//       title: 'Total Expenses',
//       value: 1234.56,
//       icon: Icons.account_balance_wallet,
//       trend: 12.5,
//     ),
//     SummaryCard(
//       title: 'Daily Average',
//       value: 45.67,
//       icon: Icons.trending_up,
//     ),
//   ],
// ),