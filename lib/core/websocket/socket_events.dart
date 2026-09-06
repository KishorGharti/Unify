enum SocketEventType {
  incomingMessage,
  messageStatusUpdated,
  conversationAssigned,
  conversationStatusChanged,
  conversationTagsUpdated,
  customerTyping,
  channelStatusChanged,
  unknown;

  static SocketEventType fromString(String value) {
    switch (value) {
      case 'message.new':
      case 'incoming_message':
        return SocketEventType.incomingMessage;
      case 'message.status':
      case 'message_status_updated':
        return SocketEventType.messageStatusUpdated;
      case 'conversation.assigned':
        return SocketEventType.conversationAssigned;
      case 'conversation.status':
        return SocketEventType.conversationStatusChanged;
      case 'conversation.tags':
        return SocketEventType.conversationTagsUpdated;
      case 'customer.typing':
        return SocketEventType.customerTyping;
      case 'channel.status':
        return SocketEventType.channelStatusChanged;
      default:
        return SocketEventType.unknown;
    }
  }
}

class SocketEvent {
  final SocketEventType type;
  final String tenantId;
  final String? conversationId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  SocketEvent({
    required this.type,
    required this.tenantId,
    this.conversationId,
    required this.payload,
    required this.timestamp,
  });

  factory SocketEvent.fromJson(Map<String, dynamic> json) {
    return SocketEvent(
      type: SocketEventType.fromString(json['event'] ?? ''),
      tenantId: json['tenant_id'] ?? '',
      conversationId: json['conversation_id'],
      payload: json['payload'] ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
