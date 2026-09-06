class BusinessTenantModel {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String planId;
  final String planTier;
  final int maxConnectedAccounts;
  final int maxTeamMembers;
  final DateTime createdAt;

  const BusinessTenantModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.planId,
    required this.planTier,
    this.maxConnectedAccounts = 5,
    this.maxTeamMembers = 10,
    required this.createdAt,
  });

  factory BusinessTenantModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return BusinessTenantModel(
      id: json['id'] as String,
      name: name,
      // The real backend only ever sends {id, name} for a tenant - slug is a
      // client-side-only convenience, so derive it when missing instead of
      // requiring the field.
      slug: (json['slug'] as String?) ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      logoUrl: json['logo_url'] as String?,
      planId: json['plan_id'] as String? ?? 'plan_starter',
      planTier: json['plan_tier'] as String? ?? 'Starter',
      maxConnectedAccounts: json['max_connected_accounts'] as int? ?? 5,
      maxTeamMembers: json['max_team_members'] as int? ?? 10,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'plan_id': planId,
        'plan_tier': planTier,
        'max_connected_accounts': maxConnectedAccounts,
        'max_team_members': maxTeamMembers,
        'created_at': createdAt.toIso8601String(),
      };
}
