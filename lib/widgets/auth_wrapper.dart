import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        debugPrint(
          '🎯 AuthWrapper BUILD - State: ${authProvider.authState}, Initializing: ${authProvider.isInitializing}, User: ${authProvider.user?.name ?? 'null'}, Loading: ${authProvider.isLoading}',
        );

        // Show splash screen while initializing
        if (authProvider.isInitializing) {
          debugPrint('📱 Showing SplashScreen (initializing)');
          return const SplashScreen();
        }

        // Also show splash while loading (during login)
        if (authProvider.isLoading) {
          debugPrint('📱 Showing SplashScreen (loading)');
          return const SplashScreen();
        }

        // Navigate based on authentication state
        switch (authProvider.authState) {
          case AuthState.authenticated:
            debugPrint(
              '✅ Showing ChatListScreen (Home) - User: ${authProvider.user?.name}',
            );
            return const ChatListScreen();

          case AuthState.authenticatedWithoutProfile:
            debugPrint(
              '⚠️ User authenticated but no profile - Showing ChatListScreen anyway',
            );
            // Allow access even without Firestore profile
            return const ChatListScreen();

          case AuthState.unauthenticated:
          case AuthState.unknown:
            debugPrint(
              '❌ Showing LoginScreen - State: ${authProvider.authState}',
            );
            return const LoginScreen();
        }
      },
    );
  }
}
