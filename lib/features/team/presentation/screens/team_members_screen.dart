import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/date_formatter.dart';
import 'package:algora/core/utils/validators.dart';
import 'package:algora/core/widgets/algora_badge.dart';
import 'package:algora/core/widgets/algora_button.dart';
import 'package:algora/core/widgets/algora_card.dart';
import 'package:algora/core/widgets/algora_text_field.dart';
import 'package:algora/core/widgets/loading_state_view.dart';
import 'package:algora/core/widgets/user_avatar.dart';
import 'package:algora/features/auth/data/models/user_model.dart';
import 'package:algora/features/team/data/models/team_member_model.dart';
import 'package:algora/features/team/presentation/providers/team_provider.dart';

class TeamMembersScreen extends ConsumerWidget {
  const TeamMembersScreen({Key? key}) : super(key: key);

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.agent;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: const RoundedRectangleBorder(borderRadius: AppDimensions.roundedLg),
            title: Text(
              'Invite Team Member',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add an agent or manager to your Algora workspace.',
                    style: AppTypography.caption(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AlgoraTextField(
                    label: 'Full Name',
                    hint: 'Alex Rivera',
                    controller: nameController,
                    validator: (v) => Validators.validateRequired(v, 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  AlgoraTextField(
                    label: 'Work Email',
                    hint: 'alex@acmegroup.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 14),
                  Text('Workspace Role', style: AppTypography.subtitle2(color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: const OutlineInputBorder(borderRadius: AppDimensions.roundedMd),
                    ),
                    items: [
                      DropdownMenuItem(value: UserRole.agent, child: Text(UserRole.agent.displayName)),
                      DropdownMenuItem(value: UserRole.admin, child: Text(UserRole.admin.displayName)),
                      DropdownMenuItem(value: UserRole.owner, child: Text(UserRole.owner.displayName)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
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
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    final success = await ref.read(teamProvider.notifier).inviteMember(
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim(),
                          role: selectedRole,
                        );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invited ${nameController.text} to workspace!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Send Invite', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Team & Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Invite Member',
            onPressed: () => _showInviteDialog(context, ref),
          ),
        ],
      ),
      body: teamState.isLoading
          ? const LoadingStateView(message: 'Loading team members...')
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Quota Card
                  AlgoraCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${teamState.members.length} of 25 Seats Active',
                                style: AppTypography.subtitle1(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pro Plan includes up to 25 team members with role-based permissions.',
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

                  // Members List
                  Text(
                    'Workspace Members (${teamState.members.length})',
                    style: AppTypography.heading3(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teamState.members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = teamState.members[index];
                      return _buildMemberCard(context, ref, member, isDark);
                    },
                  ),
                  const SizedBox(height: 24),

                  AlgoraButton(
                    text: 'Invite New Team Member',
                    onPressed: () => _showInviteDialog(context, ref),
                    variant: AlgoraButtonVariant.gradient,
                    icon: Icons.person_add_alt_1_rounded,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    WidgetRef ref,
    TeamMemberModel member,
    bool isDark,
  ) {
    Color roleColor = AppColors.primary;
    switch (member.role) {
      case UserRole.owner:
        roleColor = AppColors.warning;
        break;
      case UserRole.admin:
        roleColor = AppColors.primary;
        break;
      case UserRole.agent:
        roleColor = AppColors.accent;
        break;
    }

    return AlgoraCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          UserAvatar(
            name: member.fullName,
            isOnline: member.isOnline,
            showOnlineStatus: true,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.fullName,
                      style: AppTypography.subtitle1(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AlgoraBadge(
                      text: member.role.displayName,
                      backgroundColor: roleColor.withOpacity(0.12),
                      textColor: roleColor,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: AppTypography.caption(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active Chats: ${member.activeAssignedConversations} • Joined ${DateFormatter.formatShortDate(member.joinedAt)}',
                  style: AppTypography.caption(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          if (member.role != UserRole.owner)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onPressed: () {
                _showMemberOptions(context, ref, member);
              },
            ),
        ],
      ),
    );
  }

  void _showMemberOptions(BuildContext context, WidgetRef ref, TeamMemberModel member) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Revoke Workspace Access', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(teamProvider.notifier).removeMember(member.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
