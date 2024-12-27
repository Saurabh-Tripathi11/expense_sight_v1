// lib/presentation/screens/category/category_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/category.dart';
import '../../providers/category_provider.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategory(context),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = provider.categories;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryListItem(category: category);
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddCategory(BuildContext context) async {
    final provider = context.read<CategoryProvider>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );

    if (result != null) {
      await provider.addCategory(
        name: result['name'],
        icon: result['icon'],
        color: result['color'],
      );
    }
  }
}

class _CategoryListItem extends StatelessWidget {
  final Category category;

  const _CategoryListItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      trailing: category.isSystem
          ? const Chip(label: Text('System'))
          : IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showEditCategory(context),
      ),
    );
  }

  Future<void> _showEditCategory(BuildContext context) async {
    if (category.isSystem) return;

    final provider = context.read<CategoryProvider>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddCategoryDialog(
        initialCategory: category,
      ),
    );

    if (result != null) {
      final updatedCategory = category.copyWith(
        name: result['name'],
        icon: result['icon'],
        color: result['color'],
      );
      await provider.updateCategory(updatedCategory);
    }
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final Category? initialCategory;

  const _AddCategoryDialog({
    Key? key,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  late final TextEditingController _nameController;
  String _selectedIcon = '🏷️';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory?.name,
    );
    _selectedIcon = widget.initialCategory?.icon ?? '🏷️';
    _selectedColor = widget.initialCategory?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialCategory == null
          ? 'Add Category'
          : 'Edit Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter category name',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                onPressed: () => _showIconPicker(context),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                onPressed: () => _showColorPicker(context),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'icon': _selectedIcon,
              'color': _selectedColor,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _showIconPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Icon'),
        children: CategoryProvider.availableIcons
            .map((icon) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, icon),
          child: Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
        ))
            .toList(),
      ),
    );

    if (result != null) {
      setState(() => _selectedIcon = result);
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Color'),
        children: CategoryProvider.recommendedColors
            .map((color) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, color),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ))
            .toList(),
      ),
    );

    if (result != null) {
      setState(() => _selectedColor = result);
    }
  }
}