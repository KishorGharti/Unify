import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/channel_config.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/date_formatter.dart';
import 'package:algora/core/widgets/algora_button.dart';
import 'package:algora/core/widgets/algora_card.dart';
import 'package:algora/core/widgets/channel_badge.dart';
import 'package:algora/core/widgets/empty_state_view.dart';
import 'package:algora/core/widgets/loading_state_view.dart';
import 'package:algora/features/channels/data/models/connected_account_model.dart';
import 'package:algora/features/channels/presentation/providers/channels_provider.dart';
import 'connect_facebook_screen.dart';
import 'connect_instagram_screen.dart';

class ConnectedAccountsScreen extends ConsumerWidget {
  const ConnectedAccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final channelsState = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Connected Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(channelsProvider.notifier).loadAccounts(),
          ),
        ],
      ),
      body: channelsState.isLoading
          ? const LoadingStateView(message: 'Syncing Meta channels...')
          : RefreshIndicator(
              onRefresh: () => ref.read(channelsProvider.notifier).loadAccounts(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta Security & Official API banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.accent.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: AppDimensions.roundedLg,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meta Official Graph API Integration',
                                  style: AppTypography.subtitle2(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Algora connects via official OAuth & Webhooks. No passwords stored, end-to-end multi-tenant secure.',
                                  style: AppTypography.caption(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Active Accounts
                    Text(
                      'Active Social Channels (${channelsState.accounts.length})',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (channelsState.accounts.isEmpty)
                      const EmptyStateView(
                        title: 'No Connected Accounts',
                        description: 'Connect your Facebook Page or Instagram Business account below to start receiving unified customer messages.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: channelsState.accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final account = channelsState.accounts[index];
                          return _buildAccountCard(context, ref, account, isDark);
                        },
                      ),

                    const SizedBox(height: 32),

                    // Section: Add New Channels
                    Text(
                      'Connect New Channel',
                      style: AppTypography.heading3(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Connect FB Card
                    _buildAddChannelCard(
                      context: context,
                      title: 'Facebook Page Messenger',
                      subtitle: 'Receive customer messages & comments from your official Facebook Business Pages.',
                      channel: ChannelType.facebook,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ConnectFacebookScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Connect IG Card
                    _buildAddChannelCard(
                      context: context,
                      title: 'Instagram Professional Direct',
                      subtitle: 'Connect Instagram Business/Creator account for direct messages and story replies.',
                      channel: ChannelType.instagram,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ConnectInstagramScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Future Channel (Disabled with 'Coming Soon')
                    _buildFutureChannelCard(
                      title: 'WhatsApp Business API',
                      subtitle: 'Support for WhatsApp Cloud API is planned in next release.',
                      channel: ChannelType.whatsapp,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    ConnectedAccountModel account,
    bool isDark,
  ) {
    return AlgoraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChannelBadge(channel: account.channelType, showLabel: false, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName,
                      style: AppTypography.subtitle1(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${account.externalId} • Connected ${DateFormatter.formatShortDate(account.connectedAt)}',
                      style: AppTypography.caption(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: AppDimensions.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: AppTypography.badge(color: AppColors.success).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Webhook sync active: ${DateFormatter.formatTimeAgo(account.lastWebhookReceived)}',
                    style: AppTypography.caption(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _showDisconnectDialog(context, ref, account);
                },
                child: Text(
                  'Disconnect',
                  style: AppTypography.caption(color: AppColors.error).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddChannelCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required ChannelType channel,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AlgoraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ChannelBadge(channel: channel, showLabel: false, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.subtitle1(
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
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildFutureChannelCard({
    required String title,
    required String subtitle,
    required ChannelType channel,
    required bool isDark,
  }) {
    return Opacity(
      opacity: 0.6,
      child: AlgoraCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ChannelBadge(channel: channel, showLabel: false, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.subtitle1(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: AppDimensions.roundedFull,
                        ),
                        child: Text(
                          'Coming Soon',
                          style: AppTypography.badge(color: AppColors.primaryLight).copyWith(fontSize: 9),
                        ),
                      ),
                    ],
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
            ),
          ],
        ),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref, ConnectedAccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Channel'),
        content: Text('Are you sure you want to disconnect ${account.accountName}? Incoming messages will no longer sync until reconnected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(channelsProvider.notifier).disconnectAccount(account.id);
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
