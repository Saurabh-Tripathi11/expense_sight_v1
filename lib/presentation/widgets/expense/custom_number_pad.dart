import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CustomNumberPad extends StatelessWidget {
  final Function(String) onNumberSelected;
  final VoidCallback onDelete;

  const CustomNumberPad({
    Key? key,
    required this.onNumberSelected,
    required this.onDelete,
  }) : super(key: key);

  void _handleTap(String value) {
    HapticFeedback.lightImpact();
    onNumberSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildRow(['', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((value) {
        if (value.isEmpty) return const SizedBox(width: 80, height: 80);

        return SizedBox(
          width: 80,
          height: 80,
          child: TextButton(
            onPressed: () {
              if (value == 'del') {
                onDelete();
              } else {
                _handleTap(value);
              }
            },
            child: value == 'del'
                ? const Icon(Icons.backspace_outlined)
                : Text(
              value,
              style: AppTheme.headline1.copyWith(fontSize: 28),
            ),
          ),
        );
      }).toList(),
    );
  }
}
