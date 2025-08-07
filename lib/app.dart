import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/presentation/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';


class ChatZoneApp extends StatelessWidget {
  const ChatZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp.router(
          title: 'ChatZone',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
