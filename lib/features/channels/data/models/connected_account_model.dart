import 'package:algora/core/constants/channel_config.dart';

enum ConnectionStatus {
  active,
  expired,
  needsReauth,
  syncing;

  String get displayName {
    switch (this) {
      case ConnectionStatus.active:
        return 'Healthy & Active';
      case ConnectionStatus.expired:
        return 'Token Expired';
      case ConnectionStatus.needsReauth:
        return 'Re-Auth Required';
      case ConnectionStatus.syncing:
        return 'Syncing Webhooks';
    }
  }

  static ConnectionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return ConnectionStatus.active;
      case 'expired':
        return ConnectionStatus.expired;
      case 'needs_reauth':
        return ConnectionStatus.needsReauth;
      case 'syncing':
        return ConnectionStatus.syncing;
      default:
        return ConnectionStatus.active;
    }
  }
}

class ConnectedAccountModel {
  final String id;
  final String tenantId;
  final ChannelType channelType;
  final String accountName;
  final String externalId; // Meta Page ID or IG Account ID
  final String? profilePicUrl;
  final ConnectionStatus status;
  final int activeConversationsCount;
  final DateTime lastWebhookReceived;
  final List<String> permissionsGranted;
  final DateTime connectedAt;

  const ConnectedAccountModel({
    required this.id,
    required this.tenantId,
    required this.channelType,
    required this.accountName,
    required this.externalId,
    this.profilePicUrl,
    required this.status,
    this.activeConversationsCount = 0,
    required this.lastWebhookReceived,
    this.permissionsGranted = const [],
    required this.connectedAt,
  });

  factory ConnectedAccountModel.fromJson(Map<String, dynamic> json) {
    return ConnectedAccountModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      channelType: ChannelType.fromString(json['channel_type'] as String),
      accountName: json['account_name'] as String,
      externalId: json['external_id'] as String,
      profilePicUrl: json['profile_pic_url'] as String?,
      status: ConnectionStatus.fromString(json['status'] as String? ?? 'active'),
      activeConversationsCount: json['active_conversations_count'] as int? ?? 0,
      lastWebhookReceived: json['last_webhook_received'] != null
          ? DateTime.parse(json['last_webhook_received'])
          : DateTime.now(),
      permissionsGranted: (json['permissions_granted'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'channel_type': channelType.name,
        'account_name': accountName,
        'external_id': externalId,
        'profile_pic_url': profilePicUrl,
        'status': status.name,
        'active_conversations_count': activeConversationsCount,
        'last_webhook_received': lastWebhookReceived.toIso8601String(),
        'permissions_granted': permissionsGranted,
        'connected_at': connectedAt.toIso8601String(),
      };
}
