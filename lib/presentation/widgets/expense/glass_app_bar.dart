// lib/presentation/widgets/expense/glass_app_bar.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class GlassAppBar extends StatelessWidget {
  final Widget title;
  final List<Widget>? actions;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      title: title,
      actions: actions,
    );
  }
}