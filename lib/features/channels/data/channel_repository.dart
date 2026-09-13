import 'package:dio/dio.dart';
import 'package:unify/core/constants/api_endpoints.dart';
import 'package:unify/core/errors/app_exceptions.dart';
import 'package:unify/core/network/api_client.dart';
import 'models/connected_account_model.dart';

abstract class ChannelRepository {
  Future<List<ConnectedAccountModel>> getConnectedAccounts(String tenantId);

  Future<String> startMetaOAuth();

  Future<List<Map<String, dynamic>>> fetchAvailableFacebookPages();
  Future<List<Map<String, dynamic>>> fetchAvailableInstagramAccounts();
  Future<ConnectedAccountModel> connectFacebookPage({required String pageId});
  Future<ConnectedAccountModel> connectInstagramAccount({required String igUserId, required String pageId});

  Future<String> startInstagramLoginOAuth();
  Future<List<Map<String, dynamic>>> fetchAvailableInstagramLoginAccounts();
  Future<ConnectedAccountModel> connectInstagramLoginAccount({required String igUserId});

  Future<void> disconnectChannel(String channelId);
  Future<void> testWebhookHealth(String channelId);
}

class UnifyChannelRepository implements ChannelRepository {
  final ApiClient apiClient;

  UnifyChannelRepository({required this.apiClient});

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
  Future<String> startInstagramLoginOAuth() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.instagramLoginOauthStart,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return response.data!['oauth_url'] as String;
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableInstagramLoginAccounts() async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.instagramLoginAccounts,
        fromJsonT: (json) => json as List<dynamic>,
      );
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<ConnectedAccountModel> connectInstagramLoginAccount({required String igUserId}) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.instagramLoginConnect,
        data: {'ig_user_id': igUserId},
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
