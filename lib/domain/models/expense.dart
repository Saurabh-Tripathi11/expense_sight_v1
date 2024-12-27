// lib/domain/models/expense.dart
import 'package:flutter/foundation.dart';

@immutable
class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

   Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a copy of the expense with optional new values
  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Convert expense to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Create an expense from a database map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: map['amount'] as double,
      categoryId: map['categoryId'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Expense &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              amount == other.amount &&
              categoryId == other.categoryId &&
              date == other.date &&
              note == other.note &&
              createdAt == other.createdAt &&
              updatedAt == other.updatedAt &&
              isSynced == other.isSynced;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      date.hashCode ^
      note.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isSynced.hashCode;
}