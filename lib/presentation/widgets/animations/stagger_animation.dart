// lib/presentation/widgets/animations/stagger_animation.dart
import 'package:expense_sight/presentation/widgets/animations/slide_animation.dart';
import 'package:flutter/material.dart';

import 'fade_animation.dart';

class StaggerAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration delay;
  final bool animate;
  final Axis direction;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggerAnimation({
    Key? key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 200),
    this.delay = const Duration(milliseconds: 50),
    this.animate = true,
    this.direction = Axis.vertical,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  State<StaggerAnimation> createState() => _StaggerAnimationState();
}

class _StaggerAnimationState extends State<StaggerAnimation> {
  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: _buildAnimatedChildren(),
    )
        : Row(
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: _buildAnimatedChildren(),
    );
  }

  List<Widget> _buildAnimatedChildren() {
    final children = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      children.add(
        AnimatedBuilder(
          animation: Listenable.merge([]),
          builder: (context, child) {
            return FadeAnimation(
              duration: widget.itemDuration,
              animate: widget.animate,
              delay: widget.delay * i,
              child: SlideAnimation(
                duration: widget.itemDuration,
                animate: widget.animate,
                delay: widget.delay * i,
                begin: const Offset(0, 0.2),
                child: widget.children[i],
              ),
            );
          },
        ),
      );
    }
    return children;
  }
}