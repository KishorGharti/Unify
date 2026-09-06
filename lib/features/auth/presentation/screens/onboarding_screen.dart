import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/app_constants.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/widgets/algora_gradient_pill_button.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Icon accents stay within the same navy/blue family as the rest of the
  // auth flow, rather than the app's indigo/violet palette used elsewhere.
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'One Unified Inbox for Facebook & Instagram',
      'subtitle': 'Manage all customer conversations from your Facebook Pages and Instagram Business accounts in one single, high-speed mobile inbox.',
      'icon': Icons.all_inbox_rounded,
      'gradient': AppColors.authButtonGradient,
      'badge': 'Meta Official Partner Ready',
    },
    {
      'title': 'Collaborate With Your Support Team',
      'subtitle': 'Assign conversations to team agents, leave private internal notes, tag VIP clients, and track SLA response times effortlessly.',
      'icon': Icons.groups_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF1878B0), Color(0xFF0B2A4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'badge': 'Multi-Agent Routing',
    },
    {
      'title': 'Real-Time Replies & Live Webhooks',
      'subtitle': 'Never miss a potential customer inquiry. Experience instant incoming message sync, typing indicators, and quick canned responses.',
      'icon': Icons.bolt_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF2FA0DE), Color(0xFF071B2E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'badge': 'Instant Webhook Sync',
    },
  ];

  Future<void> _completeOnboarding() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setHasSeenOnboarding(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ALGORA', style: AppTypography.wordmark(color: Colors.white, fontSize: 24)),
                    TextButton(
                      onPressed: () async {
                        await _completeOnboarding();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: item['gradient'] as LinearGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 36,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Text(
                              item['badge'] as String,
                              style: AppTypography.badge(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: AppTypography.heading2(color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: AppTypography.body1(color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicator Dots & Buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index ? AppColors.authHeading : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_currentIndex == _slides.length - 1) ...[
                      // Invite-only: no self-serve signup. First-time visitors
                      // are shown how to request access instead of a sign-up form.
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Algora is invite-only. Contact us to get access:',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined, size: 16, color: AppColors.authHeading),
                                const SizedBox(width: 6),
                                SelectableText(
                                  AppConstants.contactEmail,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_outlined, size: 16, color: AppColors.authHeading),
                                const SizedBox(width: 6),
                                SelectableText(
                                  AppConstants.contactPhone,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AlgoraGradientPillButton(
                        text: 'I Have Access - Log In',
                        onPressed: () async {
                          await _completeOnboarding();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ] else ...[
                      AlgoraGradientPillButton(
                        text: 'Continue',
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
