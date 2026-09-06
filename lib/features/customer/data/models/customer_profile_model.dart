import 'package:algora/core/constants/channel_config.dart';

class CustomerProfileModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final ChannelType primaryChannel;
  final String socialHandle; // e.g. @sophia.laurent or fb/sophia.laurent.7
  final String? location;
  final String? notes;
  final List<String> tags;
  final int totalConversationsCount;
  final double totalSpend;
  final DateTime firstSeenAt;
  final DateTime lastActiveAt;

  const CustomerProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.primaryChannel,
    required this.socialHandle,
    this.location,
    this.notes,
    this.tags = const [],
    this.totalConversationsCount = 1,
    this.totalSpend = 0.0,
    required this.firstSeenAt,
    required this.lastActiveAt,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      primaryChannel: ChannelType.fromString(json['primary_channel'] as String? ?? 'facebook'),
      socialHandle: json['social_handle'] as String? ?? '',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalConversationsCount: json['total_conversations_count'] as int? ?? 1,
      totalSpend: (json['total_spend'] as num?)?.toDouble() ?? 0.0,
      firstSeenAt: json['first_seen_at'] != null
          ? DateTime.parse(json['first_seen_at'])
          : DateTime.now(),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'primary_channel': primaryChannel.name,
        'social_handle': socialHandle,
        'location': location,
        'notes': notes,
        'tags': tags,
        'total_conversations_count': totalConversationsCount,
        'total_spend': totalSpend,
        'first_seen_at': firstSeenAt.toIso8601String(),
        'last_active_at': lastActiveAt.toIso8601String(),
      };
}
