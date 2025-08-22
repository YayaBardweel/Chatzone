// ============================================================================
// File: lib/core/utils/auth_debug_helper.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';

/// Debug helper widget to test auth functionality
class AuthDebugHelper extends StatelessWidget {
  const AuthDebugHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Auth Debug Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {
                      authProvider.debugAuthState();
                    },
                    tooltip: 'Refresh debug info',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDebugInfo(authProvider),
              const SizedBox(height: 12),
              _buildTestActions(context, authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebugInfo(AuthProvider authProvider) {
    final state = authProvider.getAuthState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status: ${authProvider.isAuthenticated ? "✅ Signed In" : "❌ Not Signed In"}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: authProvider.isAuthenticated ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text('Email: ${authProvider.userEmail ?? "None"}'),
        Text('Verified: ${authProvider.isEmailVerified ? "✅" : "❌"}'),
        Text('Loading: ${authProvider.isLoading ? "🔄" : "✅"}'),
        if (authProvider.error != null)
          Text(
            'Error: ${authProvider.error}',
            style: const TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildTestActions(BuildContext context, AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton(
          onPressed: authProvider.isLoading ? null : () async {
            final success = await authProvider.sendEmailVerification();
            _showSnackBar(
              context,
              success ? 'Verification email sent!' : 'Failed to send email',
              success ? Colors.green : Colors.red,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Verification'),
        ),
        ElevatedButton(
          onPressed: authProvider.isLoading ? null : () async {
            final verified = await authProvider.checkEmailVerification();
            _showSnackBar(
              context,
              verified ? 'Email is verified!' : 'Email not verified yet',
              verified ? Colors.green : Colors.orange,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Check Verification'),
        ),
        ElevatedButton(
          onPressed: authProvider.isLoading ? null : () async {
            final verified = await authProvider.manualEmailVerificationCheck();
            _showSnackBar(
              context,
              verified ? 'Email verified successfully!' : 'Email not verified yet',
              verified ? Colors.green : Colors.orange,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Force Check'),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// Usage: Add this widget to any page for debugging
// ============================================================================

/*
Add this to your login page or any page to debug auth:

@override
Widget build(BuildContext context) {
  return Scaffold(
    // your existing code...
    body: Column(
      children: [
        // your existing content...

        // Add this for debugging (remove in production)
        if (kDebugMode) const AuthDebugHelper(),
      ],
    ),
  );
}
*/