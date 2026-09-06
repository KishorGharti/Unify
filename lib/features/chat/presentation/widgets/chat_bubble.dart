import 'package:flutter/material.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/date_formatter.dart';
import 'package:algora/features/chat/data/models/message_model.dart';
import 'internal_note_bubble.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isPreviousSameSender;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isPreviousSameSender = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.messageType == MessageType.internalNote) {
      return InternalNoteBubble(message: message);
    }

    final isAgent = message.senderType == MessageSenderType.agent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isAgent
        ? AppColors.primary
        : (isDark ? AppColors.darkCard : AppColors.lightSurface);
    final textColor = isAgent
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final timeColor = isAgent
        ? Colors.white.withOpacity(0.7)
        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    return Padding(
      padding: EdgeInsets.only(
        top: isPreviousSameSender ? 3 : 10,
        bottom: 2,
        left: isAgent ? 48 : 12,
        right: isAgent ? 12 : 48,
      ),
      child: Column(
        crossAxisAlignment: isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isPreviousSameSender && !isAgent) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName,
                style: AppTypography.caption(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAgent ? 16 : 4),
                bottomRight: Radius.circular(isAgent ? 4 : 16),
              ),
              border: isAgent || isDark
                  ? null
                  : Border.all(color: AppColors.lightCardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.messageType == MessageType.image && message.mediaUrl != null) ...[
                  ClipRRect(
                    borderRadius: AppDimensions.roundedMd,
                    child: Container(
                      width: 200,
                      height: 140,
                      color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                      child: const Center(
                        child: Icon(Icons.image_rounded, size: 48, color: AppColors.primaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message.text,
                  style: AppTypography.body1(color: textColor),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormatter.formatMessageTime(message.createdAt),
                      style: AppTypography.caption(color: timeColor).copyWith(fontSize: 10),
                    ),
                    if (isAgent) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MessageDeliveryStatus.read
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 13,
                        color: message.status == MessageDeliveryStatus.read
                            ? Colors.lightBlueAccent
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
