import 'package:flutter/material.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/widgets/algora_card.dart';
import 'package:algora/core/widgets/user_avatar.dart';

class AssigneePickerModal extends StatelessWidget {
  final String? currentAssigneeId;
  final Function(String? memberId, String? memberName) onSelectAssignee;

  const AssigneePickerModal({
    Key? key,
    required this.currentAssigneeId,
    required this.onSelectAssignee,
  }) : super(key: key);

  static const List<Map<String, String>> teamMembers = [
    {'id': 'usr_sarah_01', 'name': 'Sarah Jenkins', 'role': 'Workspace Owner'},
    {'id': 'usr_alex_02', 'name': 'Alex Rivera', 'role': 'Support Lead'},
    {'id': 'usr_elena_03', 'name': 'Elena Rostova', 'role': 'Support Agent'},
    {'id': 'usr_liam_04', 'name': 'Liam Thorne', 'role': 'Support Agent'},
  ];

  @override
  Widget build(BuildContext context) {
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
              'Assign Conversation',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Route this customer thread to a specific agent',
              style: AppTypography.caption(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Unassigned Option
            AlgoraCard(
              onTap: () {
                onSelectAssignee(null, 'Unassigned');
                Navigator.of(context).pop();
              },
              borderColor: currentAssigneeId == null ? AppColors.primary : null,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBorder.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_off_outlined, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unassigned / Shared Inbox Queue',
                      style: AppTypography.subtitle2(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (currentAssigneeId == null)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Member list
            ...teamMembers.map((m) {
              final isSelected = currentAssigneeId == m['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlgoraCard(
                  onTap: () {
                    onSelectAssignee(m['id'], m['name']);
                    Navigator.of(context).pop();
                  },
                  borderColor: isSelected ? AppColors.primary : null,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      UserAvatar(name: m['name']!, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name']!,
                              style: AppTypography.subtitle2(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              m['role']!,
                              style: AppTypography.caption(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
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
  }
}
