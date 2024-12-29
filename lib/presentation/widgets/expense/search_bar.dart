// lib/presentation/widgets/expense/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/search_filter_provider.dart';

class ExpenseSearchBar extends StatefulWidget {
  const ExpenseSearchBar({Key? key}) : super(key: key);

  @override
  State<ExpenseSearchBar> createState() => _ExpenseSearchBarState();
}

class _ExpenseSearchBarState extends State<ExpenseSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SearchFilterProvider>(
      builder: (context, provider, _) {
        if (!provider.isSearchActive) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: _searchController,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              textBaseline: TextBaseline.alphabetic,
            ),
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                  provider.toggleSearch();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (value) {
              provider.setSearchQuery(value);
            },
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\u200E\u200F]')),
            ],
          ),
        );
      },
    );
  }
}