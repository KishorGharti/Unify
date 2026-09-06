import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/features/auth/data/models/user_model.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/team/data/models/team_member_model.dart';

class TeamState {
  final bool isLoading;
  final List<TeamMemberModel> members;
  final String? errorMessage;
  final String? successMessage;

  const TeamState({
    this.isLoading = false,
    this.members = const [],
    this.errorMessage,
    this.successMessage,
  });

  TeamState copyWith({
    bool? isLoading,
    List<TeamMemberModel>? members,
    String? errorMessage,
    String? successMessage,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final String _tenantId;

  TeamNotifier(this._tenantId) : super(const TeamState()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 350));

    final sampleMembers = [
      TeamMemberModel(
        id: 'usr_sarah_01',
        fullName: 'Sarah Jenkins',
        email: 'sarah.jenkins@acmegroup.com',
        role: UserRole.owner,
        activeAssignedConversations: 14,
        isOnline: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      TeamMemberModel(
        id: 'usr_alex_02',
        fullName: 'Alex Rivera',
        email: 'alex.rivera@acmegroup.com',
        role: UserRole.admin,
        activeAssignedConversations: 8,
        isOnline: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      TeamMemberModel(
        id: 'usr_elena_03',
        fullName: 'Elena Rostova',
        email: 'elena.rostova@acmegroup.com',
        role: UserRole.agent,
        activeAssignedConversations: 5,
        isOnline: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      TeamMemberModel(
        id: 'usr_liam_04',
        fullName: 'Liam Thorne',
        email: 'liam.thorne@acmegroup.com',
        role: UserRole.agent,
        activeAssignedConversations: 3,
        isOnline: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    state = state.copyWith(isLoading: false, members: sampleMembers);
  }

  Future<bool> inviteMember({
    required String fullName,
    required String email,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 500));

    final newMember = TeamMemberModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      role: role,
      activeAssignedConversations: 0,
      isOnline: false,
      joinedAt: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: false,
      members: [...state.members, newMember],
      successMessage: 'Invitation email sent to $email!',
    );
    return true;
  }

  Future<void> removeMember(String memberId) async {
    state = state.copyWith(
      members: state.members.where((m) => m.id != memberId).toList(),
      successMessage: 'Team member removed from workspace.',
    );
  }
}

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  final auth = ref.watch(authStateProvider);
  final tenantId = auth.user?.tenantId ?? 'tenant_acme_01';
  return TeamNotifier(tenantId);
});
