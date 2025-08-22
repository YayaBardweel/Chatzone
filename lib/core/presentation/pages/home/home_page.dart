// ============================================================================
// File: lib/core/presentation/pages/home/home_page.dart (FINAL - WITH FIXED FAB)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/custom_button.dart';
import 'chats_tab.dart';
import 'calls_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addObserver(this);
    _setUserOnline();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _setUserOffline();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  // ============================================================================
  // APP LIFECYCLE METHODS
  // ============================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _setUserOffline();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _setUserOnline() {
    final userProvider = context.read<UserProvider>();
    userProvider.setUserOnline();
  }

  void _setUserOffline() {
    final userProvider = context.read<UserProvider>();
    userProvider.setUserOffline();
  }

  // ============================================================================
  // NAVIGATION & ACTIONS
  // ============================================================================

  void _showSearchPage() {
    showSearch(
      context: context,
      delegate: _ChatSearchDelegate(),
    );
  }

  void _showProfile() {
    AppRouter.goToProfile(context);
  }

  void _showSettings() {
    AppRouter.goToSettings(context);
  }

  void _showContacts() {
    AppRouter.goToContacts(context);
  }

  void _signOut() async {
    final authProvider = context.read<AuthProvider>();

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

  // ============================================================================
  // FAB ACTIONS
  // ============================================================================

  void _onFabPressed() {
    switch (_currentIndex) {
      case 0: // Chats
        _showNewChatOptions();
        break;
      case 1: // Calls
        _showNewCallOptions();
        break;
    }
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewChatSheet(),
    );
  }

  void _showNewCallOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNewCallSheet(),
    );
  }

  // ============================================================================
  // BUILD METHODS - FIXED LAYOUT
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, _) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          // FIXED: Use NestedScrollView for better FAB compatibility
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(userProvider),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: const [
                ChatsTab(),
                CallsTab(),
              ],
            ),
          ),
          // FIXED: Add FAB at Scaffold level with proper location
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildSliverAppBar(UserProvider userProvider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildUserHeader(userProvider),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.chat),
            text: 'CHATS',
          ),
          Tab(
            icon: Icon(Icons.call),
            text: 'CALLS',
          ),
        ],
      ),
    );
  }


  Widget _buildUserHeader(UserProvider userProvider) {
    return Row(
      children: [
        // User avatar
        GestureDetector(
          onTap: _showProfile,
          child: Hero(
            tag: 'user_avatar',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: userProvider.photoUrl != null
                    ? NetworkImage(userProvider.photoUrl!)
                    : null,
                child: userProvider.photoUrl == null
                    ? Text(
                  userProvider.displayName.isNotEmpty
                      ? userProvider.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                )
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSizes.paddingM),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userProvider.displayName}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: userProvider.isOnline
                          ? AppColors.online
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    userProvider.isOnline
                        ? 'Online'
                        : userProvider.formatLastSeen(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search button
        IconButton(
          onPressed: _showSearchPage,
          icon: const Icon(
            Icons.search,
            color: Colors.white,
            size: 24,
          ),
          tooltip: 'Search',
        ),

        // Menu button
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white,
            size: 24,
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'contacts',
              child: Row(
                children: [
                  Icon(Icons.contacts, size: 20),
                  SizedBox(width: 8),
                  Text('Contacts'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Help'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sign Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _showProfile();
        break;
      case 'contacts':
        _showContacts();
        break;
      case 'settings':
        _showSettings();
        break;
      case 'help':
        _showHelpDialog();
        break;
      case 'signout':
        _signOut();
        break;
    }
  }
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Welcome to ChatZone!\n\n'
              'Features:\n'
              '• Send messages to friends\n'
              '• Make voice and video calls\n'
              '• Share photos and files\n'
              '• Create group chats\n\n'
              'For support, contact us at support@chatzone.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.2)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive ? Colors.red.shade100 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red.shade100 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Enhanced FAB with better visibility
  Widget _buildFloatingActionButton() {
    IconData icon;
    String tooltip;

    switch (_currentIndex) {
      case 0: // Chats
        icon = Icons.chat;
        tooltip = 'New chat';
        break;
      case 1: // Calls
        icon = Icons.add_call;
        tooltip = 'New call';
        break;
      default:
        icon = Icons.add;
        tooltip = 'Add';
    }

    return FloatingActionButton(
      onPressed: _onFabPressed,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      tooltip: tooltip,
      elevation: 8, // Increased elevation for better visibility
      child: Icon(icon, size: 28), // Slightly larger icon
    );
  }

  Widget _buildNewChatSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Start a new chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Options
            _buildSheetOption(
              icon: Icons.person_add,
              title: 'New Contact',
              subtitle: 'Add a contact by email or phone',
              onTap: () {
                Navigator.pop(context);
                AppRouter.goToAddContact(context);
              },
            ),

            _buildSheetOption(
              icon: Icons.contacts,
              title: 'Select Contact',
              subtitle: 'Choose from your contacts',
              onTap: () {
                Navigator.pop(context);
                AppRouter.goToContacts(context);
              },
            ),

            _buildSheetOption(
              icon: Icons.group_add,
              title: 'New Group',
              subtitle: 'Create a group chat',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group chat feature coming soon!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),

            const SizedBox(height: AppSizes.paddingS),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCallSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.call,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Make a call',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Options
            _buildSheetOption(
              icon: Icons.call,
              title: 'Voice Call',
              subtitle: 'Make a voice call',
              onTap: () {
                Navigator.pop(context);
                AppRouter.goToContacts(context);
              },
            ),

            _buildSheetOption(
              icon: Icons.videocam,
              title: 'Video Call',
              subtitle: 'Make a video call',
              onTap: () {
                Navigator.pop(context);
                AppRouter.goToContacts(context);
              },
            ),

            const SizedBox(height: AppSizes.paddingS),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH DELEGATE
// ============================================================================

class _ChatSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search chats and contacts...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHints();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchHints() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search chats and contacts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type to start searching...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Search coming soon!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search functionality will be available in the next update.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}