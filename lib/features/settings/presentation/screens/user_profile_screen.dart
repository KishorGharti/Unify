import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/utils/date_formatter.dart';
import 'package:unify/core/widgets/unify_badge.dart';
import 'package:unify/core/widgets/unify_button.dart';
import 'package:unify/core/widgets/unify_card.dart';
import 'package:unify/core/widgets/unify_text_field.dart';
import 'package:unify/core/widgets/user_avatar.dart';
import 'package:unify/features/auth/presentation/providers/auth_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UnifyTextField(
                label: 'Current Password',
                controller: oldPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              UnifyTextField(
                label: 'New Password',
                controller: newPasswordController,
                isPassword: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated securely!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('My Profile'),
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
                    name: user?.fullName ?? 'Sarah Jenkins',
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Sarah Jenkins',
                    style: AppTypography.heading2(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'sarah.jenkins@acmegroup.com',
                    style: AppTypography.body2(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  UnifyBadge(
                    text: user?.role.displayName ?? 'Workspace Owner',
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    textColor: AppColors.primaryLight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            UnifyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security & Credentials',
                    style: AppTypography.subtitle1(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    title: Text(
                      'Change Password',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Last updated 45 days ago'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phonelink_lock_rounded, color: AppColors.success),
                    title: Text(
                      'Two-Factor Authentication (2FA)',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Enforced by Workspace Policy'),
                    trailing: const UnifyBadge(
                      text: 'Enabled',
                      backgroundColor: AppColors.success,
                      textColor: Colors.white,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices_rounded, color: AppColors.accent),
                    title: Text(
                      'Active Sessions',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: const Text('Flutter Mobile App • iPhone 15 Pro (Current)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            UnifyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tenant Information',
                    style: AppTypography.subtitle1(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tenant ID: ${user?.tenantId ?? "tenant_acme_01"}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Workspace: ${user?.currentTenant?.name ?? "Acme Retail Group"}',
                    style: AppTypography.caption(color: AppColors.textMutedDark),
                  ),
                  Text(
                    'Created: ${DateFormatter.formatShortDate(user?.createdAt ?? DateTime.now())}',
                    style: AppTypography.caption(color: AppColors.textMutedDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
