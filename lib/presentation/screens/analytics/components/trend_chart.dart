import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/analytics_data.dart';

class TrendChart extends StatelessWidget {
  final List<ExpenseTrend> trends;

  const TrendChart({
    Key? key,
    required this.trends,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(
        child: Text('No expense data available for the selected period'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.grey[700];
    final lineColor = isDark ? Colors.lightBlue[300]! : Theme.of(context).primaryColor;

    // Sort trends by date
    final sortedTrends = List<ExpenseTrend>.from(trends)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create spots for all dates
    final spots = sortedTrends.map((trend) => FlSpot(
      trend.date.millisecondsSinceEpoch.toDouble(),
      trend.amount,
    )).toList();

    // Find max value for Y axis (minimum will be 0)
    double maxY = trends.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    maxY = maxY * 1.1; // Add 10% padding

    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 8, bottom: 32), // Increased bottom padding
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: isDark ? Colors.grey[800]! : lineColor.withOpacity(0.8),
              fitInsideHorizontally: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  return LineTooltipItem(
                    DateFormat('MMM d, y').format(date),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '\n\$${spot.y.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: (isDark ? Colors.white : Colors.grey).withOpacity(0.15),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42, // Increased reserved size for labels
                interval: _calculateDateInterval(sortedTrends),
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 12, // Added space between label and axis
                    child: Text(
                      _formatDateLabel(date, sortedTrends),
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 10, // Slightly smaller font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      NumberFormat.compactCurrency(symbol: '\$').format(value),
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                interval: maxY / 5,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final radius = spot.y == 0 ? 3.0 : 4.0;
                  return FlDotCirclePainter(
                    radius: radius,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0.3),
                    lineColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime date, List<ExpenseTrend> trends) {
    final totalDays = trends.last.date.difference(trends.first.date).inDays;

    if (totalDays > 365) {
      // For more than a year, just show month and year initials
      return DateFormat('MMM y').format(date).substring(0, 6);
    } else if (totalDays > 180) {
      // For 6+ months, show short month name
      return DateFormat('MMM').format(date).substring(0, 3);
    } else if (totalDays > 60) {
      // For 2-6 months, show month initial
      return DateFormat('MMM').format(date).substring(0, 1);
    } else if (totalDays > 30) {
      // For 1-2 months, show month/day
      return DateFormat('M/d').format(date);
    } else if (totalDays > 7) {
      // For week to month, show day
      return DateFormat('d').format(date);
    } else {
      // For a week or less, show weekday initial
      return DateFormat('E').format(date).substring(0, 1);
    }
  }

  double _calculateDateInterval(List<ExpenseTrend> trends) {
    if (trends.length <= 1) return 24 * 60 * 60 * 1000;

    final totalDays = trends.last.date.difference(trends.first.date).inDays;
    final millisecondsInDay = 24 * 60 * 60 * 1000;

    // Dynamic interval based on the date range
    if (totalDays > 365) {
      return (60 * millisecondsInDay).toDouble(); // Every 2 months for > 1 year
    } else if (totalDays > 180) {
      return (45 * millisecondsInDay).toDouble(); // Every 1.5 months for > 6 months
    } else if (totalDays > 90) {
      return (30 * millisecondsInDay).toDouble(); // Monthly for 3-6 months
    } else if (totalDays > 60) {
      return (15 * millisecondsInDay).toDouble(); // Bi-weekly for 2-3 months
    } else if (totalDays > 30) {
      return (7 * millisecondsInDay).toDouble(); // Weekly for 1-2 months
    } else if (totalDays > 7) {
      return (3 * millisecondsInDay).toDouble(); // Every 3 days for week-month
    } else {
      return millisecondsInDay.toDouble(); // Daily for <= week
    }
  }
}