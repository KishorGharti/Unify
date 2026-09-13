import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class UnifyBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double? fontSize;
  final EdgeInsetsGeometry padding;

  const UnifyBadge({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDimensions.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.badge(color: textColor).copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
