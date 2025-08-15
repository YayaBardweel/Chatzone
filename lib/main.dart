// ============================================================================
// File: lib/main.dart (UPDATED FOR PHASE 2)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/contact_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 ChatZone: Starting app initialization...');

  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Run the app with providers
    print('🏗️ Setting up providers and starting app...');
    runApp(
      MultiProvider(
        providers: [
          // Authentication Provider - Must be first
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            lazy: false, // Initialize immediately
          ),

          // User Provider - Depends on auth
          ChangeNotifierProvider(
            create: (_) => UserProvider(),
            lazy: false, // Initialize immediately
          ),

          // Contact Provider - Independent
          ChangeNotifierProvider(
            create: (_) => ContactProvider(),
            lazy: true, // Initialize when needed
          ),

          // TODO: Add more providers as we build them
          // - ChatProvider
          // - MessageProvider
          // - GroupProvider
          // - StatusProvider
          // - CallProvider
          // - NotificationProvider
          // - ThemeProvider
        ],
        child: const ChatZoneApp(),
      ),
    );

    print('✅ ChatZone: App started successfully');

  } catch (e) {
    print('❌ ChatZone: Failed to initialize app - $e');

    // Run a minimal error app
    runApp(
      MaterialApp(
        title: 'ChatZone - Error',
        home: Scaffold(
          backgroundColor: const Color(0xFF075E54),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to start ChatZone',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF075E54),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROVIDER SETUP NOTES
// ============================================================================

/*
Provider Hierarchy & Dependencies:

1. AuthProvider (Independent)
   - Manages Firebase Auth state
   - Handles login/logout/signup
   - Email verification
   - Must be initialized first

2. UserProvider (Depends on AuthProvider)
   - Manages user profile data in Firestore
   - Handles profile updates, photos
   - Online/offline status
   - Needs current user from AuthProvider

3. ContactProvider (Independent)
   - Manages device contacts
   - Contact permissions
   - Contact sync with app users
   - Independent of auth state

4. Future Providers:
   - ChatProvider (Depends on UserProvider, ContactProvider)
   - MessageProvider (Depends on ChatProvider)
   - GroupProvider (Depends on UserProvider, ContactProvider)
   - StatusProvider (Depends on UserProvider)
   - CallProvider (Depends on UserProvider, ContactProvider)
   - NotificationProvider (Depends on multiple)
   - ThemeProvider (Independent)

Provider Initialization Strategy:
- Critical providers (Auth, User): lazy: false (immediate init)
- Feature providers (Contact, Chat): lazy: true (init when accessed)
- This ensures fast app startup while maintaining functionality

Error Handling:
- If core initialization fails, show error screen with retry option
- Individual provider errors are handled within each provider
- UI shows loading states and error messages appropriately

Memory Management:
- Providers automatically dispose when app closes
- Subscriptions and streams are properly canceled
- Large data (contacts, messages) is cached efficiently

Performance Considerations:
- User data is streamed real-time from Firestore
- Contacts are cached locally after permission grant
- Messages will be paginated and cached
- Images/media will have size limits and compression
*/