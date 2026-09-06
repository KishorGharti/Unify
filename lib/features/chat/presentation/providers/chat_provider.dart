import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/channel_config.dart';
import 'package:algora/core/websocket/socket_events.dart';
import 'package:algora/core/websocket/socket_service.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:algora/features/chat/data/chat_repository.dart';
import 'package:algora/features/chat/data/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlgoraChatRepository(apiClient: apiClient);
});

enum ChatInputMode { customerReply, internalNote }

class ChatState {
  final String conversationId;
  final bool isLoading;
  final List<MessageModel> messages;
  final ChatInputMode inputMode;
  final bool isCustomerTyping;
  final String? typingCustomerName;
  final String? errorMessage;

  const ChatState({
    required this.conversationId,
    this.isLoading = false,
    this.messages = const [],
    this.inputMode = ChatInputMode.customerReply,
    this.isCustomerTyping = false,
    this.typingCustomerName,
    this.errorMessage,
  });

  ChatState copyWith({
    String? conversationId,
    bool? isLoading,
    List<MessageModel>? messages,
    ChatInputMode? inputMode,
    bool? isCustomerTyping,
    String? typingCustomerName,
    String? errorMessage,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      inputMode: inputMode ?? this.inputMode,
      isCustomerTyping: isCustomerTyping ?? this.isCustomerTyping,
      typingCustomerName: typingCustomerName ?? this.typingCustomerName,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final WebSocketService _socketService;
  final String _conversationId;

  ChatNotifier(this._repository, this._socketService, this._conversationId)
      : super(ChatState(conversationId: _conversationId)) {
    loadMessages();
    _socketService.subscribeToConversation(_conversationId);
    _listenToEvents();
  }

  void _listenToEvents() {
    _socketService.eventStream.listen((event) {
      if (event.conversationId == _conversationId) {
        if (event.type == SocketEventType.incomingMessage) {
          final payload = event.payload;
          final newMsg = MessageModel(
            id: payload['id'] ?? 'ws_msg_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: _conversationId,
            senderType: MessageSenderType.fromString(payload['sender_type'] ?? 'customer'),
            senderName: payload['sender_name'] ?? 'Customer',
            messageType: MessageType.text,
            text: payload['text'] ?? '',
            channel: ChannelType.fromString(payload['channel'] ?? 'facebook'),
            createdAt: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, newMsg],
            isCustomerTyping: false,
          );
        } else if (event.type == SocketEventType.customerTyping) {
          state = state.copyWith(
            isCustomerTyping: event.payload['is_typing'] ?? false,
            typingCustomerName: event.payload['customer_name'],
          );
        }
      }
    });
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final messages = await _repository.getMessages(_conversationId);
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setInputMode(ChatInputMode mode) {
    state = state.copyWith(inputMode: mode);
  }

  Future<void> sendMessage({
    required String text,
    required ChannelType channel,
    required String senderName,
  }) async {
    if (text.trim().isEmpty) return;

    if (state.inputMode == ChatInputMode.internalNote) {
      final note = await _repository.addInternalNote(
        conversationId: _conversationId,
        text: text.trim(),
        authorName: senderName,
      );
      state = state.copyWith(messages: [...state.messages, note]);
    } else {
      final message = await _repository.sendCustomerMessage(
        conversationId: _conversationId,
        text: text.trim(),
        channel: channel,
        senderName: senderName,
      );
      state = state.copyWith(messages: [...state.messages, message]);
    }
  }

  Future<void> sendImageAttachment({
    required String imageUrl,
    required ChannelType channel,
    required String senderName,
  }) async {
    final message = await _repository.sendImageAttachment(
      conversationId: _conversationId,
      imageUrl: imageUrl,
      channel: channel,
      senderName: senderName,
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }

  @override
  void dispose() {
    _socketService.unsubscribeFromConversation(_conversationId);
    super.dispose();
  }
}

final chatProviderFamily = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  final socket = ref.watch(webSocketServiceProvider);
  return ChatNotifier(repo, socket, conversationId);
});
