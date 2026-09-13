import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/utils/date_formatter.dart';
import 'package:unify/core/widgets/unify_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  static final List<Map<String, dynamic>> sampleNotifications = [
    {
      'title': 'New Facebook Customer Inquiry',
      'message': 'Marcus Vance sent a message on Acme Official Store: "Hi team, thanks for the update..."',
      'type': 'message',
      'time': DateTime.now().subtract(const Duration(minutes: 18)),
      'isRead': false,
    },
    {
      'title': 'Instagram DM Assigned to You',
      'message': 'Sarah Jenkins assigned Sophia Laurent inquiry to your queue.',
      'type': 'assignment',
      'time': DateTime.now().subtract(const Duration(minutes: 45)),
      'isRead': false,
    },
    {
      'title': 'Webhook Health Check Successful',
      'message': 'Meta Graph API webhook handshake verified with zero latency.',
      'type': 'system',
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'isRead': true,
    },
    {
      'title': 'Monthly Billing Receipt Ready',
      'message': 'Your Pro Annual invoice INV-2026-003 has been processed.',
      'type': 'billing',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: sampleNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = sampleNotifications[index];
          final isRead = notif['isRead'] as bool;

          IconData icon;
          Color iconColor;
          switch (notif['type']) {
            case 'message':
              icon = Icons.forum_outlined;
              iconColor = AppColors.facebook;
              break;
            case 'assignment':
              icon = Icons.person_pin_circle_outlined;
              iconColor = AppColors.primary;
              break;
            case 'billing':
              icon = Icons.receipt_long_outlined;
              iconColor = AppColors.success;
              break;
            default:
              icon = Icons.bolt_rounded;
              iconColor = AppColors.accent;
          }

          return UnifyCard(
            padding: const EdgeInsets.all(14),
            borderColor: !isRead ? AppColors.primary.withOpacity(0.4) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'],
                              style: AppTypography.subtitle2(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ).copyWith(fontWeight: !isRead ? FontWeight.bold : FontWeight.w600),
                            ),
                          ),
                          Text(
                            DateFormatter.formatTimeAgo(notif['time']),
                            style: AppTypography.caption(
                              color: !isRead ? AppColors.primary : AppColors.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['message'],
                        style: AppTypography.body2(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
