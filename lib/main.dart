import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/auth_provider.dart' as auth_provider;
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/auth_wrapper.dart';

/// ✅ Must be annotated for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message received: ${message.messageId}");
  debugPrint("Data: ${message.data}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // ✅ Register background handler properly
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ Initialize local notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // ✅ Request user permission
    await _requestNotificationPermission();

    // ✅ Set up foreground listener
    _setupForegroundMessageListener();

    // ✅ Get FCM Token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('✅ FCM Token: $fcmToken');

    runApp(const HasaApp());
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
    runApp(const HasaApp());
  }
}

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('✅ Notifications permission granted');
  } else {
    debugPrint('⚠️ Notifications permission denied');
  }
}

void _setupForegroundMessageListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📢 Foreground message: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    debugPrint('Notification: ${message.notification?.title}');

    if (message.notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? '',
        notificationDetails,
      );
    }
  });
}

class HasaApp extends StatelessWidget {
  const HasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Hasa Chat App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
