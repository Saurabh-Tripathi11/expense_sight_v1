// lib/presentation/widgets/animations/slide_animation.dart
import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  final Offset begin;
  final Offset end;
  final bool animate;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay,
    this.curve = Curves.easeOutQuad,
    this.begin = const Offset(0, 1),
    this.end = Offset.zero,
    this.animate = true,
  }) : super(key: key);

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<Offset>(
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
  void didUpdateWidget(SlideAnimation oldWidget) {
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
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}