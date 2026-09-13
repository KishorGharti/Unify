class AppConstants {
  static const String appName = 'Unify';
  static const String appTagline = 'Unified Business Messaging for Meta';
  static const String appVersion = '1.0.0';

  static const String contactEmail = 'thealgora99@gmail.com';
  static const String contactPhone = '9866225251';

  static const String keyAuthToken = 'unify_auth_token';
  static const String keyRefreshToken = 'unify_refresh_token';
  static const String keyCurrentTenantId = 'unify_current_tenant_id';
  static const String keyUserSession = 'unify_user_session';
  static const String keyThemeMode = 'unify_theme_mode';
  static const String keyHasSeenOnboarding = 'unify_has_seen_onboarding';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration wsHeartbeatInterval = Duration(seconds: 25);
  static const Duration wsReconnectDelay = Duration(seconds: 3);

  static const int defaultPageSize = 25;
}
