// ============================================================================
// File: lib/core/presentation/contacts/contacts_page.dart (UPDATED NAVIGATION)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../data/models/contact_model.dart';
import '../../providers/contact_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/page_wrapper.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize contacts if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactProvider = context.read<ContactProvider>();
      if (!contactProvider.isInitialized && !contactProvider.isLoading) {
        contactProvider.refreshContacts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, _) {
        return PageWrapper(
          title: 'Contacts',
          showBackButton: true, // This will show back button
          backgroundColor: Colors.grey.shade50,
          actions: [
            // Search action
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearch,
              tooltip: 'Search contacts',
            ),
            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Invite Friends'),
                    ],
                  ),
                ),
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
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            onTap: (index) {
              final views = [ContactsView.all, ContactsView.appUsers, ContactsView.device];
              contactProvider.setContactsView(views[index]);
            },
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text('All (${contactProvider.totalContactsCount})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat, size: 16),
                    const SizedBox(width: 4),
                    Text('App (${contactProvider.appUsersCount})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16),
                    const SizedBox(width: 4),
                    Text('Device (${contactProvider.deviceContactsCount})'),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
          body: Column(
            children: [
              _buildSearchBar(contactProvider),
              _buildContactStats(contactProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContactsList(contactProvider),
                    _buildContactsList(contactProvider),
                    _buildContactsList(contactProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: ContactSearchDelegate(),
    );
  }

  void _handleMenuAction(String action) {
    final contactProvider = context.read<ContactProvider>();

    switch (action) {
      case 'refresh':
        contactProvider.refreshContacts();
        _showSnackBar('Refreshing contacts...');
        break;
      case 'invite':
        _showSnackBar('Invite friends feature coming soon!');
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacts Help'),
        content: const Text(
          'Here you can:\n\n'
              '• View all your contacts\n'
              '• Find friends using ChatZone\n'
              '• Start new conversations\n'
              '• Invite friends to join ChatZone',
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

  Widget _buildSearchBar(ContactProvider contactProvider) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: contactProvider.searchContacts,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: contactProvider.searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade500),
            onPressed: () {
              _searchController.clear();
              contactProvider.clearSearch();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContactStats(ContactProvider contactProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            icon: Icons.people,
            label: 'Total',
            value: contactProvider.totalContactsCount.toString(),
            color: AppColors.primary,
          ),
          _buildStatColumn(
            icon: Icons.chat_bubble,
            label: 'App Users',
            value: contactProvider.appUsersCount.toString(),
            color: AppColors.accent,
          ),
          _buildStatColumn(
            icon: Icons.phone,
            label: 'Device',
            value: contactProvider.deviceContactsCount.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList(ContactProvider contactProvider) {
    if (contactProvider.isLoading && contactProvider.displayedContacts.isEmpty) {
      return const Center(
        child: LoadingWidget(
          type: LoadingType.pulse,
          message: 'Loading contacts...',
        ),
      );
    }

    if (contactProvider.error != null) {
      return CustomErrorWidget(
        message: contactProvider.error!,
        onRetry: () {
          if (!contactProvider.hasPermission) {
            contactProvider.requestPermission();
          } else {
            contactProvider.refreshContacts();
          }
        },
      );
    }

    if (!contactProvider.hasPermission) {
      return _buildPermissionRequest(contactProvider);
    }

    if (contactProvider.displayedContacts.isEmpty) {
      return _buildEmptyState(contactProvider);
    }

    return _buildGroupedContactsList(contactProvider);
  }

  Widget _buildPermissionRequest(ContactProvider contactProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contacts_rounded,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            const Text(
              'Access Your Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            const Text(
              'To find friends and connect with people you know, ChatZone needs access to your contacts.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingL),
            CustomButton(
              text: 'Grant Permission',
              onPressed: contactProvider.requestPermission,
              type: ButtonType.primary,
              size: ButtonSize.medium,
              icon: Icons.contacts,
              width: 200,
            ),
            const SizedBox(height: AppSizes.paddingM),
            CustomButton(
              text: 'Open Settings',
              onPressed: contactProvider.openAppSettings,
              type: ButtonType.outline,
              size: ButtonSize.medium,
              icon: Icons.settings,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ContactProvider contactProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              contactProvider.searchQuery.isNotEmpty ? 'No Results Found' : 'No Contacts Yet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              contactProvider.searchQuery.isNotEmpty
                  ? 'Try searching with a different term'
                  : 'Add contacts to start chatting',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingL),
            if (contactProvider.searchQuery.isEmpty)
              CustomButton(
                text: 'Refresh Contacts',
                onPressed: contactProvider.refreshContacts,
                type: ButtonType.primary,
                size: ButtonSize.medium,
                icon: Icons.refresh,
                width: 200,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedContactsList(ContactProvider contactProvider) {
    final groupedContacts = contactProvider.groupedContacts;
    final sortedKeys = groupedContacts.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final contacts = groupedContacts[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              color: Colors.grey.shade100,
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Contacts in this section
            ...contacts.map((contact) => _buildContactTile(contact)),
          ],
        );
      },
    );
  }

  Widget _buildContactTile(ContactModel contact) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _onContactTap(contact),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Avatar
              _buildContactAvatar(contact),
              const SizedBox(width: 12),
              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (contact.status != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.status!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (contact.phoneNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.formattedPhoneNumber ?? contact.phoneNumber!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicators
              Column(
                children: [
                  if (contact.isAppUser) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ChatZone',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (contact.isOnline == true && contact.isAppUser)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(ContactModel contact) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: contact.isAppUser
                  ? [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.4)]
                  : [Colors.grey.shade200, Colors.grey.shade400],
            ),
          ),
          child: contact.displayPhoto != null
              ? ClipOval(
            child: contact.photo != null
                ? Image.memory(
              contact.photo!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : contact.photoUrl != null
                ? Image.network(
              contact.photoUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar(contact);
              },
            )
                : _buildDefaultAvatar(contact),
          )
              : _buildDefaultAvatar(contact),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ContactModel contact) {
    return Center(
      child: Text(
        contact.initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: contact.isAppUser ? AppColors.primary : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showSnackBar('Add contact feature coming soon!');
      },
      backgroundColor: AppColors.accent,
      child: const Icon(Icons.person_add, color: Colors.white),
    );
  }

  void _onContactTap(ContactModel contact) {
    if (contact.isAppUser) {
      _showSnackBar('Starting chat with ${contact.displayName}...');
    } else {
      _showContactOptions(contact);
    }
  }

  void _showContactOptions(ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Row(
                  children: [
                    _buildContactAvatar(contact),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (contact.phoneNumber != null)
                            Text(
                              contact.formattedPhoneNumber ?? contact.phoneNumber!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildContactAction(
                icon: Icons.message,
                title: 'Send SMS',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('SMS feature coming soon!');
                },
              ),
              _buildContactAction(
                icon: Icons.call,
                title: 'Call',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Call feature coming soon!');
                },
              ),
              _buildContactAction(
                icon: Icons.share,
                title: 'Invite to ChatZone',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Invite feature coming soon!');
                },
              ),
              const SizedBox(height: AppSizes.paddingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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

class ContactSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search contacts...';

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
            'Search your contacts',
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