import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UnifyGradientPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const UnifyGradientPillButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.authButtonGradient,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2FA0DE).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Text(text, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
