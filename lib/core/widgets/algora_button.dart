import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

enum AlgoraButtonVariant { primary, secondary, outline, danger, ghost, gradient }

class AlgoraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AlgoraButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AlgoraButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.variant = AlgoraButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _getTextColor(isDark)),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: AppTypography.button(color: _getTextColor(isDark)),
        ),
      ],
    );

    if (variant == AlgoraButtonVariant.gradient) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppDimensions.roundedLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppDimensions.roundedLg,
            onTap: isLoading ? null : onPressed,
            child: Center(child: child),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: _getButtonStyle(isDark),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }

  Color _getTextColor(bool isDark) {
    switch (variant) {
      case AlgoraButtonVariant.primary:
      case AlgoraButtonVariant.gradient:
      case AlgoraButtonVariant.danger:
        return Colors.white;
      case AlgoraButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case AlgoraButtonVariant.outline:
      case AlgoraButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  ButtonStyle _getButtonStyle(bool isDark) {
    switch (variant) {
      case AlgoraButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
          elevation: 2,
        );
      case AlgoraButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightInputBg,
          foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
          elevation: 0,
        );
      case AlgoraButtonVariant.outline:
        return OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
          elevation: 0,
        );
      case AlgoraButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
          elevation: 0,
        );
      case AlgoraButtonVariant.ghost:
        return TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
        );
      case AlgoraButtonVariant.gradient:
        return ElevatedButton.styleFrom();
    }
  }
}
