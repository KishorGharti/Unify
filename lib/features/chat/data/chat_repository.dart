import 'package:dio/dio.dart';
import 'package:algora/core/constants/api_endpoints.dart';
import 'package:algora/core/constants/channel_config.dart';
import 'package:algora/core/errors/app_exceptions.dart';
import 'package:algora/core/network/api_client.dart';
import 'models/message_model.dart';

abstract class ChatRepository {
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendCustomerMessage({
    required String conversationId,
    required String text,
    required ChannelType channel,
    required String senderName,
  });
  Future<MessageModel> addInternalNote({
    required String conversationId,
    required String text,
    required String authorName,
  });
  Future<MessageModel> sendImageAttachment({
    required String conversationId,
    required String imageUrl,
    required ChannelType channel,
    required String senderName,
  });
}

/// Talks to the real backend (see backend/src/controllers/inbox.controller.ts).
/// A customer reply actually goes out through the Messenger/Instagram Send
/// API - there's no local echo or fake delay.
class AlgoraChatRepository implements ChatRepository {
  final ApiClient apiClient;

  AlgoraChatRepository({required this.apiClient});

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        '${ApiEndpoints.conversations}/$conversationId/messages',
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? []).map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<MessageModel> sendCustomerMessage({
    required String conversationId,
    required String text,
    required ChannelType channel,
    required String senderName,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.conversations}/$conversationId/messages',
        data: {'text': text},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return MessageModel.fromJson(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<MessageModel> addInternalNote({
    required String conversationId,
    required String text,
    required String authorName,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.conversations}/$conversationId/notes',
        data: {'text': text},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return MessageModel.fromJson(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<MessageModel> sendImageAttachment({
    required String conversationId,
    required String imageUrl,
    required ChannelType channel,
    required String senderName,
  }) async {
    // The backend has no attachment upload/send endpoint yet (sendMessage
    // only accepts { text } - see inbox.controller.ts). Surfacing this
    // honestly rather than faking a successful send.
    throw Exception('Sending image attachments isn\'t supported by the backend yet.');
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
