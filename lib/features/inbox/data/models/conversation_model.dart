import 'package:algora/core/constants/channel_config.dart';
import 'package:algora/core/widgets/status_badge.dart';
import 'package:algora/features/customer/data/models/customer_profile_model.dart';
import 'package:algora/features/chat/data/models/message_model.dart';

class ConversationModel {
  final String id;
  final String tenantId;
  final CustomerProfileModel customer;
  final ChannelType channel;
  final String latestMessageText;
  final DateTime latestMessageTimestamp;
  final int unreadCount;
  final bool isRead;
  final String? assignedToMemberId;
  final String? assignedToMemberName;
  final ConversationStatus status;
  final List<String> tags;
  final List<MessageModel> recentMessages;
  // A custom label the app lets an agent give this contact (shown as a
  // small green pill above their name) - purely optional, null by default.
  final String? nickname;

  const ConversationModel({
    required this.id,
    required this.tenantId,
    required this.customer,
    required this.channel,
    required this.latestMessageText,
    required this.latestMessageTimestamp,
    this.unreadCount = 0,
    this.isRead = true,
    this.assignedToMemberId,
    this.assignedToMemberName,
    this.status = ConversationStatus.open,
    this.tags = const [],
    this.recentMessages = const [],
    this.nickname,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      customer: CustomerProfileModel.fromJson(json['customer']),
      channel: ChannelType.fromString(json['channel'] as String? ?? 'facebook'),
      latestMessageText: json['latest_message_text'] as String? ?? '',
      latestMessageTimestamp: json['latest_message_timestamp'] != null
          ? DateTime.parse(json['latest_message_timestamp'])
          : DateTime.now(),
      unreadCount: json['unread_count'] as int? ?? 0,
      isRead: json['is_read'] as bool? ?? true,
      assignedToMemberId: json['assigned_to_member_id'] as String?,
      assignedToMemberName: json['assigned_to_member_name'] as String?,
      status: ConversationStatus.fromString(json['status'] as String? ?? 'open'),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recentMessages: (json['recent_messages'] as List<dynamic>?)
              ?.map((e) => MessageModel.fromJson(e))
              .toList() ??
          [],
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'customer': customer.toJson(),
        'channel': channel.name,
        'latest_message_text': latestMessageText,
        'latest_message_timestamp': latestMessageTimestamp.toIso8601String(),
        'unread_count': unreadCount,
        'is_read': isRead,
        'assigned_to_member_id': assignedToMemberId,
        'assigned_to_member_name': assignedToMemberName,
        'status': status.name,
        'tags': tags,
        'recent_messages': recentMessages.map((m) => m.toJson()).toList(),
        'nickname': nickname,
      };

  ConversationModel copyWith({
    String? id,
    String? tenantId,
    CustomerProfileModel? customer,
    ChannelType? channel,
    String? latestMessageText,
    DateTime? latestMessageTimestamp,
    int? unreadCount,
    bool? isRead,
    String? assignedToMemberId,
    String? assignedToMemberName,
    ConversationStatus? status,
    List<String>? tags,
    List<MessageModel>? recentMessages,
    String? nickname,
    bool clearNickname = false,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customer: customer ?? this.customer,
      channel: channel ?? this.channel,
      latestMessageText: latestMessageText ?? this.latestMessageText,
      latestMessageTimestamp: latestMessageTimestamp ?? this.latestMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      isRead: isRead ?? this.isRead,
      assignedToMemberId: assignedToMemberId ?? this.assignedToMemberId,
      assignedToMemberName: assignedToMemberName ?? this.assignedToMemberName,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      recentMessages: recentMessages ?? this.recentMessages,
      nickname: clearNickname ? null : (nickname ?? this.nickname),
    );
  }
}
