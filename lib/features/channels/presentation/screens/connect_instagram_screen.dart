import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/widgets/algora_button.dart';
import 'package:algora/core/widgets/algora_card.dart';
import 'package:algora/core/widgets/loading_state_view.dart';
import 'package:algora/features/channels/presentation/providers/channels_provider.dart';

/// Real Meta OAuth - Instagram Business/Creator accounts are discovered
/// through the same Facebook Login flow as Pages (an IG account is always
/// linked to a Page). See connect_facebook_screen.dart for the browser
/// hand-off details; this mirrors it for the Instagram picker.
class ConnectInstagramScreen extends ConsumerStatefulWidget {
  const ConnectInstagramScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectInstagramScreen> createState() => _ConnectInstagramScreenState();
}

enum _Step { permissions, openingBrowser, waitingForReturn, picker }

class _ConnectInstagramScreenState extends ConsumerState<ConnectInstagramScreen> {
  _Step _step = _Step.permissions;
  bool _isLoadingAccounts = false;
  String? _error;
  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;

  Future<void> _startInstagramAuth() async {
    setState(() {
      _step = _Step.openingBrowser;
      _error = null;
    });

    try {
      final repo = ref.read(channelRepositoryProvider);
      final oauthUrl = await repo.startMetaOAuth();
      final uri = Uri.parse(oauthUrl);

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Could not open the browser for Instagram login.');

      if (!mounted) return;
      setState(() => _step = _Step.waitingForReturn);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.permissions;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _continueAfterBrowser() async {
    setState(() {
      _step = _Step.picker;
      _isLoadingAccounts = true;
      _error = null;
    });

    try {
      final repo = ref.read(channelRepositoryProvider);
      final accounts = await repo.fetchAvailableInstagramAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty) _selectedAccountId = accounts.first['id'] as String;
        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAccounts = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _connectSelectedAccount() async {
    if (_selectedAccountId == null) return;
    final selected = _accounts.firstWhere((a) => a['id'] == _selectedAccountId);

    final success = await ref.read(channelsProvider.notifier).connectInstagramAccount(
          igUserId: selected['id'] as String,
          pageId: selected['_linkedPageId'] as String,
          username: selected['username'] as String,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected ${selected['username']} successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(channelsProvider).errorMessage ?? 'Could not connect that account.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Connect Instagram Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_step) {
      case _Step.permissions:
        return _buildRequirementsStep(isDark);
      case _Step.openingBrowser:
        return _buildStatusStep(
          isDark: isDark,
          title: 'Opening Instagram Login...',
          subtitle: 'Requesting an authorization URL from the Algora server',
        );
      case _Step.waitingForReturn:
        return _buildWaitingForReturnStep(isDark);
      case _Step.picker:
        return _buildAccountPickerStep(isDark);
    }
  }

  Widget _buildRequirementsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.instagramGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instagram Professional Direct',
                    style: AppTypography.heading3(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Instagram Graph API Integration',
                    style: AppTypography.caption(color: AppColors.instagram),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // Pre-requisite checklist
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: AppDimensions.roundedLg,
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Meta requires Instagram accounts to be set as "Business" or "Creator" and linked to a Facebook Page to enable API messaging.',
                  style: AppTypography.body2(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'API Permissions Requested',
          style: AppTypography.subtitle1(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 10),
        _buildPermissionItem('instagram_basic', 'Access basic profile information and username.'),
        const SizedBox(height: 8),
        _buildPermissionItem('instagram_manage_messages', 'Receive and reply to Direct Messages, story mentions, and replies.'),
        const Spacer(),
        AlgoraButton(
          text: 'Login with Meta / Instagram',
          onPressed: _startInstagramAuth,
          variant: AlgoraButtonVariant.gradient,
          icon: Icons.open_in_browser_rounded,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPermissionItem(String code, String desc) {
    return AlgoraCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep({required bool isDark, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.instagramGradient.scale(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.heading3(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body2(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.instagram),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForReturnStep(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.instagramGradient.scale(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Finish in your browser',
          style: AppTypography.heading3(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 8),
        Text(
          'A browser tab opened for Instagram/Facebook login. Approve access there, then come back here and continue.',
          textAlign: TextAlign.center,
          style: AppTypography.body2(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryDark),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 32),
        AlgoraButton(
          text: "I've Authorized - Continue",
          onPressed: _continueAfterBrowser,
          variant: AlgoraButtonVariant.gradient,
          width: double.infinity,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _startInstagramAuth,
          child: const Text('Reopen the login page'),
        ),
      ],
    );
  }

  Widget _buildAccountPickerStep(bool isDark) {
    if (_isLoadingAccounts) {
      return const LoadingStateView(message: 'Loading linked Instagram profiles...');
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 20),
          AlgoraButton(text: 'Try Again', onPressed: _continueAfterBrowser, variant: AlgoraButtonVariant.outline),
        ],
      );
    }

    if (_accounts.isEmpty) {
      return Center(
        child: Text(
          'No linked Instagram Business/Creator accounts found.',
          style: AppTypography.body1(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryDark),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Instagram Account',
          style: AppTypography.heading2(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the Instagram Business account to connect to Algora:',
          style: AppTypography.body2(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final acc = _accounts[index];
              final isSelected = _selectedAccountId == acc['id'];
              final alreadyConnected = acc['is_connected'] == true;

              return AlgoraCard(
                onTap: alreadyConnected
                    ? null
                    : () {
                        setState(() {
                          _selectedAccountId = acc['id'] as String;
                        });
                      },
                borderColor: isSelected ? AppColors.instagram : null,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: AppColors.instagramGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc['username'] as String,
                            style: AppTypography.subtitle1(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${acc['name']} • ${(acc['followers_count'] as int? ?? 0)} followers${alreadyConnected ? ' • Already connected' : ''}',
                            style: AppTypography.caption(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          Text(
                            'Linked Page: ${acc['linked_page']}',
                            style: AppTypography.caption(color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    ),
                    if (!alreadyConnected)
                      Radio<String>(
                        value: acc['id'] as String,
                        groupValue: _selectedAccountId,
                        activeColor: AppColors.instagram,
                        onChanged: (val) {
                          setState(() {
                            _selectedAccountId = val;
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        AlgoraButton(
          text: 'Connect Instagram to Inbox',
          onPressed: _connectSelectedAccount,
          variant: AlgoraButtonVariant.gradient,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
