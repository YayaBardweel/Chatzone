// ============================================================================
// File: lib/core/presentation/pages/contacts/add_contact_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/contact_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/validators.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_widget.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  // Tab controllers for search
  final _searchEmailController = TextEditingController();
  final _searchPhoneController = TextEditingController();

  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupAnimations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _searchEmailController.dispose();
    _searchPhoneController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer2<ContactProvider, UserProvider>(
        builder: (context, contactProvider, userProvider, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            _buildTabBar(),
                            _buildTabContent(contactProvider, userProvider),
                          ],
                        ),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
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
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Contact',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Find friends and connect',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingM),
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
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            icon: Icon(Icons.search, size: 20),
            text: 'Search Users',
          ),
          Tab(
            icon: Icon(Icons.person_add, size: 20),
            text: 'Add Manually',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ContactProvider contactProvider, UserProvider userProvider) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 300,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(contactProvider, userProvider),
          _buildManualAddTab(contactProvider, userProvider),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ContactProvider contactProvider, UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Search by Email'),
          const SizedBox(height: 16),

          // Email search
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchEmailController,
                  hintText: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Search',
                onPressed: () => _searchByEmail(userProvider),
                type: ButtonType.primary,
                size: ButtonSize.medium,
                icon: Icons.search,
                width: 100,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Search by Phone'),
          const SizedBox(height: 16),

          // Phone search
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchPhoneController,
                  hintText: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Search',
                onPressed: () => _searchByPhone(userProvider),
                type: ButtonType.primary,
                size: ButtonSize.medium,
                icon: Icons.search,
                width: 100,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search results
          if (_isSearching)
            const Center(
              child: LoadingWidget(
                type: LoadingType.pulse,
                message: 'Searching...',
              ),
            )
          else if (_searchResults.isNotEmpty)
            _buildSearchResults()
          else if (_searchEmailController.text.isNotEmpty || _searchPhoneController.text.isNotEmpty)
              _buildNoResults(),
        ],
      ),
    );
  }

  Widget _buildManualAddTab(ContactProvider contactProvider, UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Add Contact Manually'),
            const SizedBox(height: 16),

            // Name field
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
              controller: _nameController,
              hintText: 'Enter contact name',
              validator: Validators.validateDisplayName,
              prefixIcon: const Icon(Icons.person_outline),
            ),

            const SizedBox(height: 20),

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
              hintText: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),

            const SizedBox(height: 20),

            // Phone field
            const Text(
              'Phone Number (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Enter phone number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),

            const SizedBox(height: 32),

            // Add button
            CustomButton(
              text: 'Add Contact',
              onPressed: () => _addContact(contactProvider),
              type: ButtonType.primary,
              size: ButtonSize.large,
              icon: Icons.person_add,
              isLoading: contactProvider.isLoading,
            ),

            const SizedBox(height: 16),

            // Info card
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
                      'Adding a contact will send them an invitation to connect on ChatZone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Search Results'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return _buildUserResultTile(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResultTile(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: 12,
      ),
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
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.4)
                ],
              ),
            ),
            child: user['photoUrl'] != null
                ? ClipOval(
              child: Image.network(
                user['photoUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(user['displayName'] ?? 'U');
                },
              ),
            )
                : _buildDefaultAvatar(user['displayName'] ?? 'U'),
          ),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (user['status'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user['status'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Connect button
          CustomButton(
            text: 'Connect',
            onPressed: () => _connectWithUser(user),
            type: ButtonType.primary,
            size: ButtonSize.small,
            width: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different email or phone number',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  void _searchByEmail(UserProvider userProvider) async {
    if (_searchEmailController.text.trim().isEmpty) {
      _showError('Please enter an email address');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // This is a mock search - in real implementation, you'd call your backend
      await Future.delayed(const Duration(seconds: 2));

      // Mock results
      final results = [
        {
          'displayName': 'John Doe',
          'email': _searchEmailController.text.trim(),
          'status': 'Hey there! I am using ChatZone.',
          'photoUrl': null,
          'isOnline': true,
        }
      ];

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showError('Search failed: $e');
    }
  }

  void _searchByPhone(UserProvider userProvider) async {
    if (_searchPhoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      // This is a mock search - in real implementation, you'd call your backend
      await Future.delayed(const Duration(seconds: 2));

      // Mock results
      final results = [
        {
          'displayName': 'Jane Smith',
          'phoneNumber': _searchPhoneController.text.trim(),
          'status': 'Available',
          'photoUrl': null,
          'isOnline': false,
        }
      ];

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showError('Search failed: $e');
    }
  }

  void _addContact(ContactProvider contactProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Mock adding contact
      _showSuccess('Contact invitation sent!');

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();

      // Go back to contacts list
      Future.delayed(const Duration(seconds: 1), () {
        AppRouter.goToContacts(context);
      });

    } catch (e) {
      _showError('Failed to add contact: $e');
    }
  }

  void _connectWithUser(dynamic user) {
    _showSuccess('Connection request sent to ${user['displayName']}!');

    // Remove from search results
    setState(() {
      _searchResults.remove(user);
    });
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
}