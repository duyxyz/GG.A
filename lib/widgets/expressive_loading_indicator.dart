import 'package:flutter/material.dart';

class ExpressiveLoadingIndicator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    Widget indicator = Image.asset(
      'lib/assets/loading-indicator.gif',
      width: size,
      height: size,
      color: themeColor, // Tints the GIF if possible (works for transparent GIFs)
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.refresh,
        size: size,
        color: themeColor,
      ),
    );

    if (isContained) {
      return Container(
        width: size * 1.5,
        height: size * 1.5,
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
