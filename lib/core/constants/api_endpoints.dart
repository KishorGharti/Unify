class ApiEndpoints {
  // Points at the local backend (see backend/README.md). Swap the host for
  // your machine's LAN IP (e.g. 10.0.2.2 for the Android emulator) or your
  // deployed URL when not running against localhost.
  static const String baseUrl = 'http://localhost:4000/api/v1';
  static const String wsUrl = 'ws://localhost:4000';

  // Auth. Admin creates the account (see the /admin panel) - there's no
  // signup. Login is password-only. OTP exists solely to set/reset that
  // password (an admin's approval only ever generates a random one nobody
  // knows, so this also covers a brand new account's first-ever password).
  static const String login = '/auth/login';
  static const String passwordForgot = '/auth/password/forgot';
  static const String passwordReset = '/auth/password/reset';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Tenant / Business
  static const String tenants = '/tenants';
  static const String currentTenant = '/tenants/current';
  static const String teamMembers = '/tenants/current/members';
  static const String inviteMember = '/tenants/current/members/invite';
  static const String updateRole = '/tenants/current/members/{id}/role';

  // Channels / Meta Connections
  static const String channels = '/channels';
  static const String metaOauthStart = '/channels/meta/oauth/start';
  static const String facebookConnect = '/channels/meta/facebook/connect';
  static const String facebookPages = '/channels/meta/facebook/pages';
  static const String instagramConnect = '/channels/meta/instagram/connect';
  static const String instagramAccounts = '/channels/meta/instagram/accounts';
  static const String channelDisconnect = '/channels/{id}/disconnect';
  static const String channelHealth = '/channels/{id}/health';

  // Inbox & Conversations
  static const String conversations = '/inbox/conversations';
  static const String conversationDetail = '/inbox/conversations/{id}';
  static const String messages = '/inbox/conversations/{id}/messages';
  static const String sendMessage = '/inbox/conversations/{id}/messages';
  static const String assignConversation = '/inbox/conversations/{id}/assign';
  static const String updateStatus = '/inbox/conversations/{id}/status';
  static const String updateTags = '/inbox/conversations/{id}/tags';
  static const String addInternalNote = '/inbox/conversations/{id}/notes';

  // Customer Profile
  static const String customerProfile = '/customers/{id}';
  static const String updateCustomer = '/customers/{id}';

  // Analytics & Dashboard
  static const String dashboardMetrics = '/analytics/dashboard';
  static const String channelMetrics = '/analytics/channels';
}
