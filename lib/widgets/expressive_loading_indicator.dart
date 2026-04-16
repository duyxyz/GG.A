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
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      child: Image.asset(
        'lib/assets/loading-indicator.png',
        width: widget.size,
        height: widget.size,
        color: themeColor,
        colorBlendMode: BlendMode.srcIn,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.refresh, size: widget.size, color: themeColor),
      ),
    );

    if (widget.isContained) {
      return Container(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(child: indicator),
      );
    }

    return indicator;
  }
}
