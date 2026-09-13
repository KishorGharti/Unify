class ApiEndpoints {

  static const String baseUrl = 'http://localhost:4000/api/v1';
  static const String wsUrl = 'ws://localhost:4000';

  static const String login = '/auth/login';
  static const String passwordForgot = '/auth/password/forgot';
  static const String passwordReset = '/auth/password/reset';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String tenants = '/tenants';
  static const String currentTenant = '/tenants/current';
  static const String teamMembers = '/tenants/current/members';
  static const String inviteMember = '/tenants/current/members/invite';
  static const String updateRole = '/tenants/current/members/{id}/role';

  static const String channels = '/channels';
  static const String metaOauthStart = '/channels/meta/oauth/start';
  static const String facebookConnect = '/channels/meta/facebook/connect';
  static const String facebookPages = '/channels/meta/facebook/pages';
  static const String instagramConnect = '/channels/meta/instagram/connect';
  static const String instagramAccounts = '/channels/meta/instagram/accounts';

  static const String instagramLoginOauthStart = '/channels/meta/instagram-login/oauth/start';
  static const String instagramLoginAccounts = '/channels/meta/instagram-login/accounts';
  static const String instagramLoginConnect = '/channels/meta/instagram-login/connect';

  static const String channelDisconnect = '/channels/{id}/disconnect';
  static const String channelHealth = '/channels/{id}/health';

  static const String conversations = '/inbox/conversations';
  static const String conversationDetail = '/inbox/conversations/{id}';
  static const String messages = '/inbox/conversations/{id}/messages';
  static const String sendMessage = '/inbox/conversations/{id}/messages';
  static const String assignConversation = '/inbox/conversations/{id}/assign';
  static const String updateStatus = '/inbox/conversations/{id}/status';
  static const String updateTags = '/inbox/conversations/{id}/tags';
  static const String addInternalNote = '/inbox/conversations/{id}/notes';

  static const String customerProfile = '/customers/{id}';
  static const String updateCustomer = '/customers/{id}';

  static const String dashboardMetrics = '/analytics/dashboard';
  static const String channelMetrics = '/analytics/channels';
}
