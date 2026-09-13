import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/utils/validators.dart';
import 'package:unify/core/widgets/unify_gradient_pill_button.dart';
import 'package:unify/core/widgets/unify_pill_field.dart';
import 'package:unify/main.dart';
import '../providers/auth_provider.dart';

enum _ResetStep { email, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _handleSendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).requestPasswordReset(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (success && mounted) {
      setState(() => _step = _ResetStep.reset);
      _startCooldown();
    } else if (mounted) {
      final error = ref.read(authStateProvider).errorMessage ?? 'Could not send the code. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _codeController.text.trim(),
          _newPasswordController.text,
        );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You are logged in.'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } else if (mounted) {
      final error = ref.read(authStateProvider).errorMessage ?? 'Could not reset the password. Please try again.';
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
                  const SizedBox(height: 40),
                  Text('UNIFY', style: AppTypography.wordmark(color: Colors.white, fontSize: 32)),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text('Back to Login', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Reset Password',
                          style: AppTypography.heading1(color: AppColors.authHeading).copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == _ResetStep.email
                              ? 'Enter your account email to receive a reset code'
                              : 'Enter the code we emailed you and choose a new password',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        if (_step == _ResetStep.email) _buildEmailStep() else _buildResetStep(),
                      ],
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

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifyPillField(
            hint: 'Email',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 24),
          UnifyGradientPillButton(
            text: 'Send Reset Code',
            onPressed: _handleSendCode,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _emailController.text.trim(),
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _step = _ResetStep.email),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          UnifyPillField(
            hint: '6-Digit Code',
            controller: _codeController,
            icon: Icons.lock_outline_rounded,
            keyboardType: TextInputType.number,
            validator: Validators.validateOtpCode,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: (_isLoading || _resendCooldown > 0) ? null : _handleSendCode,
              child: Text(_resendCooldown > 0 ? 'Resend code in ${_resendCooldown}s' : 'Resend code'),
            ),
          ),
          const SizedBox(height: 8),
          UnifyPillField(
            hint: 'New Password',
            controller: _newPasswordController,
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 24),
          UnifyGradientPillButton(
            text: 'Reset Password & Log In',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
