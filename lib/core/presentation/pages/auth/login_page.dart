// ============================================================================
// File: lib/core/presentation/pages/auth/login_page.dart (CLEAN REBUILD)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../routes/app_router.dart';
import '../../../utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ============================================================================
  // CONTROLLERS & FOCUS NODES
  // ============================================================================

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // ============================================================================
  // ANIMATIONS
  // ============================================================================

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
  }

  // ============================================================================
  // AUTHENTICATION ACTIONS
  // ============================================================================

  /// Handle sign in
  void _signIn() async {
    // Clear any existing errors
    context.read<AuthProvider>().clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('🔥 LoginPage: Starting sign in process');

    // Attempt sign in
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      print('✅ LoginPage: Sign in successful');
      _navigateAfterSignIn();
    } else {
      print('❌ LoginPage: Sign in failed');
      _showError(authProvider.error ?? 'Sign in failed');
    }
  }

  /// Navigate after successful sign in
  void _navigateAfterSignIn() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isEmailVerified) {
      // Email verified - go to home
      print('🏠 LoginPage: Email verified, going to home');
      AppRouter.goToHome(context);
    } else {
      // Email not verified - go to verification
      print('📧 LoginPage: Email not verified, going to verification');
      AppRouter.goToEmailVerification(context);
    }
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void _goToSignUp() {
    print('🔗 LoginPage: Going to sign up');
    AppRouter.goToSignUp(context);
  }

  void _goToForgotPassword() {
    print('🔗 LoginPage: Going to forgot password');
    AppRouter.goToForgotPassword(context, _emailController.text.trim());
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

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

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading overlay
            if (authProvider.isLoading) {
              return const Center(
                child: LoadingWidget(
                  type: LoadingType.pulse,
                  message: 'Signing in...',
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 50),
                          _buildLoginForm(),
                          const SizedBox(height: 30),
                          _buildSignInButton(),
                          const SizedBox(height: 20),
                          _buildForgotPasswordButton(),
                          const SizedBox(height: 40),
                          _buildSignUpLink(),
                          const SizedBox(height: 30),
                          _buildTermsText(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App logo and name
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Welcome text
        const Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Sign in to your account to continue',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hintText: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            prefixIcon: const Icon(Icons.email_outlined),
            onChanged: (value) {
              // Clear errors when user types
              context.read<AuthProvider>().clearError();
            },
            onTap: () {
              // Clear errors when field is tapped
              context.read<AuthProvider>().clearError();
            },
          ),

          const SizedBox(height: 20),

          // Password field
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onChanged: (value) {
              // Clear errors when user types
              context.read<AuthProvider>().clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return CustomButton(
      text: 'Sign In',
      onPressed: _signIn,
      type: ButtonType.primary,
      size: ButtonSize.large,
      icon: Icons.login_rounded,
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: _goToForgotPassword,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _goToSignUp,
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: 'By signing in, you agree to our ',
          ),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: '.'),
        ],
      ),
    );
  }
}
