import 'package:flutter/material.dart';
import 'package:unify/core/constants/channel_config.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/utils/date_formatter.dart';
import 'package:unify/core/widgets/unify_badge.dart';
import 'package:unify/core/widgets/unify_card.dart';
import 'package:unify/core/widgets/channel_badge.dart';
import 'package:unify/core/widgets/user_avatar.dart';
import 'package:unify/features/customer/data/models/customer_profile_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  final CustomerProfileModel customer;

  const CustomerProfileScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Customer Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [

            UnifyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  UserAvatar(
                    name: customer.fullName,
                    channel: customer.primaryChannel,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.fullName,
                    style: AppTypography.heading2(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChannelBadge(channel: customer.primaryChannel, showLabel: true),
                      const SizedBox(width: 8),
                      Text(
                        customer.socialHandle,
                        style: AppTypography.body2(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: customer.tags.map((t) {
                      return UnifyBadge(
                        text: t,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        textColor: AppColors.primaryLight,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: UnifyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Total Spend', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${customer.totalSpend.toStringAsFixed(2)}',
                          style: AppTypography.heading3(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UnifyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.forum_outlined, size: 16, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text('Inquiries', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customer.totalConversationsCount.toString(),
                          style: AppTypography.heading3(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            UnifyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact & Identity Details',
                    style: AppTypography.subtitle1(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (customer.email != null) ...[
                    _buildInfoRow(Icons.email_outlined, 'Email', customer.email!, isDark),
                    const Divider(height: 16),
                  ],
                  if (customer.phone != null) ...[
                    _buildInfoRow(Icons.phone_outlined, 'Phone', customer.phone!, isDark),
                    const Divider(height: 16),
                  ],
                  if (customer.location != null) ...[
                    _buildInfoRow(Icons.location_on_outlined, 'Location', customer.location!, isDark),
                    const Divider(height: 16),
                  ],
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'First Contact',
                    DateFormatter.formatShortDate(customer.firstSeenAt),
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    Icons.bolt_rounded,
                    'Last Active',
                    DateFormatter.formatTimeAgo(customer.lastActiveAt),
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (customer.notes != null) ...[
              UnifyCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Internal CRM Notes',
                          style: AppTypography.subtitle1(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer.notes!,
                      style: AppTypography.body1(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.body2(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.subtitle2(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
