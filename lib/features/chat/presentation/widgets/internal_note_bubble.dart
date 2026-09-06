import 'package:flutter/material.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/date_formatter.dart';
import 'package:algora/features/chat/data/models/message_model.dart';

class InternalNoteBubble extends StatelessWidget {
  final MessageModel message;

  const InternalNoteBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.internalNoteBgDark : AppColors.internalNoteBg;
    final textColor = isDark ? AppColors.internalNoteTextDark : AppColors.internalNoteText;
    final borderColor = isDark ? AppColors.internalNoteBorderDark : AppColors.internalNoteBorder;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimensions.roundedLg,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                'Internal Note by ${message.senderName}',
                style: AppTypography.badge(color: textColor).copyWith(fontSize: 11),
              ),
              const Spacer(),
              Text(
                DateFormatter.formatMessageTime(message.createdAt),
                style: AppTypography.caption(color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: AppTypography.body1(color: textColor),
          ),
        ],
      ),
    );
  }
}
