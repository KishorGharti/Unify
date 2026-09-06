import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AlgoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool hasGradient;

  const AlgoraCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spaceLg),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.hasGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final decoration = BoxDecoration(
      color: hasGradient ? null : (backgroundColor ?? defaultBg),
      gradient: hasGradient ? (isDark ? AppColors.darkCardGradient : null) : null,
      borderRadius: AppDimensions.roundedLg,
      border: Border.all(
        color: borderColor ?? defaultBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    // Always give descendants a local Material to paint on - not just when
    // the card itself is tappable. A card that isn't tappable but wraps
    // tappable children (e.g. a Column of ListTiles) still needs one, or
    // their ink splashes/backgrounds render on whatever Material ancestor
    // happens to be further up the tree instead, hidden behind this card's
    // own DecoratedBox.
    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppDimensions.roundedLg,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimensions.roundedLg,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
