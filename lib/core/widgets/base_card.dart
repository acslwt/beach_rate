import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// White surface with soft shadow and rounded corners.
/// Use for every overlay panel: dropdown, results, pills.
class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: appCream,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
