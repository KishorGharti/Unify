class AppConstants {
  static const String appName = 'Algora';
  static const String appTagline = 'Unified Business Messaging for Meta';
  static const String appVersion = '1.0.0';

  // Algora is invite-only - shown on first launch and told to people without
  // access yet so they know how to request it.
  static const String contactEmail = 'thealgora99@gmail.com';
  static const String contactPhone = '9866225251';

  // Storage Keys
  static const String keyAuthToken = 'algora_auth_token';
  static const String keyRefreshToken = 'algora_refresh_token';
  static const String keyCurrentTenantId = 'algora_current_tenant_id';
  static const String keyUserSession = 'algora_user_session';
  static const String keyThemeMode = 'algora_theme_mode';
  static const String keyHasSeenOnboarding = 'algora_has_seen_onboarding';
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration wsHeartbeatInterval = Duration(seconds: 25);
  static const Duration wsReconnectDelay = Duration(seconds: 3);

  // Pagination
  static const int defaultPageSize = 25;
}
