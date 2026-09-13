import 'package:flutter/material.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/widgets/unify_card.dart';

class QuickRepliesModal extends StatelessWidget {
  final ValueChanged<String> onSelectReply;

  const QuickRepliesModal({Key? key, required this.onSelectReply}) : super(key: key);

  static const List<Map<String, String>> cannedReplies = [
    {
      'title': 'Greeting & Introduction',
      'shortcut': '/hello',
      'text': 'Hi there! Thank you for reaching out to us. How can I assist you with your order or inquiry today?',
    },
    {
      'title': 'Order Shipping & Tracking',
      'shortcut': '/track',
      'text': 'Your package is on its way! You can track real-time delivery status using the tracking code sent to your email confirmation.',
    },
    {
      'title': 'Inventory Stock Check',
      'shortcut': '/stock',
      'text': 'I have verified with our warehouse team, and this item is currently in stock ready for same-day dispatch.',
    },
    {
      'title': 'Return & Exchange Policy',
      'shortcut': '/returns',
      'text': 'We offer a hassle-free 30-day return and exchange policy. Just let us know your order number to generate a return slip.',
    },
    {
      'title': 'Business Hours & SLA',
      'shortcut': '/hours',
      'text': 'Our customer support team is available Monday through Friday from 8:00 AM to 8:00 PM EST.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkCardBorder,
                borderRadius: AppDimensions.roundedFull,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Canned Quick Replies',
                style: AppTypography.heading3(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any template to insert into your customer response',
            style: AppTypography.caption(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: cannedReplies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final reply = cannedReplies[index];
                return UnifyCard(
                  onTap: () {
                    onSelectReply(reply['text']!);
                    Navigator.of(context).pop();
                  },
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reply['title']!,
                            style: AppTypography.subtitle2(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: AppDimensions.roundedSm,
                            ),
                            child: Text(
                              reply['shortcut']!,
                              style: AppTypography.badge(color: AppColors.primaryLight).copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reply['text']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
