import 'package:flutter/material.dart';

enum ChannelType {
  facebook,
  instagram,
  whatsapp,
  viber,
  telegram,
  email,
  tiktok;

  String get displayName {
    switch (this) {
      case ChannelType.facebook:
        return 'Facebook Messenger';
      case ChannelType.instagram:
        return 'Instagram Direct';
      case ChannelType.whatsapp:
        return 'WhatsApp Business';
      case ChannelType.viber:
        return 'Viber';
      case ChannelType.telegram:
        return 'Telegram';
      case ChannelType.email:
        return 'Email Support';
      case ChannelType.tiktok:
        return 'TikTok Direct';
    }
  }

  String get shortName {
    switch (this) {
      case ChannelType.facebook:
        return 'Facebook';
      case ChannelType.instagram:
        return 'Instagram';
      case ChannelType.whatsapp:
        return 'WhatsApp';
      case ChannelType.viber:
        return 'Viber';
      case ChannelType.telegram:
        return 'Telegram';
      case ChannelType.email:
        return 'Email';
      case ChannelType.tiktok:
        return 'TikTok';
    }
  }

  bool get isSupportedInMvp {
    return this == ChannelType.facebook || this == ChannelType.instagram;
  }

  Color get brandColor {
    switch (this) {
      case ChannelType.facebook:
        return const Color(0xFF1877F2);
      case ChannelType.instagram:
        return const Color(0xFFE1306C);
      case ChannelType.whatsapp:
        return const Color(0xFF25D366);
      case ChannelType.viber:
        return const Color(0xFF7360F2);
      case ChannelType.telegram:
        return const Color(0xFF229ED9);
      case ChannelType.email:
        return const Color(0xFF6B7280);
      case ChannelType.tiktok:
        return const Color(0xFF000000);
    }
  }

  IconData get iconData {
    switch (this) {
      case ChannelType.facebook:
        return Icons.facebook;
      case ChannelType.instagram:
        return Icons.camera_alt_outlined;
      case ChannelType.whatsapp:
        return Icons.chat_bubble_outline;
      case ChannelType.viber:
        return Icons.phone_in_talk_outlined;
      case ChannelType.telegram:
        return Icons.send_rounded;
      case ChannelType.email:
        return Icons.mail_outline_rounded;
      case ChannelType.tiktok:
        return Icons.music_note_outlined;
    }
  }

  static ChannelType fromString(String value) {
    return ChannelType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChannelType.facebook,
    );
  }
}
