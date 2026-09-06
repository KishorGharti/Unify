import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/channel_config.dart';
import 'package:algora/core/websocket/socket_events.dart';
import 'package:algora/core/websocket/socket_service.dart';
import 'package:algora/core/widgets/status_badge.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/chat/data/models/message_model.dart';
import 'package:algora/features/inbox/data/inbox_repository.dart';
import 'package:algora/features/inbox/data/models/conversation_model.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlgoraInboxRepository(apiClient: apiClient);
});

final webSocketServiceProvider = Provider<AlgoraWebSocketService>((ref) {
  return AlgoraWebSocketService();
});

enum InboxFilterType {
  all,
  unread,
  assignedToMe,
  facebook,
  instagram,
  resolved;

  String get label {
    switch (this) {
      case InboxFilterType.all:
        return 'All';
      case InboxFilterType.unread:
        return 'Unread';
      case InboxFilterType.assignedToMe:
        return 'Assigned to Me';
      case InboxFilterType.facebook:
        return 'Facebook';
      case InboxFilterType.instagram:
        return 'Instagram';
      case InboxFilterType.resolved:
        return 'Resolved';
    }
  }
}

class InboxState {
  final bool isLoading;
  final List<ConversationModel> allConversations;
  final InboxFilterType currentFilter;
  final String searchQuery;
  final String? errorMessage;

  const InboxState({
    this.isLoading = false,
    this.allConversations = const [],
    this.currentFilter = InboxFilterType.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<ConversationModel> get filteredConversations {
    return allConversations.where((conv) {
      // 1. Search Query Filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchName = conv.customer.fullName.toLowerCase().contains(query);
        final matchMsg = conv.latestMessageText.toLowerCase().contains(query);
        final matchTag = conv.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchName && !matchMsg && !matchTag) return false;
      }

      // 2. Category Filter
      switch (currentFilter) {
        case InboxFilterType.all:
          return conv.status != ConversationStatus.resolved;
        case InboxFilterType.unread:
          return !conv.isRead || conv.unreadCount > 0;
        case InboxFilterType.assignedToMe:
          return conv.assignedToMemberId == 'usr_sarah_01';
        case InboxFilterType.facebook:
          return conv.channel == ChannelType.facebook;
        case InboxFilterType.instagram:
          return conv.channel == ChannelType.instagram;
        case InboxFilterType.resolved:
          return conv.status == ConversationStatus.resolved;
      }
    }).toList();
  }

  int get totalUnreadCount {
    return allConversations.fold<int>(0, (sum, conv) => sum + (conv.unreadCount > 0 ? conv.unreadCount : (!conv.isRead ? 1 : 0)));
  }

  InboxState copyWith({
    bool? isLoading,
    List<ConversationModel>? allConversations,
    InboxFilterType? currentFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      allConversations: allConversations ?? this.allConversations,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final InboxRepository _repository;
  final WebSocketService _socketService;
  final String _tenantId;

  InboxNotifier(this._repository, this._socketService, this._tenantId)
      : super(const InboxState()) {
    loadConversations();
    _listenToSocketEvents();
  }

  void _listenToSocketEvents() {
    _socketService.eventStream.listen((event) {
      if (event.type == SocketEventType.incomingMessage) {
        final payload = event.payload;
        final convId = event.conversationId ?? payload['conversation_id'];
        if (convId != null) {
          final newMsg = MessageModel(
            id: payload['id'] ?? 'ws_msg_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: convId,
            senderType: MessageSenderType.fromString(payload['sender_type'] ?? 'customer'),
            senderName: payload['sender_name'] ?? 'Customer',
            messageType: MessageType.text,
            text: payload['text'] ?? '',
            channel: ChannelType.fromString(payload['channel'] ?? 'facebook'),
            createdAt: DateTime.now(),
          );

          // Update local list
          final updated = state.allConversations.map((c) {
            if (c.id == convId) {
              return c.copyWith(
                latestMessageText: newMsg.text,
                latestMessageTimestamp: newMsg.createdAt,
                unreadCount: c.unreadCount + 1,
                isRead: false,
                recentMessages: [...c.recentMessages, newMsg],
              );
            }
            return c;
          }).toList();

          state = state.copyWith(allConversations: updated);
        }
      }
    });
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final conversations = await _repository.getConversations(_tenantId);
      state = state.copyWith(isLoading: false, allConversations: conversations);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(InboxFilterType filter) {
    state = state.copyWith(currentFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markAsRead(conversationId);
    final updated = state.allConversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0, isRead: true);
      }
      return c;
    }).toList();
    state = state.copyWith(allConversations: updated);
  }

  Future<void> updateStatus(String conversationId, ConversationStatus status) async {
    await _repository.updateStatus(conversationId, status);
    final updated = state.allConversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(status: status);
      }
      return c;
    }).toList();
    state = state.copyWith(allConversations: updated);
  }

  Future<void> updateAssignee(String conversationId, String? memberId, String? memberName) async {
    await _repository.updateAssignee(conversationId, memberId, memberName);
    final updated = state.allConversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(
          assignedToMemberId: memberId,
          assignedToMemberName: memberName ?? 'Unassigned',
        );
      }
      return c;
    }).toList();
    state = state.copyWith(allConversations: updated);
  }

  Future<void> updateTags(String conversationId, List<String> tags) async {
    await _repository.updateTags(conversationId, tags);
    final updated = state.allConversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(tags: tags);
      }
      return c;
    }).toList();
    state = state.copyWith(allConversations: updated);
  }

  /// Sets (or, with null, clears) the optional custom nickname shown above a
  /// contact's name.
  Future<void> updateNickname(String conversationId, String? nickname) async {
    await _repository.updateNickname(conversationId, nickname);
    final updated = state.allConversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(nickname: nickname, clearNickname: nickname == null);
      }
      return c;
    }).toList();
    state = state.copyWith(allConversations: updated);
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repo = ref.watch(inboxRepositoryProvider);
  final socket = ref.watch(webSocketServiceProvider);
  final auth = ref.watch(authStateProvider);
  final tenantId = auth.user?.tenantId ?? 'tenant_acme_01';
  return InboxNotifier(repo, socket, tenantId);
});
