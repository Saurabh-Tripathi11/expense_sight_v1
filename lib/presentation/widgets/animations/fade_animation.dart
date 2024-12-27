// lib/presentation/widgets/animations/fade_animation.dart
import 'package:flutter/material.dart';

class FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  final bool animate;
  final double begin;
  final double end;

  const FadeAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay,
    this.curve = Curves.easeOut,
    this.animate = true,
    this.begin = 0.0,
    this.end = 1.0,
  }) : super(key: key);

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate) {
      if (widget.delay != null) {
        Future.delayed(widget.delay!, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (widget.delay != null) {
          Future.delayed(widget.delay!, () {
            if (mounted) {
              _controller.forward();
            }
          });
        } else {
          _controller.forward();
        }
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}