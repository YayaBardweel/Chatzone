// ============================================================================
// File: lib/core/presentation/pages/profile/profile_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/validators.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _displayNameController = TextEditingController();
  final _statusController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeControllers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _statusController.dispose();
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

    _animationController.forward();
  }

  void _initializeControllers() {
    final userProvider = context.read<UserProvider>();
    _displayNameController.text = userProvider.displayName;
    _statusController.text = userProvider.userStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(
              child: LoadingWidget(
                type: LoadingType.pulse,
                message: 'Updating profile...',
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(userProvider),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildProfileContent(userProvider, authProvider),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(UserProvider userProvider) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Edit Profile',
          ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => AppRouter.goToSettings(context),
          tooltip: 'Settings',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Space for app bar
                _buildProfilePhoto(userProvider),
                const SizedBox(height: 16),
                Text(
                  userProvider.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProvider.userEmail ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                _buildOnlineStatus(userProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(UserProvider userProvider) {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          Hero(
            tag: 'user_avatar',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                  _selectedImage!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                )
                    : userProvider.photoUrl != null
                    ? Image.network(
                  userProvider.photoUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(userProvider);
                  },
                )
                    : _buildDefaultAvatar(userProvider),
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(UserProvider userProvider) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          userProvider.displayName.isNotEmpty
              ? userProvider.displayName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatus(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: userProvider.isOnline
            ? AppColors.online.withOpacity(0.2)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: userProvider.isOnline
              ? AppColors.online
              : Colors.white.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: userProvider.isOnline ? AppColors.online : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            userProvider.isOnline ? 'Online' : userProvider.formatLastSeen(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: userProvider.isOnline ? AppColors.online : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserProvider userProvider, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _buildEditForm(userProvider),
            const SizedBox(height: 20),
            _buildActionButtons(userProvider),
          ] else ...[
            _buildProfileInfo(userProvider),
            const SizedBox(height: 20),
            _buildAccountInfo(userProvider, authProvider),
            const SizedBox(height: 20),
            _buildQuickActions(userProvider),
          ],
          const SizedBox(height: 20),
          _buildDangerZone(authProvider),
        ],
      ),
    );
  }

  Widget _buildEditForm(UserProvider userProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Edit Profile'),
          const SizedBox(height: 16),

          // Display Name
          const Text(
            'Display Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _displayNameController,
            hintText: 'Enter your display name',
            validator: Validators.validateDisplayName,
            prefixIcon: const Icon(Icons.person_outline),
          ),

          const SizedBox(height: 20),

          // Status
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _statusController,
            hintText: 'What\'s on your mind?',
            maxLines: 3,
            maxLength: 139,
            validator: Validators.validateStatus,
            prefixIcon: const Icon(Icons.mood_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserProvider userProvider) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancel',
            onPressed: _cancelEditing,
            type: ButtonType.outline,
            size: ButtonSize.medium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'Save',
            onPressed: () => _saveProfile(userProvider),
            type: ButtonType.primary,
            size: ButtonSize.medium,
            icon: Icons.save,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About'),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.person,
          title: 'Display Name',
          value: userProvider.displayName,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.mood,
          title: 'Status',
          value: userProvider.userStatus,
          color: AppColors.accent,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.schedule,
          title: 'Last Seen',
          value: userProvider.formatLastSeen(),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildAccountInfo(UserProvider userProvider, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account'),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.email,
          title: 'Email',
          value: userProvider.userEmail ?? 'Not available',
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.verified,
          title: 'Email Verification',
          value: authProvider.isEmailVerified ? 'Verified' : 'Not Verified',
          color: authProvider.isEmailVerified ? Colors.green : AppColors.error,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Member Since',
          value: userProvider.currentUser?.createdAt != null
              ? _formatDate(userProvider.currentUser!.createdAt)
              : 'Unknown',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.qr_code,
                title: 'QR Code',
                subtitle: 'Share your profile',
                onTap: () {
                  // TODO: Show QR code
                  _showComingSoon('QR Code');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.share,
                title: 'Invite Friends',
                subtitle: 'Share ChatZone',
                onTap: () {
                  // TODO: Share app
                  _showComingSoon('Invite Friends');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDangerZone(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account Actions', color: AppColors.error),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Sign Out',
          onPressed: () => _confirmSignOut(authProvider),
          type: ButtonType.outline,
          size: ButtonSize.medium,
          customColor: AppColors.error,
          icon: Icons.logout,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  void _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _saveProfile(UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Upload image if selected
      if (_selectedImage != null) {
        final success = await userProvider.uploadProfilePhoto(_selectedImage!);
        if (!success) {
          _showError('Failed to upload profile photo');
          return;
        }
      }

      // Update profile data
      final updates = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'status': _statusController.text.trim(),
      };

      final success = await userProvider.updateUser(updates);

      if (success) {
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });
        _showSuccess('Profile updated successfully!');
      } else {
        _showError(userProvider.error ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
    });
    _initializeControllers(); // Reset controllers
  }

  void _confirmSignOut(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Sign Out',
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (mounted) {
                AppRouter.goToLogin(context);
              }
            },
            type: ButtonType.text,
            size: ButtonSize.small,
            customColor: AppColors.error,
            width: 100,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}