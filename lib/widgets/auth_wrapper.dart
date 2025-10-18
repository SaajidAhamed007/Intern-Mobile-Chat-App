import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash screen while initializing
        if (authProvider.isInitializing) {
          return const SplashScreen();
        }

        // Navigate based on authentication state
        switch (authProvider.authState) {
          case AuthState.authenticated:
            return const ChatListScreen();

          case AuthState.unauthenticated:
          case AuthState.unknown:
          case AuthState.authenticatedWithoutProfile:
            return const LoginScreen();
        }
      },
    );
  }
}
