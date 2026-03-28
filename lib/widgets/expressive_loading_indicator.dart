import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExpressiveLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final bool isContained;

  const ExpressiveLoadingIndicator({
    super.key,
    this.size = 48.0,
    this.color,
    this.isContained = false,
  });

  @override
  State<ExpressiveLoadingIndicator> createState() => _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).colorScheme.primary;

    Widget indicator = RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ExpressiveStarPainter(color: themeColor),
      ),
    );

    if (widget.isContained) {
      return Container(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(child: indicator),
      );
    }

    return indicator;
  }
}

class _ExpressiveStarPainter extends CustomPainter {
  final Color color;

  _ExpressiveStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.75;
    const pointsCount = 12;

    final path = Path();
    const angleStep = (2 * math.pi) / (pointsCount * 2);

    for (int i = 0; i < pointsCount * 2; i++) {
      final isOuter = i % 2 == 0;
      final radius = isOuter ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use quadraticBezierTo for smoothing
        final prevAngle = (i - 1) * angleStep - math.pi / 2;
        final prevRadius = !isOuter ? outerRadius : innerRadius;
        final prevX = center.dx + prevRadius * math.cos(prevAngle);
        final prevY = center.dy + prevRadius * math.sin(prevAngle);

        final midAngle = (i - 0.5) * angleStep - math.pi / 2;
        // Adjust control point to create the "clover" rounded look
        final controlRadius = (outerRadius + innerRadius) / 2 * 1.1;
        final cx = center.dx + controlRadius * math.cos(midAngle);
        final cy = center.dy + controlRadius * math.sin(midAngle);

        path.quadraticBezierTo(cx, cy, x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpressiveStarPainter oldDelegate) =>
      color != oldDelegate.color;
}
