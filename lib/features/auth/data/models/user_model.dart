import 'tenant_model.dart';

enum UserRole {
  owner,
  admin,
  agent;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Workspace Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.agent:
        return 'Support Agent';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'agent':
      default:
        return UserRole.agent;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final UserRole role;
  final String tenantId;
  final BusinessTenantModel? currentTenant;
  final List<BusinessTenantModel> availableTenants;
  final DateTime createdAt;

  final bool hasPassword;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.tenantId,
    this.currentTenant,
    this.availableTenants = const [],
    required this.createdAt,
    this.hasPassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'agent'),
      tenantId: json['tenant_id'] as String,
      currentTenant: json['current_tenant'] != null
          ? BusinessTenantModel.fromJson(json['current_tenant'])
          : null,
      availableTenants: (json['available_tenants'] as List<dynamic>?)
              ?.map((e) => BusinessTenantModel.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      hasPassword: json['has_password'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'role': role.name,
        'tenant_id': tenantId,
        'current_tenant': currentTenant?.toJson(),
        'available_tenants': availableTenants.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'has_password': hasPassword,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    String? tenantId,
    BusinessTenantModel? currentTenant,
    List<BusinessTenantModel>? availableTenants,
    DateTime? createdAt,
    bool? hasPassword,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      currentTenant: currentTenant ?? this.currentTenant,
      availableTenants: availableTenants ?? this.availableTenants,
      createdAt: createdAt ?? this.createdAt,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}
