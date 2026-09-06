import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

enum ConversationStatus {
  open,
  pending,
  resolved,
  snoozed;

  String get label {
    switch (this) {
      case ConversationStatus.open:
        return 'Open';
      case ConversationStatus.pending:
        return 'Pending';
      case ConversationStatus.resolved:
        return 'Resolved';
      case ConversationStatus.snoozed:
        return 'Snoozed';
    }
  }

  Color get color {
    switch (this) {
      case ConversationStatus.open:
        return AppColors.statusOpen;
      case ConversationStatus.pending:
        return AppColors.statusPending;
      case ConversationStatus.resolved:
        return AppColors.statusResolved;
      case ConversationStatus.snoozed:
        return AppColors.statusSnoozed;
    }
  }

  static ConversationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'open':
        return ConversationStatus.open;
      case 'pending':
        return ConversationStatus.pending;
      case 'resolved':
      case 'closed':
        return ConversationStatus.resolved;
      case 'snoozed':
        return ConversationStatus.snoozed;
      default:
        return ConversationStatus.open;
    }
  }
}

class StatusBadge extends StatelessWidget {
  final ConversationStatus status;
  final bool isCompact;

  const StatusBadge({
    Key? key,
    required this.status,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(color: status.color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.badge(color: status.color).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
