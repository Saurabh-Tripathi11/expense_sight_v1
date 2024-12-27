// lib/presentation/providers/category_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../../data/database/database_helper.dart';
import '../../domain/models/expense.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _db;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();

  // Default categories with emojis and colors
  static final List<Category> _defaultCategories = [
    Category(
      id: 'food',
      name: 'Food & Dining',
      icon: '🍽️',
      color: Colors.orange,
      isSystem: true,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: '🚗',
      color: Colors.blue,
      isSystem: true,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛍️',
      color: Colors.purple,
      isSystem: true,
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      icon: '💡',
      color: Colors.green,
      isSystem: true,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎮',
      color: Colors.red,
      isSystem: true,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: '🏥',
      color: Colors.pink,
      isSystem: true,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: '📚',
      color: Colors.indigo,
      isSystem: true,
    ),
    Category(
      id: 'housing',
      name: 'Housing',
      icon: '🏠',
      color: Colors.brown,
      isSystem: true,
    ),
    // Add more default categories as needed
  ];

  CategoryProvider(this._db) {
    _initializeCategories();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Category> get categories => List.unmodifiable(_categories);

  // Initialize categories and ensure defaults exist
  Future<void> _initializeCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load existing categories
      _categories = await _db.getAllCategories();

      // Add default categories if they don't exist
      if (_categories.isEmpty) {
        for (final category in _defaultCategories) {
          await _db.insertCategory(category);
        }
        _categories = await _db.getAllCategories();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize categories: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new category
  Future<void> addCategory({
    required String name,
    required String icon,
    required Color color,
    String? parentId,
  }) async {
    try {
      final category = Category(
        id: _uuid.v4(),
        name: name,
        icon: icon,
        color: color,
        parentId: parentId,
      );

      await _db.insertCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add category: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Update existing category
  Future<void> updateCategory(Category category) async {
    try {
      if (category.isSystem) {
        throw Exception('Cannot modify system category');
      }

      await _db.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update category: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final category = _categories.firstWhere((c) => c.id == id);
      if (category.isSystem) {
        throw Exception('Cannot delete system category');
      }

      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get parent categories
  List<Category> getParentCategories() {
    return _categories.where((c) => c.parentId == null).toList();
  }

  // Get child categories
  List<Category> getChildCategories(String parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  // Get all available icons
  static const List<String> availableIcons = [
    '🍽️', '🚗', '🛍️', '💡', '🎮', '🏥', '📚', '🏠',
    '✈️', '🎵', '🎨', '💼', '🏋️', '🎁', '💪', '🎭',
    '🚌', '🍺', '☕', '🎬', '📱', '💇', '🏦', '⚽',
    '🎪', '🎤', '📷', '🎲', '🛠️', '🧺', '🎨', '🎹'
  ];

  // Get recommended colors
  static const List<Color> recommendedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  // Get category statistics
  Map<String, double> getCategoryStatistics(List<Expense> expenses) {
    final Map<String, double> stats = {};

    for (final category in _categories) {
      final categoryExpenses = expenses.where((e) => e.categoryId == category.id);
      final total = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      stats[category.id] = total;
    }

    return stats;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset to default categories
  Future<void> resetToDefaults() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Delete all non-system categories
      for (final category in _categories) {
        if (!category.isSystem) {
          await _db.deleteCategory(category.id);
        }
      }

      // Reload categories
      await _initializeCategories();

    } catch (e) {
      _error = 'Failed to reset categories: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Export categories as JSON
  Map<String, dynamic> exportAsJson() {
    return {
      'categories': _categories.map((c) => c.toMap()).toList(),
    };
  }

  // Import categories from JSON
  Future<void> importFromJson(Map<String, dynamic> json) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final List<dynamic> categoriesJson = json['categories'];
      final List<Category> newCategories = categoriesJson
          .map((json) => Category.fromMap(json as Map<String, dynamic>))
          .toList();

      // Clear existing non-system categories
      for (final category in _categories) {
        if (!category.isSystem) {
          await _db.deleteCategory(category.id);
        }
      }

      // Add new categories
      for (final category in newCategories) {
        if (!category.isSystem) {
          await _db.insertCategory(category);
        }
      }

      await _initializeCategories();

    } catch (e) {
      _error = 'Failed to import categories: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}