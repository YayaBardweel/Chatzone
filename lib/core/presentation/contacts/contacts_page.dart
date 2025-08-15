// ============================================================================
// File: lib/core/presentation/pages/contacts/contacts_page.dart
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<ContactProvider>(
        builder: (context, contactProvider, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(contactProvider),
              _buildSearchBar(contactProvider),
              _buildContactStats(contactProvider),
              _buildContactsList(contactProvider),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar(ContactProvider contactProvider) {
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
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${contactProvider.totalContactsCount} contacts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
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
        onTap: (index) {
          final views = [ContactsView.all, ContactsView.appUsers, ContactsView.device];
          contactProvider.setContactsView(views[index]);
        },
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 6),
                Text('All (${contactProvider.totalContactsCount})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat, size: 18),
                const SizedBox(width: 6),
                Text('App (${contactProvider.appUsersCount})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Text('Device (${contactProvider.deviceContactsCount})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ContactProvider contactProvider) {
    return SliverToBoxAdapter(
      child: Container(
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
      ),
    );
  }

  Widget _buildContactStats(ContactProvider contactProvider) {
    return SliverToBoxAdapter(
      child: Container(
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
      return const SliverFillRemaining(
        child: Center(
          child: LoadingWidget(
            type: LoadingType.pulse,
            message: 'Loading contacts...',
          ),
        ),
      );
    }

    if (contactProvider.error != null) {
      return SliverFillRemaining(
        child: CustomErrorWidget(
          message: contactProvider.error!,
          onRetry: () {
            if (!contactProvider.hasPermission) {
              contactProvider.requestPermission();
            } else {
              contactProvider.refreshContacts();
            }
          },
        ),
      );
    }

    if (!contactProvider.hasPermission) {
      return SliverFillRemaining(
        child: _buildPermissionRequest(contactProvider),
      );
    }

    if (contactProvider.displayedContacts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(contactProvider),
      );
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index >= sortedKeys.length) return null;

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
        childCount: sortedKeys.length,
      ),
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
        // TODO: Navigate to add contact page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add contact feature coming soon!'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      backgroundColor: AppColors.accent,
      child: const Icon(Icons.person_add, color: Colors.white),
    );
  }

  void _onContactTap(ContactModel contact) {
    if (contact.isAppUser) {
      // TODO: Start chat with this user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting chat with ${contact.displayName}...'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      // Show contact details or invite to app
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
              // Contact info
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
              // Actions
              _buildContactAction(
                icon: Icons.message,
                title: 'Send SMS',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open SMS app
                },
              ),
              _buildContactAction(
                icon: Icons.call,
                title: 'Call',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Make call
                },
              ),
              _buildContactAction(
                icon: Icons.share,
                title: 'Invite to ChatZone',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Send app invite
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