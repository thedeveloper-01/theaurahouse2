import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavyBackground extends StatelessWidget {
  final Widget child;
  final Color? waveColor;

  const WavyBackground({super.key, required this.child, this.waveColor});

  @override
  Widget build(BuildContext context) {
    final color = waveColor ?? Colors.white;

    return Stack(
      children: [
        // Dark background
        Container(color: Colors.black),
        // Wavy shape - positioned behind title area
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 120),
            painter: WavyPainter(color: color),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class WavyPainter extends CustomPainter {
  final Color color;

  WavyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 50.0;
    final waveLength = size.width / 1.5;

    // Start from top left
    path.moveTo(0, size.height * 0.3);

    // Create wavy pattern
    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final y =
          size.height * 0.3 +
          waveHeight * math.sin((i / waveLength) * 2 * math.pi);
      path.lineTo(x, y);
    }

    // Complete the shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
