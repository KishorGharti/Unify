import 'package:flutter/material.dart';
import '../constants/channel_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'channel_badge.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final ChannelType? channel;
  final bool isOnline;
  final bool showOnlineStatus;

  const UserAvatar({
    Key? key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.channel,
    this.isOnline = false,
    this.showOnlineStatus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final bgColor = _generateColorForName(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.heading3(color: Colors.white).copyWith(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (channel != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: ChannelBadge(
                channel: channel!,
                showLabel: false,
                size: size * 0.42,
              ),
            ),
          if (showOnlineStatus && channel == null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textMutedDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _generateColorForName(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }
}
