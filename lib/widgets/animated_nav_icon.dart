import 'package:flutter/material.dart';

class AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color? color;

  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // value 0 -> 1
        // scale from 1.0 to 1.3
        final scale = 1.0 + (value * 0.25);
        // rotation from 0 to 15 degrees
        // final rotation = value * 0.2; 

        return Transform.scale(
          scale: scale,
          child: Icon(
            icon,
            color: color ?? (isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant),
            size: 24,
          ),
        );
      },
    );
  }
}
