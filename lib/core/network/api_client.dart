import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'api_interceptors.dart';
import 'api_response.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(SecureStorageService storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
      ),
    );

    _dio.interceptors.add(AuthInterceptor(storage));
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
      ),
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJsonT,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return ApiResponse<T>.fromJson(response.data, fromJsonT);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJsonT,
  }) async {
    final response = await _dio.post(path, data: data, queryParameters: queryParameters);
    return ApiResponse<T>.fromJson(response.data, fromJsonT);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic) fromJsonT,
  }) async {
    final response = await _dio.put(path, data: data);
    return ApiResponse<T>.fromJson(response.data, fromJsonT);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(dynamic) fromJsonT,
  }) async {
    final response = await _dio.delete(path);
    return ApiResponse<T>.fromJson(response.data, fromJsonT);
  }
}
