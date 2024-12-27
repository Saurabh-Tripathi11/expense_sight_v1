// lib/domain/entities/category.dart
import 'package:flutter/material.dart';

@immutable
class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final String? parentId;
  final bool isSystem;
  final DateTime createdAt;

   Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    this.isSystem = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    String? name,
    String? icon,
    Color? color,
    String? parentId,
    bool? isSystem,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'parentId': parentId,
      'isSystem': isSystem ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: Color(map['color'] as int),
      parentId: map['parentId'] as String?,
      isSystem: (map['isSystem'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Category &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              icon == other.icon &&
              color == other.color &&
              parentId == other.parentId &&
              isSystem == other.isSystem &&
              createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      color.hashCode ^
      parentId.hashCode ^
      isSystem.hashCode ^
      createdAt.hashCode;
}
