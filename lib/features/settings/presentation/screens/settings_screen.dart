import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/app_constants.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/widgets/algora_badge.dart';
import 'package:algora/core/widgets/algora_card.dart';
import 'package:algora/core/widgets/user_avatar.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/auth/presentation/screens/login_screen.dart';
import 'package:algora/features/channels/presentation/screens/connected_accounts_screen.dart';
import 'package:algora/features/team/presentation/screens/team_members_screen.dart';
import 'package:algora/features/settings/presentation/providers/settings_provider.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showTenantSwitcher(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  'Switch Business Workspace',
                  style: AppTypography.heading3(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which company tenant to view and manage',
                  style: AppTypography.caption(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ...user.availableTenants.map((t) {
                  final isCurrent = t.id == user.tenantId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AlgoraCard(
                      onTap: () {
                        ref.read(authStateProvider.notifier).switchTenant(t.id);
                        Navigator.of(ctx).pop();
                      },
                      borderColor: isCurrent ? AppColors.primary : null,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: AppDimensions.roundedMd,
                            ),
                            child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: AppTypography.subtitle2(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  '${t.planTier} Plan • ${t.maxConnectedAccounts} channels',
                                  style: AppTypography.caption(color: AppColors.textMutedDark),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out from your Algora workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final settingsState = ref.watch(settingsProvider);
    final user = authState.user;
    final tenant = user?.currentTenant;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Settings & Workspace'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User & Workspace Quick Card
            AlgoraCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(name: user?.fullName ?? 'Sarah Jenkins', size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Sarah Jenkins',
                          style: AppTypography.subtitle1(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          user?.email ?? 'sarah.jenkins@acmegroup.com',
                          style: AppTypography.caption(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AlgoraBadge(
                              text: user?.role.displayName ?? 'Workspace Owner',
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              textColor: AppColors.primaryLight,
                              fontSize: 9,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Business & Multi-Tenant
            Text(
              'Business & Workspace',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            AlgoraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                    title: Text(
                      'Current Tenant: ${tenant?.name ?? "Acme Retail Group"}',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Switch between business profiles'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showTenantSwitcher(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.hub_outlined, color: AppColors.facebook),
                    title: Text(
                      'Connected Channels',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Facebook Pages & Instagram Accounts'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConnectedAccountsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined, color: AppColors.accent),
                    title: Text(
                      'Team & Permissions',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Invite support agents & assign roles'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: App Preferences
            Text(
              'App Preferences',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            AlgoraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                    title: Text(
                      'Dark Mode Interface',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                    title: Text(
                      'Real-time Push Notifications',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Instant alerts for incoming FB & IG messages'),
                    value: settingsState.pushNotificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).togglePush(val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primaryLight),
                    title: Text(
                      'Notifications Center',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('View recent alerts and assignment logs'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Sign Out
            AlgoraCard(
              onTap: () => _showLogoutDialog(context, ref),
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out of Workspace',
                    style: AppTypography.button(color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${AppConstants.appName} v${AppConstants.appVersion} • Multi-Tenant Meta SaaS',
                style: AppTypography.caption(color: AppColors.textMutedDark),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
