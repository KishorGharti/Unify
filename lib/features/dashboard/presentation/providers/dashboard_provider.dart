import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/api_endpoints.dart';
import 'package:algora/core/errors/app_exceptions.dart';
import 'package:algora/core/network/api_client.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/dashboard/data/models/dashboard_metrics.dart';

class DashboardState {
  final bool isLoading;
  final DashboardMetricsModel? metrics;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.metrics,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardMetricsModel? metrics,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      errorMessage: errorMessage,
    );
  }
}

/// Talks to the real backend (see backend/src/controllers/analytics.controller.ts)
/// - every number here is computed from this tenant's actual conversations
/// and messages, not sample data. A fresh workspace with nothing connected
/// yet correctly shows zeros, not a bug.
class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;

  DashboardNotifier(this._apiClient) : super(const DashboardState()) {
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardMetrics,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, metrics: DashboardMetricsModel.fromJson(response.data!));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendlyMessage(e));
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

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient);
});
