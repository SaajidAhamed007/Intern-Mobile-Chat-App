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
      // Determine notification channel based on message content
      String channelId = 'high_importance_channel';
      String channelName = 'High Importance Notifications';
      String icon = '@mipmap/ic_launcher';

      // Check if this is a contact request notification
      final title = message.notification?.title ?? '';
      if (title.contains('Contact Request')) {
        channelId = 'contact_requests_channel';
        channelName = 'Contact Requests';
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: icon,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        notificationDetails,
      );
    }
  });
}

class HasaApp extends StatefulWidget {
  const HasaApp({super.key});

  @override
  State<HasaApp> createState() => _HasaAppState();
}

class _HasaAppState extends State<HasaApp> {
  late ThemeProvider _themeProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _themeProvider.initializeTheme();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
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
