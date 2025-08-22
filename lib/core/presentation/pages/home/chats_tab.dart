// ============================================================================
// File: lib/core/presentation/pages/home/chats_tab.dart (MODERN REBUILD)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final bool _isLoading = false;
  String _searchQuery = '';

  // Enhanced mock data with more realistic content
  final List<ModernChatModel> _mockChats = [
    ModernChatModel(
      id: '1',
      name: 'Alice Johnson',
      lastMessage: 'Hey! How was your weekend? 😊',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      unreadCount: 3,
      isOnline: true,
      avatarUrl: null,
      isTyping: false,
      lastMessageType: MessageType.text,
      isPinned: true,
    ),
    ModernChatModel(
      id: '2',
      name: 'Work Team',
      lastMessage: 'Sarah: The project deadline is tomorrow 📅',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 7,
      isOnline: false,
      avatarUrl: null,
      isTyping: true,
      lastMessageType: MessageType.text,
      isGroup: true,
      isPinned: true,
    ),
    ModernChatModel(
      id: '3',
      name: 'John Smith',
      lastMessage: '📸 Photo',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 1,
      isOnline: true,
      avatarUrl: null,
      isTyping: false,
      lastMessageType: MessageType.image,
      isPinned: false,
    ),
    ModernChatModel(
      id: '4',
      name: 'Mom ❤️',
      lastMessage: 'Don\'t forget to call grandma today',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      isOnline: false,
      avatarUrl: null,
      isTyping: false,
      lastMessageType: MessageType.text,
      isPinned: false,
    ),
    ModernChatModel(
      id: '5',
      name: 'David Wilson',
      lastMessage: '🎵 Voice message',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 0,
      isOnline: true,
      avatarUrl: null,
      isTyping: false,
      lastMessageType: MessageType.voice,
      isPinned: false,
    ),
    ModernChatModel(
      id: '6',
      name: 'Family Group',
      lastMessage: 'Dad: See you all at dinner tonight! 🍽️',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 2,
      isOnline: false,
      avatarUrl: null,
      isTyping: false,
      lastMessageType: MessageType.text,
      isGroup: true,
      isPinned: false,
    ),
  ];

  List<ModernChatModel> get _filteredChats {
    if (_searchQuery.isEmpty) {
      // Sort by pinned first, then by timestamp
      final sorted = List<ModernChatModel>.from(_mockChats);
      sorted.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      return sorted;
    }

    return _mockChats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, _) {
        if (_isLoading) {
          return const Center(
            child: LoadingWidget(
              type: LoadingType.pulse,
              message: 'Loading chats...',
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(),
            _buildChatStats(),
            Expanded(
              child: _filteredChats.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade500,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
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

  Widget _buildChatStats() {
    final totalChats = _mockChats.length;
    final unreadChats = _mockChats.where((chat) => chat.unreadCount > 0).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.chat_bubble,
            label: 'Total',
            value: totalChats.toString(),
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            icon: Icons.mark_chat_unread,
            label: 'Unread',
            value: unreadChats.toString(),
            isHighlighted: unreadChats > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlighted ? AppColors.accent : AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? AppColors.accent : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      padding: const EdgeInsets.only(
        top: AppSizes.paddingM,
        bottom: 100, // Space for FAB
      ),
      itemCount: _filteredChats.length,
      separatorBuilder: (context, index) => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 80),
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final chat = _filteredChats[index];
        return _buildModernChatTile(chat);
      },
    );
  }

  Widget _buildModernChatTile(ModernChatModel chat) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openChat(chat),
        onLongPress: () => _showChatOptions(chat),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Avatar with status indicator
              _buildChatAvatar(chat),

              const SizedBox(width: 12),

              // Chat content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and timestamp row
                    Row(
                      children: [
                        // Pinned indicator
                        if (chat.isPinned) ...[
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Name
                        Expanded(
                          child: Text(
                            chat.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Timestamp
                        Text(
                          _formatTimestamp(chat.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.unreadCount > 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Last message and indicators row
                    Row(
                      children: [
                        // Message type icon
                        if (chat.lastMessageType != MessageType.text) ...[
                          Icon(
                            _getMessageTypeIcon(chat.lastMessageType),
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Last message or typing indicator
                        Expanded(
                          child: chat.isTyping
                              ? _buildTypingIndicator()
                              : Text(
                                  chat.lastMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: chat.unreadCount > 0
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: chat.unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),

                        // Unread count badge
                        if (chat.unreadCount > 0)
                          _buildUnreadBadge(chat.unreadCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatAvatar(ModernChatModel chat) {
    return Stack(
      children: [
        Hero(
          tag: 'chat_avatar_${chat.id}',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: chat.isGroup
                    ? [Colors.deepPurple.shade200, Colors.deepPurple.shade400]
                    : [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.4)
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: chat.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      chat.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(chat);
                      },
                    ),
                  )
                : _buildDefaultAvatar(chat),
          ),
        ),

        // Online indicator
        if (chat.isOnline && !chat.isGroup)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ModernChatModel chat) {
    return Center(
      child: Text(
        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : 'C',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: chat.isGroup ? Colors.deepPurple.shade700 : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const Text(
          'typing',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.chat_bubble_outline,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            const Text(
              'Start a conversation by tapping the chat button',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingL),
            CustomButton(
              text: 'Start Chatting',
              onPressed: () {
                AppRouter.goToContacts(context);
              },
              type: ButtonType.primary,
              size: ButtonSize.medium,
              icon: Icons.chat,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CHAT ACTIONS
  // ============================================================================

  void _openChat(ModernChatModel chat) {
    print('📱 Opening chat with ${chat.name}');

    // Mark as read locally
    setState(() {
      chat.unreadCount = 0;
    });

    // TODO: Navigate to chat page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Opening chat with ${chat.name}'),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }

  void _showChatOptions(ModernChatModel chat) {
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

              // Chat info header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Row(
                  children: [
                    _buildChatAvatar(chat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            chat.isGroup
                                ? 'Group chat'
                                : chat.isOnline
                                    ? 'Online'
                                    : 'Last seen recently',
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

              // Options
              _buildBottomSheetOption(
                icon: Icons.info_outline,
                title: 'Chat Info',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show chat info
                },
              ),

              _buildBottomSheetOption(
                icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                title: chat.isPinned ? 'Unpin Chat' : 'Pin Chat',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    chat.isPinned = !chat.isPinned;
                  });
                },
              ),

              _buildBottomSheetOption(
                icon: chat.unreadCount > 0
                    ? Icons.mark_chat_read
                    : Icons.mark_chat_unread,
                title: chat.unreadCount > 0 ? 'Mark as Read' : 'Mark as Unread',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    chat.unreadCount = chat.unreadCount > 0 ? 0 : 1;
                  });
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.archive_outlined,
                title: 'Archive Chat',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Archive chat
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.delete_outline,
                title: 'Delete Chat',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(chat);
                },
              ),

              const SizedBox(height: AppSizes.paddingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
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
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(ModernChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        title: const Text('Delete Chat'),
        content: Text(
            'Are you sure you want to delete this chat with ${chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            type: ButtonType.text,
            size: ButtonSize.small,
            customColor: AppColors.error,
            width: 80,
          ),
        ],
      ),
    );
  }

  void _deleteChat(ModernChatModel chat) {
    setState(() {
      _mockChats.remove(chat);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Chat with ${chat.name} deleted'),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _mockChats.add(chat);
            });
          },
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
  // UTILITY METHODS
  // ============================================================================

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.text:
        return Icons.message;
      case MessageType.image:
        return Icons.image;
      case MessageType.voice:
        return Icons.mic;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.document:
        return Icons.description;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

// ============================================================================
// ENHANCED MOCK DATA MODEL
// ============================================================================

enum MessageType { text, image, voice, video, document }

class ModernChatModel {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime timestamp;
  int unreadCount;
  final bool isOnline;
  final String? avatarUrl;
  final bool isTyping;
  final MessageType lastMessageType;
  final bool isGroup;
  bool isPinned;

  ModernChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    this.avatarUrl,
    required this.isTyping,
    required this.lastMessageType,
    this.isGroup = false,
    required this.isPinned,
  });
}
