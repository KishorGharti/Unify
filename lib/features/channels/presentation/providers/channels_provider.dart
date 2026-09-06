import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/features/auth/presentation/providers/auth_provider.dart';
import 'package:algora/features/channels/data/channel_repository.dart';
import 'package:algora/features/channels/data/models/connected_account_model.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlgoraChannelRepository(apiClient: apiClient);
});

class ChannelsState {
  final bool isLoading;
  final List<ConnectedAccountModel> accounts;
  final String? errorMessage;
  final String? successMessage;

  const ChannelsState({
    this.isLoading = false,
    this.accounts = const [],
    this.errorMessage,
    this.successMessage,
  });

  ChannelsState copyWith({
    bool? isLoading,
    List<ConnectedAccountModel>? accounts,
    String? errorMessage,
    String? successMessage,
  }) {
    return ChannelsState(
      isLoading: isLoading ?? this.isLoading,
      accounts: accounts ?? this.accounts,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ChannelsNotifier extends StateNotifier<ChannelsState> {
  final ChannelRepository _repository;
  final String _tenantId;

  ChannelsNotifier(this._repository, this._tenantId) : super(const ChannelsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final accounts = await _repository.getConnectedAccounts(_tenantId);
      state = state.copyWith(isLoading: false, accounts: accounts);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> connectFacebookPage({required String pageId, required String pageName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _repository.connectFacebookPage(pageId: pageId);
      state = state.copyWith(
        isLoading: false,
        accounts: [...state.accounts.where((a) => a.id != account.id), account],
        successMessage: 'Successfully connected $pageName to Algora!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> connectInstagramAccount({required String igUserId, required String pageId, required String username}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _repository.connectInstagramAccount(igUserId: igUserId, pageId: pageId);
      state = state.copyWith(
        isLoading: false,
        accounts: [...state.accounts.where((a) => a.id != account.id), account],
        successMessage: 'Successfully connected $username Instagram account!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> disconnectAccount(String channelId) async {
    try {
      await _repository.disconnectChannel(channelId);
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != channelId).toList(),
        successMessage: 'Channel disconnected.',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final channelsProvider = StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  final repo = ref.watch(channelRepositoryProvider);
  final auth = ref.watch(authStateProvider);
  final tenantId = auth.user?.tenantId ?? '';
  return ChannelsNotifier(repo, tenantId);
});
