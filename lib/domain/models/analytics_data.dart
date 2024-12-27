// lib/domain/models/analytics_data.dart
class AnalyticsData {
  final double totalExpenses;
  final double averagePerDay;
  final Map<String, double> categoryBreakdown;
  final List<DailyExpense> dailyExpenses;
  final DateTime startDate;
  final DateTime endDate;

  AnalyticsData({
    required this.totalExpenses,
    required this.averagePerDay,
    required this.categoryBreakdown,
    required this.dailyExpenses,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalExpenses': totalExpenses,
      'averagePerDay': averagePerDay,
      'categoryBreakdown': categoryBreakdown,
      'dailyExpenses': dailyExpenses.map((e) => e.toJson()).toList(),
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalExpenses: json['totalExpenses'] as double,
      averagePerDay: json['averagePerDay'] as double,
      categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
      dailyExpenses: (json['dailyExpenses'] as List)
          .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
    );
  }
}

class DailyExpense {
  final DateTime date;
  final double amount;
  final Map<String, double> categoryAmounts;

  DailyExpense({
    required this.date,
    required this.amount,
    required this.categoryAmounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'categoryAmounts': categoryAmounts,
    };
  }

  factory DailyExpense.fromJson(Map<String, dynamic> json) {
    return DailyExpense(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      amount: json['amount'] as double,
      categoryAmounts: Map<String, double>.from(json['categoryAmounts']),
    );
  }
}