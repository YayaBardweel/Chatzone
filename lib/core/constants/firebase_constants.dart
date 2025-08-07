class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String groupsCollection = 'groups';
  static const String statusCollection = 'status';

  // Storage Paths
  static const String userProfileImages = 'user_profiles';
  static const String chatImages = 'chat_images';
  static const String chatVideos = 'chat_videos';
  static const String chatDocuments = 'chat_documents';
  static const String chatAudio = 'chat_audio';

  // User Fields
  static const String userId = 'userId';
  static const String email = 'email';
  static const String emailVerified = 'emailVerified';
  static const String displayName = 'displayName';
  static const String photoUrl = 'photoUrl';
  static const String status = 'status';
  static const String isOnline = 'isOnline';
  static const String lastSeen = 'lastSeen';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // Chat Fields
  static const String chatId = 'chatId';
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTime = 'lastMessageTime';
  static const String lastMessageSender = 'lastMessageSender';
  static const String unreadCount = 'unreadCount';
  static const String chatType = 'chatType'; // 'individual' or 'group'

  // Message Fields
  static const String messageId = 'messageId';
  static const String senderId = 'senderId';
  static const String receiverId = 'receiverId';
  static const String messageText = 'messageText';
  static const String messageType = 'messageType'; // 'text', 'image', 'video', 'audio', 'document'
  static const String mediaUrl = 'mediaUrl';
  static const String timestamp = 'timestamp';
  static const String isRead = 'isRead';
  static const String readBy = 'readBy';
  static const String deliveredTo = 'deliveredTo';

  // Message Types
  static const String textMessage = 'text';
  static const String imageMessage = 'image';
  static const String videoMessage = 'video';
  static const String audioMessage = 'audio';
  static const String documentMessage = 'document';
  static const String locationMessage = 'location';

  // Chat Types
  static const String individualChat = 'individual';
  static const String groupChat = 'group';

  // Default Values
  static const String defaultStatus = 'Hey there! I am using ChatZone.';
  static const String defaultProfileImage = 'https://via.placeholder.com/150/075E54/FFFFFF?text=User';

  // Email Authentication
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 128;

  // Timeouts
  static const int connectionTimeoutSeconds = 30;
  static const int messageRetryAttempts = 3;
  static const int emailVerificationCheckInterval = 5; // seconds

  // Limits
  static const int maxMessageLength = 4096;
  static const int maxGroupParticipants = 256;
  static const double maxFileSize = 100 * 1024 * 1024; // 100MB
  static const double maxImageSize = 50 * 1024 * 1024; // 50MB
  static const double maxVideoSize = 200 * 1024 * 1024; // 200MB
}