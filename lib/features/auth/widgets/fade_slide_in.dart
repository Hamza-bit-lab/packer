import 'package:flutter/material.dart';

/// One-shot fade + slide-up entrance; [delay] staggers widgets.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 450);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    final totalMicros =
        _animationDuration.inMicroseconds + widget.delay.inMicroseconds;
    final delayFraction = totalMicros == 0
        ? 0.0
        : widget.delay.inMicroseconds / totalMicros;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(microseconds: totalMicros),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayFraction, 1.0, curve: Curves.easeOut),
    );
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
