import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algora/core/constants/app_constants.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/validators.dart';
import 'package:algora/core/widgets/algora_gradient_pill_button.dart';
import 'package:algora/core/widgets/algora_pill_field.dart';
import 'package:algora/main.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

/// Password-only login. There's no signup screen at all - accounts are
/// created exclusively from the admin panel (see backend/README.md section
/// 6), which only ever generates a random, unknown password. First-time
/// users (and anyone who forgets theirs) go through "Forgot password?",
/// which emails a one-time code to set one - that's the only place OTP is
/// used.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else if (mounted) {
      final error = ref.read(authStateProvider).errorMessage ?? 'Invalid email or password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Text('ALGORA', style: AppTypography.wordmark(color: Colors.white)),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login',
                            style: AppTypography.heading1(color: AppColors.authHeading).copyWith(fontSize: 30),
                          ),
                          const SizedBox(height: 24),
                          AlgoraPillField(
                            hint: 'Email',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          AlgoraPillField(
                            hint: 'Password',
                            controller: _passwordController,
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text('Forget Password?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AlgoraGradientPillButton(
                            text: 'Login',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Column(
                              children: [
                                Text("Don't have access yet?", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  'Contact ${AppConstants.contactEmail} or ${AppConstants.contactPhone}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

