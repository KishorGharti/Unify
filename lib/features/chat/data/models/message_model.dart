import 'package:unify/core/constants/channel_config.dart';

enum MessageType {
  text,
  image,
  file,
  internalNote,
  system;

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'internal_note':
      case 'internalnote':
        return MessageType.internalNote;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

enum MessageSenderType {
  customer,
  agent,
  bot,
  system;

  static MessageSenderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'customer':
        return MessageSenderType.customer;
      case 'agent':
        return MessageSenderType.agent;
      case 'bot':
        return MessageSenderType.bot;
      case 'system':
      default:
        return MessageSenderType.system;
    }
  }
}

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageDeliveryStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageDeliveryStatus.sending;
      case 'sent':
        return MessageDeliveryStatus.sent;
      case 'delivered':
        return MessageDeliveryStatus.delivered;
      case 'read':
        return MessageDeliveryStatus.read;
      case 'failed':
        return MessageDeliveryStatus.failed;
      default:
        return MessageDeliveryStatus.delivered;
    }
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final MessageSenderType senderType;
  final String senderName;
  final String? senderAvatarUrl;
  final MessageType messageType;
  final String text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final ChannelType channel;
  final MessageDeliveryStatus status;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderName,
    this.senderAvatarUrl,
    required this.messageType,
    required this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    required this.channel,
    this.status = MessageDeliveryStatus.delivered,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: MessageSenderType.fromString(json['sender_type'] as String? ?? 'customer'),
      senderName: json['sender_name'] as String? ?? 'Customer',
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      text: json['text'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      channel: ChannelType.fromString(json['channel'] as String? ?? 'facebook'),
      status: MessageDeliveryStatus.fromString(json['status'] as String? ?? 'delivered'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_type': senderType.name,
        'sender_name': senderName,
        'sender_avatar_url': senderAvatarUrl,
        'message_type': messageType.name,
        'text': text,
        'media_url': mediaUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'channel': channel.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}
