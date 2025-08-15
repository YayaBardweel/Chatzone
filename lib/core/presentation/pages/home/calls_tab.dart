// ============================================================================
// File: lib/core/presentation/pages/home/calls_tab.dart (MODERN REBUILD)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final bool _isLoading = false;
  String _filterType = 'all'; // all, missed, incoming, outgoing

  final List<ModernCallModel> _mockCalls = [
    ModernCallModel(
      id: '1',
      contactName: 'Alice Johnson',
      callType: CallType.outgoingVideo,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      duration: const Duration(minutes: 8, seconds: 45),
      avatarUrl: null,
      isGroup: false,
    ),
    ModernCallModel(
      id: '2',
      contactName: 'Work Team',
      callType: CallType.incomingVideo,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      duration: const Duration(minutes: 23, seconds: 12),
      avatarUrl: null,
      isGroup: true,
    ),
    ModernCallModel(
      id: '3',
      contactName: 'John Smith',
      callType: CallType.missedVoice,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      duration: Duration.zero,
      avatarUrl: null,
      isGroup: false,
    ),
    ModernCallModel(
      id: '4',
      contactName: 'Mom ❤️',
      callType: CallType.incomingVoice,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      duration: const Duration(minutes: 15, seconds: 30),
      avatarUrl: null,
      isGroup: false,
    ),
    ModernCallModel(
      id: '5',
      contactName: 'David Wilson',
      callType: CallType.outgoingVoice,
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      duration: const Duration(minutes: 3, seconds: 22),
      avatarUrl: null,
      isGroup: false,
    ),
    ModernCallModel(
      id: '6',
      contactName: 'Sarah Kim',
      callType: CallType.missedVideo,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      duration: Duration.zero,
      avatarUrl: null,
      isGroup: false,
    ),
    ModernCallModel(
      id: '7',
      contactName: 'Family Group',
      callType: CallType.incomingVideo,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(minutes: 45, seconds: 18),
      avatarUrl: null,
      isGroup: true,
    ),
  ];

  List<ModernCallModel> get _filteredCalls {
    switch (_filterType) {
      case 'missed':
        return _mockCalls
            .where((call) =>
                call.callType == CallType.missedVoice ||
                call.callType == CallType.missedVideo)
            .toList();
      case 'incoming':
        return _mockCalls
            .where((call) =>
                call.callType == CallType.incomingVoice ||
                call.callType == CallType.incomingVideo)
            .toList();
      case 'outgoing':
        return _mockCalls
            .where((call) =>
                call.callType == CallType.outgoingVoice ||
                call.callType == CallType.outgoingVideo)
            .toList();
      default:
        return _mockCalls;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (_isLoading) {
          return const Center(
            child: LoadingWidget(
              type: LoadingType.pulse,
              message: 'Loading calls...',
            ),
          );
        }

        return Column(
          children: [
            _buildFilterBar(),
            _buildCallStats(),
            Expanded(
              child: _filteredCalls.isEmpty
                  ? _buildEmptyState()
                  : _buildCallsList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingM),
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'All Calls'),
          const SizedBox(width: 8),
          _buildFilterChip('missed', 'Missed'),
          const SizedBox(width: 8),
          _buildFilterChip('incoming', 'Incoming'),
          const SizedBox(width: 8),
          _buildFilterChip('outgoing', 'Outgoing'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCallStats() {
    final totalCalls = _mockCalls.length;
    final missedCalls = _mockCalls
        .where((call) =>
            call.callType == CallType.missedVoice ||
            call.callType == CallType.missedVideo)
        .length;
    final todaysCalls = _mockCalls
        .where((call) => DateTime.now().difference(call.timestamp).inDays == 0)
        .length;

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
            icon: Icons.call,
            label: 'Total',
            value: totalCalls.toString(),
            color: AppColors.primary,
          ),
          _buildStatColumn(
            icon: Icons.call_missed,
            label: 'Missed',
            value: missedCalls.toString(),
            color: AppColors.error,
          ),
          _buildStatColumn(
            icon: Icons.today,
            label: 'Today',
            value: todaysCalls.toString(),
            color: AppColors.accent,
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
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
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

  Widget _buildCallsList() {
    return ListView.separated(
      padding: const EdgeInsets.only(
        top: AppSizes.paddingM,
        bottom: 100, // Space for FAB
      ),
      itemCount: _filteredCalls.length,
      separatorBuilder: (context, index) => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 80),
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final call = _filteredCalls[index];
        return _buildModernCallTile(call);
      },
    );
  }

  Widget _buildModernCallTile(ModernCallModel call) {
    final isMissed = call.callType == CallType.missedVoice ||
        call.callType == CallType.missedVideo;

    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _initiateCall(call),
        onLongPress: () => _showCallOptions(call),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Avatar
              _buildCallAvatar(call),

              const SizedBox(width: 12),

              // Call info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact name
                    Text(
                      call.contactName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isMissed ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Call details
                    Row(
                      children: [
                        Icon(
                          _getCallDirectionIcon(call.callType),
                          size: 16,
                          color: _getCallTypeColor(call.callType),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCallTypeText(call.callType),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getCallTypeColor(call.callType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (call.duration > Duration.zero) ...[
                          Text(
                            ' • ${_formatDuration(call.duration)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Timestamp
                    Text(
                      _formatCallTimestamp(call.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Call button
              _buildCallButton(call),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallAvatar(ModernCallModel call) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: call.isGroup
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
      child: call.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                call.avatarUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultCallAvatar(call);
                },
              ),
            )
          : _buildDefaultCallAvatar(call),
    );
  }

  Widget _buildDefaultCallAvatar(ModernCallModel call) {
    return Center(
      child: Text(
        call.contactName.isNotEmpty ? call.contactName[0].toUpperCase() : 'C',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: call.isGroup ? Colors.deepPurple.shade700 : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCallButton(ModernCallModel call) {
    final isVideoCall = call.callType == CallType.incomingVideo ||
        call.callType == CallType.outgoingVideo ||
        call.callType == CallType.missedVideo;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _initiateCall(call),
        icon: Icon(
          isVideoCall ? Icons.videocam : Icons.call,
          color: Colors.white,
          size: 24,
        ),
        tooltip: isVideoCall ? 'Video call' : 'Voice call',
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
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_outlined,
                size: 60,
                color: AppColors.accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            const Text(
              'No recent calls',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            const Text(
              'Your call history will appear here',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: 'Voice Call',
                  onPressed: () {
                    AppRouter.goToContacts(context);
                  },
                  type: ButtonType.outline,
                  size: ButtonSize.medium,
                  icon: Icons.call,
                  width: 140,
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Video Call',
                  onPressed: () {
                    AppRouter.goToContacts(context);
                  },
                  type: ButtonType.primary,
                  size: ButtonSize.medium,
                  icon: Icons.videocam,
                  width: 140,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CALL ACTIONS
  // ============================================================================

  void _initiateCall(ModernCallModel call) {
    final isVideoCall = call.callType == CallType.incomingVideo ||
        call.callType == CallType.outgoingVideo ||
        call.callType == CallType.missedVideo;

    print('📞 ${isVideoCall ? "Video" : "Voice"} calling ${call.contactName}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isVideoCall ? Icons.videocam : Icons.call,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
                '${isVideoCall ? "Video" : "Voice"} calling ${call.contactName}...'),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }

  void _showCallOptions(ModernCallModel call) {
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

              // Call info header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Row(
                  children: [
                    _buildCallAvatar(call),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.contactName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatCallTimestamp(call.timestamp),
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

              // Call actions
              _buildCallOptionTile(
                icon: Icons.call,
                title: 'Voice Call',
                onTap: () {
                  Navigator.pop(context);
                  _initiateCall(call);
                },
              ),

              _buildCallOptionTile(
                icon: Icons.videocam,
                title: 'Video Call',
                onTap: () {
                  Navigator.pop(context);
                  _initiateCall(call);
                },
              ),

              _buildCallOptionTile(
                icon: Icons.chat,
                title: 'Send Message',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open chat
                },
              ),

              _buildCallOptionTile(
                icon: Icons.person,
                title: 'Contact Info',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show contact info
                },
              ),

              _buildCallOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete from Call Log',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _deleteCall(call);
                },
              ),

              const SizedBox(height: AppSizes.paddingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallOptionTile({
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

  void _deleteCall(ModernCallModel call) {
    setState(() {
      _mockCalls.remove(call);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Call from ${call.contactName} deleted'),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _mockCalls.add(call);
              _mockCalls.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  IconData _getCallDirectionIcon(CallType type) {
    switch (type) {
      case CallType.incomingVoice:
      case CallType.incomingVideo:
        return Icons.call_received;
      case CallType.outgoingVoice:
      case CallType.outgoingVideo:
        return Icons.call_made;
      case CallType.missedVoice:
      case CallType.missedVideo:
        return Icons.call_missed;
    }
  }

  Color _getCallTypeColor(CallType type) {
    switch (type) {
      case CallType.incomingVoice:
      case CallType.incomingVideo:
        return AppColors.accent;
      case CallType.outgoingVoice:
      case CallType.outgoingVideo:
        return AppColors.primary;
      case CallType.missedVoice:
      case CallType.missedVideo:
        return AppColors.error;
    }
  }

  String _getCallTypeText(CallType type) {
    switch (type) {
      case CallType.incomingVoice:
        return 'Incoming';
      case CallType.outgoingVoice:
        return 'Outgoing';
      case CallType.missedVoice:
        return 'Missed';
      case CallType.incomingVideo:
        return 'Incoming video';
      case CallType.outgoingVideo:
        return 'Outgoing video';
      case CallType.missedVideo:
        return 'Missed video';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
  }

  String _formatCallTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today $displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// ============================================================================
// ENHANCED CALL MODEL
// ============================================================================

enum CallType {
  incomingVoice,
  outgoingVoice,
  missedVoice,
  incomingVideo,
  outgoingVideo,
  missedVideo,
}

class ModernCallModel {
  final String id;
  final String contactName;
  final CallType callType;
  final DateTime timestamp;
  final Duration duration;
  final String? avatarUrl;
  final bool isGroup;

  ModernCallModel({
    required this.id,
    required this.contactName,
    required this.callType,
    required this.timestamp,
    required this.duration,
    this.avatarUrl,
    this.isGroup = false,
  });
}
