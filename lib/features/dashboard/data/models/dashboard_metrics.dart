class DashboardMetricsModel {
  final int totalConversations;
  final int openConversations;
  final int resolvedToday;
  final String avgResponseTime;
  final double resolutionRate;
  final int facebookInquiries;
  final int instagramInquiries;
  final List<RecentActivityItem> recentActivities;

  const DashboardMetricsModel({
    required this.totalConversations,
    required this.openConversations,
    required this.resolvedToday,
    required this.avgResponseTime,
    required this.resolutionRate,
    required this.facebookInquiries,
    required this.instagramInquiries,
    this.recentActivities = const [],
  });

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      totalConversations: json['total_conversations'] as int? ?? 0,
      openConversations: json['open_conversations'] as int? ?? 0,
      resolvedToday: json['resolved_today'] as int? ?? 0,
      avgResponseTime: json['avg_response_time'] as String? ?? '—',
      resolutionRate: (json['resolution_rate'] as num?)?.toDouble() ?? 0,
      facebookInquiries: json['facebook_inquiries'] as int? ?? 0,
      instagramInquiries: json['instagram_inquiries'] as int? ?? 0,
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => RecentActivityItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentActivityItem {
  final String id;
  final String title;
  final String description;
  final String channel;
  final DateTime timestamp;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.channel,
    required this.timestamp,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      channel: json['channel'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
