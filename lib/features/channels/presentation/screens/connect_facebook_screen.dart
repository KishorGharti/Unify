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

/// Real Meta OAuth: opens Facebook's login dialog in the system browser (see
/// backend/README.md section 2-3). There's no deep link registered to bring
/// the user straight back into the app after they approve it, so this asks
/// them to return and tap Continue manually once they're done.
class ConnectFacebookScreen extends ConsumerStatefulWidget {
  const ConnectFacebookScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectFacebookScreen> createState() => _ConnectFacebookScreenState();
}

enum _Step { permissions, openingBrowser, waitingForReturn, picker }

class _ConnectFacebookScreenState extends ConsumerState<ConnectFacebookScreen> {
  _Step _step = _Step.permissions;
  bool _isLoadingPages = false;
  String? _error;
  List<Map<String, dynamic>> _pages = [];
  String? _selectedPageId;

  Future<void> _startOAuthFlow() async {
    setState(() {
      _step = _Step.openingBrowser;
      _error = null;
    });

    try {
      final repo = ref.read(channelRepositoryProvider);
      final oauthUrl = await repo.startMetaOAuth();
      final uri = Uri.parse(oauthUrl);

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Could not open the browser for Facebook login.');

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
      _isLoadingPages = true;
      _error = null;
    });

    try {
      final repo = ref.read(channelRepositoryProvider);
      final pages = await repo.fetchAvailableFacebookPages();
      if (!mounted) return;
      setState(() {
        _pages = pages;
        if (pages.isNotEmpty) _selectedPageId = pages.first['id'] as String;
        _isLoadingPages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPages = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _connectSelectedPage() async {
    if (_selectedPageId == null) return;
    final selected = _pages.firstWhere((p) => p['id'] == _selectedPageId);

    final success = await ref.read(channelsProvider.notifier).connectFacebookPage(
          pageId: selected['id'],
          pageName: selected['name'],
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected ${selected['name']} successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(channelsProvider).errorMessage ?? 'Could not connect that Page.';
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
        title: const Text('Connect Facebook Page'),
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
        return _buildPermissionsStep(isDark);
      case _Step.openingBrowser:
        return _buildStatusStep(
          isDark: isDark,
          title: 'Opening Facebook Login...',
          subtitle: 'Requesting an authorization URL from the Algora server',
        );
      case _Step.waitingForReturn:
        return _buildWaitingForReturnStep(isDark);
      case _Step.picker:
        return _buildPageSelectionStep(isDark);
    }
  }

  Widget _buildPermissionsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.facebook,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.facebook_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Facebook Business Login',
                    style: AppTypography.heading3(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Official Meta OAuth 2.0 Flow',
                    style: AppTypography.caption(color: AppColors.facebook),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
        Text(
          'Permissions Required',
          style: AppTypography.subtitle1(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        _buildPermissionItem('pages_messaging', 'Allows Algora to receive and reply to Messenger inquiries from customers in real-time.'),
        const SizedBox(height: 8),
        _buildPermissionItem('pages_manage_metadata', 'Enables real-time webhook subscriptions for instant message notifications.'),
        const SizedBox(height: 8),
        _buildPermissionItem('pages_read_engagement', 'Allows retrieving customer name, profile avatar, and conversation status.'),
        const Spacer(),
        AlgoraButton(
          text: 'Continue to Facebook Authorization',
          onPressed: _startOAuthFlow,
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
              color: AppColors.facebook.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.facebook, size: 40),
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
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.facebook),
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
            color: AppColors.facebook.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.open_in_new_rounded, color: AppColors.facebook, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Finish in your browser',
          style: AppTypography.heading3(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 8),
        Text(
          'A browser tab opened for Facebook login. Approve access there, then come back here and continue.',
          textAlign: TextAlign.center,
          style: AppTypography.body2(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
          onPressed: _startOAuthFlow,
          child: const Text('Reopen the Facebook login page'),
        ),
      ],
    );
  }

  Widget _buildPageSelectionStep(bool isDark) {
    if (_isLoadingPages) {
      return const LoadingStateView(message: 'Retrieving your Facebook Pages...');
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

    if (_pages.isEmpty) {
      return Center(
        child: Text(
          'No Facebook Pages found for this account.',
          style: AppTypography.body1(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Facebook Page',
          style: AppTypography.heading2(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the Facebook Business Page you want to route into Algora Unified Inbox:',
          style: AppTypography.body2(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final page = _pages[index];
              final isSelected = _selectedPageId == page['id'];
              final alreadyConnected = page['is_connected'] == true;

              return AlgoraCard(
                onTap: alreadyConnected
                    ? null
                    : () {
                        setState(() {
                          _selectedPageId = page['id'];
                        });
                      },
                borderColor: isSelected ? AppColors.facebook : null,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.facebook,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page['name'] as String,
                            style: AppTypography.subtitle1(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${page['category'] ?? 'Page'} • ${(page['fan_count'] as int? ?? 0)} followers${alreadyConnected ? ' • Already connected' : ''}',
                            style: AppTypography.caption(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!alreadyConnected)
                      Radio<String>(
                        value: page['id'] as String,
                        groupValue: _selectedPageId,
                        activeColor: AppColors.facebook,
                        onChanged: (val) {
                          setState(() {
                            _selectedPageId = val;
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
          text: 'Connect Page to Inbox',
          onPressed: _connectSelectedPage,
          variant: AlgoraButtonVariant.gradient,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
