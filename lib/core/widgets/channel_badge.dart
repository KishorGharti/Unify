import 'package:flutter/material.dart';
import '../constants/channel_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_dimensions.dart';

class ChannelBadge extends StatelessWidget {
  final ChannelType channel;
  final bool showLabel;
  final double size;

  const ChannelBadge({
    Key? key,
    required this.channel,
    this.showLabel = true,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (channel == ChannelType.instagram) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: AppColors.instagramGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.camera_alt_rounded,
          size: size * 0.65,
          color: Colors.white,
        ),
      );
    } else if (channel == ChannelType.facebook) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.facebook,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.facebook_rounded,
          size: size * 0.75,
          color: Colors.white,
        ),
      );
    } else {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: channel.brandColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          channel.iconData,
          size: size * 0.65,
          color: Colors.white,
        ),
      );
    }

    if (!showLabel) {
      return iconWidget;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: channel == ChannelType.instagram
            ? AppColors.instagram.withOpacity(0.12)
            : channel.brandColor.withOpacity(0.12),
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(
          color: channel.brandColor.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(
            channel.shortName,
            style: AppTypography.badge(
              color: channel == ChannelType.instagram
                  ? AppColors.instagram
                  : channel.brandColor,
            ).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
