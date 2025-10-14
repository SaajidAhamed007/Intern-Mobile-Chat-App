import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart' as auth_provider;
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_listener_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
    await testFirestoreConnection();
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  runApp(const HasaApp());
}

Future<void> testFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .doc('ping')
        .set({'status': 'connected', 'timestamp': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 10));
    print("✅ Firestore Connected!");
  } catch (e) {
    print("⚠️ Firestore connection error: $e");
  }
}

class HasaApp extends StatelessWidget {
  const HasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => auth_provider.AuthProvider(),
        ),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Hasa Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// This widget decides whether to show the Splash, Login, or Home screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final NotificationListenerService _notificationListener =
      NotificationListenerService();
  bool _notificationListenerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize notifications when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.initialize();
    });
  }

  @override
  void dispose() {
    _notificationListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen only during initial authentication check
        if (authProvider.isInitializing) {
          return const SplashScreen();
        }

        // Handle different auth states
        switch (authProvider.authState) {
          case auth_provider.AuthState.authenticated:
            // User is authenticated and has profile data
            // Initialize notification listener for authenticated user (only once)
            if (!_notificationListenerInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _notificationListener.initialize();
                _notificationListenerInitialized = true;
              });
            }
            return const ChatListScreen();

          case auth_provider.AuthState.authenticatedWithoutProfile:
            // User is authenticated but needs to complete profile
            // For now, redirect to login screen - you can create ProfileSetupScreen later
            return const LoginScreen();

          case auth_provider.AuthState.unauthenticated:
          case auth_provider.AuthState.unknown:
            // User is not authenticated or unknown state
            _notificationListener.dispose(); // Stop listener when not authenticated
            _notificationListenerInitialized = false; // Reset flag
            return const LoginScreen();
        }
      },
    );
  }
}
