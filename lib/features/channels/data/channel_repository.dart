import 'package:dio/dio.dart';
import 'package:algora/core/constants/api_endpoints.dart';
import 'package:algora/core/errors/app_exceptions.dart';
import 'package:algora/core/network/api_client.dart';
import 'models/connected_account_model.dart';

abstract class ChannelRepository {
  Future<List<ConnectedAccountModel>> getConnectedAccounts(String tenantId);

  /// Step 1 of the real Meta OAuth flow: asks the backend for the Facebook
  /// Login dialog URL (see backend/src/controllers/channels.controller.ts
  /// startOAuth). Requires META_APP_ID/SECRET to be configured server-side.
  Future<String> startMetaOAuth();

  /// Pages found in the most recent OAuth session (see startMetaOAuth) -
  /// only populated after the user actually completes Meta's login in the
  /// browser, so this legitimately 409s otherwise.
  Future<List<Map<String, dynamic>>> fetchAvailableFacebookPages();
  Future<List<Map<String, dynamic>>> fetchAvailableInstagramAccounts();
  Future<ConnectedAccountModel> connectFacebookPage({required String pageId});
  Future<ConnectedAccountModel> connectInstagramAccount({required String igUserId, required String pageId});
  Future<void> disconnectChannel(String channelId);
  Future<void> testWebhookHealth(String channelId);
}

/// Talks to the real backend. There's no sample/mock connected-account data
/// here - an empty list means no Facebook Page or Instagram account has
/// actually been connected yet.
class AlgoraChannelRepository implements ChannelRepository {
  final ApiClient apiClient;

  AlgoraChannelRepository({required this.apiClient});

  @override
  Future<List<ConnectedAccountModel>> getConnectedAccounts(String tenantId) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.channels,
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? []).map((e) => ConnectedAccountModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<String> startMetaOAuth() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.metaOauthStart,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return response.data!['oauth_url'] as String;
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableFacebookPages() async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.facebookPages,
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableInstagramAccounts() async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.instagramAccounts,
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<ConnectedAccountModel> connectFacebookPage({required String pageId}) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.facebookConnect,
        data: {'page_id': pageId},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return ConnectedAccountModel.fromJson(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<ConnectedAccountModel> connectInstagramAccount({required String igUserId, required String pageId}) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.instagramConnect,
        data: {'ig_user_id': igUserId, 'page_id': pageId},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return ConnectedAccountModel.fromJson(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> disconnectChannel(String channelId) async {
    try {
      await apiClient.post<dynamic>(
        ApiEndpoints.channelDisconnect.replaceAll('{id}', channelId),
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> testWebhookHealth(String channelId) async {
    try {
      await apiClient.get<dynamic>(
        ApiEndpoints.channelHealth.replaceAll('{id}', channelId),
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
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
