import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/constants/channel_config.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/utils/date_formatter.dart';
import 'package:unify/core/widgets/unify_badge.dart';
import 'package:unify/core/widgets/unify_button.dart';
import 'package:unify/core/widgets/unify_card.dart';
import 'package:unify/core/widgets/channel_badge.dart';
import 'package:unify/core/widgets/loading_state_view.dart';
import 'package:unify/features/auth/presentation/providers/auth_provider.dart';
import 'package:unify/features/channels/presentation/screens/connected_accounts_screen.dart';
import 'package:unify/features/team/presentation/screens/team_members_screen.dart';
import 'package:unify/features/dashboard/presentation/providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final user = authState.user;
    final tenant = user?.currentTenant;
    final metrics = dashboardState.metrics;
    final openCount = metrics?.openConversations ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tenant?.name ?? 'Workspace',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'Unified Messaging Workspace',
              style: AppTypography.caption(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(dashboardProvider.notifier).loadMetrics(),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const LoadingStateView(message: 'Calculating live business analytics...')
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).loadMetrics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppDimensions.roundedLg,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.fullName.split(' ').first ?? 'there'}!',
                                  style: AppTypography.heading2(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  openCount > 0
                                      ? 'You have $openCount open ${openCount == 1 ? 'inquiry' : 'inquiries'} awaiting response.'
                                      : 'All caught up - no open inquiries right now.',
                                  style: AppTypography.body2(color: Colors.white.withOpacity(0.9)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppDimensions.roundedMd,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onPressed: () => onNavigateTab?.call(1),
                            child: const Text('Open Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Live Performance & SLAs',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Open Inquiries',
                            value: '$openCount',
                            subtitle: 'Requires attention',
                            icon: Icons.mark_chat_unread_outlined,
                            iconColor: AppColors.statusOpen,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Avg First Reply',
                            value: metrics?.avgResponseTime ?? '—',
                            subtitle: 'Average across all channels',
                            icon: Icons.timer_outlined,
                            iconColor: AppColors.accent,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Resolution Rate',
                            value: '${metrics?.resolutionRate.toStringAsFixed(1) ?? '0'}%',
                            subtitle: '${metrics?.resolvedToday ?? 0} resolved today',
                            icon: Icons.task_alt_rounded,
                            iconColor: AppColors.statusResolved,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Conversations',
                            value: '${metrics?.totalConversations ?? 0}',
                            subtitle: 'Across FB & IG',
                            icon: Icons.all_inclusive_rounded,
                            iconColor: AppColors.primaryLight,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Channel Distribution',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final igCount = metrics?.instagramInquiries ?? 0;
                      final fbCount = metrics?.facebookInquiries ?? 0;
                      final channelTotal = igCount + fbCount;
                      final igPercent = channelTotal > 0 ? (igCount * 100 / channelTotal).round() : 0;
                      final fbPercent = channelTotal > 0 ? 100 - igPercent : 0;

                      return UnifyCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ChannelBadge(channel: ChannelType.instagram, showLabel: true),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$igPercent% ($igCount DMs)',
                                      style: AppTypography.caption(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ChannelBadge(channel: ChannelType.facebook, showLabel: true),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$fbPercent% ($fbCount Msgs)',
                                      style: AppTypography.caption(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: AppDimensions.roundedFull,
                              child: SizedBox(
                                height: 10,
                                child: igCount > 0 && fbCount > 0
                                    ? Row(
                                        children: [
                                          Expanded(flex: igPercent, child: Container(color: AppColors.instagram)),
                                          const SizedBox(width: 2),
                                          Expanded(flex: fbPercent, child: Container(color: AppColors.facebook)),
                                        ],
                                      )
                                    : Container(
                                        color: igCount > 0
                                            ? AppColors.instagram
                                            : fbCount > 0
                                                ? AppColors.facebook
                                                : (isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0)),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    Text(
                      'Quick Actions',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: UnifyCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ConnectedAccountsScreen()),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Icon(Icons.add_link_rounded, color: AppColors.primary, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  'Connect Page',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: UnifyCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  'Invite Team',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: UnifyCard(
                            onTap: () => onNavigateTab?.call(4),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Icon(Icons.settings_rounded, color: AppColors.warning, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  'Settings',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Recent Activity Stream',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((metrics?.recentActivities ?? const []).isEmpty)
                      Text(
                        'No activity yet - it shows up here once messages start coming in.',
                        style: AppTypography.body2(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ...dashboardState.metrics?.recentActivities.map((act) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: UnifyCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: act.channel == 'instagram'
                                          ? AppColors.instagram.withOpacity(0.15)
                                          : AppColors.facebook.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      act.channel == 'instagram'
                                          ? Icons.camera_alt_rounded
                                          : Icons.facebook_rounded,
                                      size: 18,
                                      color: act.channel == 'instagram'
                                          ? AppColors.instagram
                                          : AppColors.facebook,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.title,
                                          style: AppTypography.subtitle2(
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          act.description,
                                          style: AppTypography.caption(
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatTimeAgo(act.timestamp),
                                    style: AppTypography.caption(
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList() ??
                        [],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return UnifyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.caption(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.heading2(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
