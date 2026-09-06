import 'package:dio/dio.dart';
import 'package:algora/core/constants/api_endpoints.dart';
import 'package:algora/core/errors/app_exceptions.dart';
import 'package:algora/core/network/api_client.dart';
import 'package:algora/core/widgets/status_badge.dart';
import 'models/conversation_model.dart';

abstract class InboxRepository {
  Future<List<ConversationModel>> getConversations(String tenantId);
  Future<ConversationModel> getConversationById(String conversationId);
  Future<void> updateStatus(String conversationId, ConversationStatus status);
  Future<void> updateAssignee(String conversationId, String? memberId, String? memberName);
  Future<void> updateTags(String conversationId, List<String> tags);
  Future<void> markAsRead(String conversationId);
  Future<void> updateNickname(String conversationId, String? nickname);
}

/// Talks to the real backend (see backend/src/controllers/inbox.controller.ts)
/// - conversations come from real Facebook/Instagram messages received via
/// the Meta webhook, once a channel is connected. No sample/demo data here;
/// an empty inbox means no messages have come in yet, not a bug.
class AlgoraInboxRepository implements InboxRepository {
  final ApiClient apiClient;

  // Nickname is a client-side-only label (see unified_inbox_screen.dart) -
  // the backend has no column for it, so it's kept here, in memory, per
  // conversation id. It intentionally doesn't survive an app restart yet;
  // move it server-side (a field on Conversation) if it needs to.
  final Map<String, String> _nicknames = {};

  AlgoraInboxRepository({required this.apiClient});

  @override
  Future<List<ConversationModel>> getConversations(String tenantId) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.conversations,
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? [])
          .map((e) => _withNickname(ConversationModel.fromJson(e as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.conversations}/$conversationId',
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return _withNickname(ConversationModel.fromJson(response.data!));
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> updateStatus(String conversationId, ConversationStatus status) async {
    try {
      await apiClient.post<dynamic>(
        '${ApiEndpoints.conversations}/$conversationId/status',
        data: {'status': status.name},
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> updateAssignee(String conversationId, String? memberId, String? memberName) async {
    try {
      await apiClient.post<dynamic>(
        '${ApiEndpoints.conversations}/$conversationId/assign',
        data: {'member_id': memberId},
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> updateTags(String conversationId, List<String> tags) async {
    try {
      await apiClient.post<dynamic>(
        '${ApiEndpoints.conversations}/$conversationId/tags',
        data: {'tags': tags},
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> updateNickname(String conversationId, String? nickname) async {
    // Client-side only - see the field comment above.
    if (nickname == null || nickname.isEmpty) {
      _nicknames.remove(conversationId);
    } else {
      _nicknames[conversationId] = nickname;
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    // The backend doesn't track a per-conversation read/unread column yet
    // (see inbox.controller.ts - unread_count is always 0), so there's
    // nothing to persist here today. Kept as a real method so the caller
    // doesn't need to know that; wire it up once that column exists.
  }

  ConversationModel _withNickname(ConversationModel conv) {
    final nickname = _nicknames[conv.id];
    return nickname != null ? conv.copyWith(nickname: nickname) : conv;
  }

  String _friendlyMessage(Object e) {
    if (e is AppException) return e.message;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return e.message ?? 'Something went wrong. Please try again.';
    }
    return e.toString();
  }
}
