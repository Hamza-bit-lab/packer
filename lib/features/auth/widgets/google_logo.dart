import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Google "G" mark, drawn in code so the button doesn't need a bundled
/// image asset.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect,
      _rad(-55),
      _rad(95),
      false,
      arcPaint(const Color(0xFF4285F4)),
    );
    canvas.drawArc(
      rect,
      _rad(40),
      _rad(75),
      false,
      arcPaint(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      _rad(115),
      _rad(75),
      false,
      arcPaint(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      _rad(190),
      _rad(130),
      false,
      arcPaint(const Color(0xFFEA4335)),
    );

    // The crossbar that turns the ring into a "G" — sits in the right-middle
    // gap, flush with the blue arc's end.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTWH(
      size.width * 0.5,
      size.height * 0.44,
      size.width * 0.46,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
