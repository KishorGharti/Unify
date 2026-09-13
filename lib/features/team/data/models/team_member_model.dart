import 'package:unify/features/auth/data/models/user_model.dart';

class TeamMemberModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final int activeAssignedConversations;
  final bool isOnline;
  final DateTime joinedAt;

  const TeamMemberModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.activeAssignedConversations = 0,
    this.isOnline = false,
    required this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'agent'),
      avatarUrl: json['avatar_url'] as String?,
      activeAssignedConversations: json['active_assigned_conversations'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role.name,
        'avatar_url': avatarUrl,
        'active_assigned_conversations': activeAssignedConversations,
        'is_online': isOnline,
        'joined_at': joinedAt.toIso8601String(),
      };
}
