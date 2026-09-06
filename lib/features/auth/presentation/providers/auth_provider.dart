import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/network/api_client.dart';
import 'package:algora/core/storage/secure_storage.dart';
import 'package:algora/features/auth/data/auth_repository.dart';
import 'package:algora/features/auth/data/models/user_model.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AlgoraAuthRepository(apiClient: apiClient, storage: storage);
});

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getCachedUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = AuthState.initial().copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState.initial().copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _message(e),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: _message(e));
      return false;
    }
  }

  /// Step 1 of setting/resetting a password: emails a one-time code to
  /// [email]. Covers both a brand new account's first-ever password and a
  /// genuinely forgotten one.
  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.requestPasswordReset(email);
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: _message(e));
      return false;
    }
  }

  /// Step 2 of password reset: sets [newPassword] using the emailed [code],
  /// and logs the device in.
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.resetPassword(email, code, newPassword);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: _message(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = AuthState.initial().copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> switchTenant(String tenantId) async {
    await _repository.switchTenant(tenantId);
    final user = await _repository.getCachedUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
