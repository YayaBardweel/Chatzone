// ============================================================================
// File: lib/presentation/pages/auth/email_verification_page.dart (NEW)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _checkTimer;
  bool _isResendingEmail = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startVerificationCheck();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startVerificationCheck() {
    print('🔄 DEBUG: Email Verification UI - Starting verification check');

    // Check every 8 seconds if email is verified (reduced frequency)
    _checkTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        print('🔍 DEBUG: Email Verification UI - Periodic check...');
        bool isVerified = await authProvider.checkEmailVerification();

        if (isVerified) {
          print('✅ DEBUG: Email Verification UI - Email verified! Stopping timer');
          timer.cancel();
          _showSuccessAndNavigate();
        } else {
          print('⏳ DEBUG: Email Verification UI - Still not verified');
        }
      } catch (e) {
        print('❌ DEBUG: Email Verification UI - Check failed: $e');
        // Continue checking despite errors
      }
    });
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.verified, color: Colors.white),
            SizedBox(width: 8),
            Text('Email verified successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );

    // Navigate to home or profile setup
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        AppRouter.goToHome(context);
      }
    });
  }

  void _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResendingEmail = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendEmailVerification();

    setState(() {
      _isResendingEmail = false;
    });

    if (success) {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.email, color: Colors.white),
              SizedBox(width: 8),
              Text('Verification email sent!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
    } else {
      _showError(authProvider.errorMessage ?? 'Failed to resend email');
    }
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }

  void _changeEmail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email?'),
        content: const Text(
          'To change your email address, you\'ll need to create a new account. Would you like to go back to sign up?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppRouter.goToSignUp(context);
            },
            child: const Text('Change Email'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      AppRouter.goToLogin(context);
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Header with animated icon
                          _buildHeader(authProvider),

                          const SizedBox(height: 40),

                          // Email info
                          _buildEmailInfo(authProvider),

                          const SizedBox(height: 40),

                          // Instructions
                          _buildInstructions(),

                          const SizedBox(height: 40),

                          // Action buttons
                          _buildActionButtons(),

                          const SizedBox(height: 30),

                          // Help text
                          _buildHelpText(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Column(
      children: [
        // Animated email icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  authProvider.isEmailVerified
                      ? Icons.mark_email_read_rounded
                      : Icons.email_rounded,
                  size: 50,
                  color: authProvider.isEmailVerified
                      ? Colors.green
                      : AppColors.primary,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          authProvider.isEmailVerified
              ? 'Email Verified!'
              : 'Check Your Email',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInfo(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.alternate_email,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),

          Text(
            authProvider.currentUserEmail ?? 'your-email@example.com',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          GestureDetector(
            onTap: _changeEmail,
            child: Text(
              'Wrong email?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          'We sent a verification link to your email address.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        const Text(
          'Click the link in the email to verify your account. It may take a few minutes to arrive.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check your spam folder if you don\'t see the email.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resend email button
        CustomButton(
          text: _isResendingEmail
              ? 'Sending...'
              : _resendCooldown > 0
              ? 'Resend in ${_resendCooldown}s'
              : 'Resend Verification Email',
          onPressed: _resendCooldown > 0 || _isResendingEmail ? null : _resendVerificationEmail,
          type: ButtonType.outline,
          size: ButtonSize.medium,
          icon: _isResendingEmail ? null : Icons.refresh_rounded,
          isLoading: _isResendingEmail,
        ),

        const SizedBox(height: 16),

        // Manual check button
        CustomButton(
          text: 'I\'ve Verified My Email',
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final isVerified = await authProvider.checkEmailVerification();

            if (isVerified) {
              _showSuccessAndNavigate();
            } else {
              _showError('Email not verified yet. Please check your email and click the verification link.');
            }
          },
          type: ButtonType.primary,
          size: ButtonSize.medium,
          icon: Icons.verified_rounded,
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Still having trouble?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure to check your spam/junk folder. If you still don\'t receive the email, try resending it or contact support.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}