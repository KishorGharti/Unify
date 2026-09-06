import 'package:dio/dio.dart';
import 'package:algora/core/constants/api_endpoints.dart';
import 'package:algora/core/errors/app_exceptions.dart';
import 'package:algora/core/network/api_client.dart';
import 'package:algora/core/storage/secure_storage.dart';
import 'models/user_model.dart';

/// Accounts are created by an admin (see the /admin panel's "Approve a new
/// email") - there is no signup in the app. Login is password-only. OTP
/// exists solely to set/reset that password (requestPasswordReset then
/// resetPassword) - an admin's approval only ever generates a random
/// password nobody knows, so this also covers a brand new account's
/// first-ever password, not just a forgotten one.
abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> requestPasswordReset(String email);
  Future<UserModel> resetPassword(String email, String code, String newPassword);
  Future<void> logout();
  Future<UserModel?> getCachedUser();
  Future<void> switchTenant(String tenantId);
}

class AlgoraAuthRepository implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  UserModel? _currentUser;

  AlgoraAuthRepository({required this.apiClient, required this.storage});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return await _handleAuthResponse(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await apiClient.post<dynamic>(
        ApiEndpoints.passwordForgot,
        data: {'email': email},
        fromJsonT: (json) => json,
      );
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  @override
  Future<UserModel> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.passwordReset,
        data: {'email': email, 'code': code, 'new_password': newPassword},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return await _handleAuthResponse(response.data!);
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Shared by login/resetPassword - both return the same {token, user}
  /// shape and log the device in the same way.
  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await storage.saveAuthToken(token);
    await storage.saveTenantId(user.tenantId);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post<dynamic>(ApiEndpoints.logout, fromJsonT: (json) => json);
    } catch (_) {
      // Stateless JWT - even if this call fails (offline, expired token,
      // etc), clearing local state below still logs the device out.
    }
    await storage.clearAll();
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final token = storage.getAuthToken();
    if (token == null) return null;
    if (_currentUser != null) return _currentUser;

    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.me,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      _currentUser = UserModel.fromJson(response.data!);
      return _currentUser;
    } catch (_) {
      // Token invalid/expired - treat as logged out.
      await storage.clearAll();
      return null;
    }
  }

  @override
  Future<void> switchTenant(String tenantId) async {
    // Multi-tenant switching isn't implemented on the backend yet (single
    // tenant per user for now) - this just keeps the locally-selected id in
    // sync for whichever tenant is already on the cached user.
    await storage.saveTenantId(tenantId);
    if (_currentUser != null) {
      final newTenant = _currentUser!.availableTenants.firstWhere(
        (t) => t.id == tenantId,
        orElse: () => _currentUser!.currentTenant!,
      );
      _currentUser = _currentUser!.copyWith(
        tenantId: tenantId,
        currentTenant: newTenant,
      );
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
