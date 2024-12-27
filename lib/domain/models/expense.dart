// lib/domain/models/expense.dart
// class Expense {
//   final String id;
//   final double amount;
//   final DateTime date;
//   final String categoryId;
//   final String? note;
//
//   Expense({
//     required this.id,
//     required this.amount,
//     required this.date,
//     required this.categoryId,
//     this.note,
//   });
// }
class Expense {
  final String id;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? note;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}