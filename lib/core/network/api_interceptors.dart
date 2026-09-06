import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final tenantId = _storage.getTenantId();
    if (tenantId != null && tenantId.isNotEmpty) {
      options.headers['X-Tenant-ID'] = tenantId;
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  // Deliberately just passes every error through unchanged (handler.next).
  // Throwing a replacement exception here gets re-wrapped by Dio as it
  // passes through the next interceptor in the chain (LogInterceptor, added
  // after this one in api_client.dart) - that re-wrap drops the original
  // `err.response`, which is exactly what carries the backend's actual
  // message ("Incorrect code.", "Invalid email or password.", etc), leaving
  // callers with nothing but a generic fallback. Repositories read the real
  // message straight off `err.response.data` themselves (see
  // auth_repository.dart's _friendlyMessage) - that only works if the
  // response survives intact, so nothing here should replace or discard it.
}
