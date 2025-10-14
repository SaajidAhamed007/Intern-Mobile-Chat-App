import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Top-level function for background message handling
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ NotificationService initialization failed: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Provisional notification permissions granted');
    } else {
      print('❌ Notification permissions denied');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _saveFCMTokenToFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        if (_auth.currentUser != null) {
          _saveFCMTokenToFirestore(newToken);
        }
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore user document
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  /// Configure Firebase message handlers
  void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Parse payload and navigate accordingly
    if (response.payload != null) {
      // You can parse the payload and navigate to specific chat
      _handleNotificationNavigation(response.payload!);
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap with data: $data');
    // Extract chat information from notification data
    final chatUserId = data['chatUserId'];
    final userName = data['userName'];

    if (chatUserId != null) {
      // Navigate to specific chat
      // This would be implemented based on your navigation setup
      print('Navigate to chat with user: $userName ($chatUserId)');
    }
  }

  /// Handle notification navigation (for local notifications)
  void _handleNotificationNavigation(String payload) {
    print('Handling local notification navigation: $payload');
    // Parse payload and navigate accordingly
  }

  /// Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String receiverUserId,
    required String senderName,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get receiver's FCM token from Firestore
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverUserId)
          .get();

      if (!receiverDoc.exists) {
        print('❌ Receiver user not found');
        return false;
      }

      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final receiverToken = receiverData['fcmToken'] as String?;

      if (receiverToken == null) {
        print('❌ Receiver FCM token not found');
        return false;
      }

      // Create notification data
      final notificationData = {
        'chatUserId': _auth.currentUser?.uid,
        'senderName': senderName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      // Send notification via Firebase Cloud Functions or your backend
      // For now, we'll save to a notifications collection that can trigger Cloud Functions
      await _firestore.collection('notifications').add({
        'receiverUserId': receiverUserId,
        'senderUserId': _auth.currentUser?.uid,
        'senderName': senderName,
        'title': 'New message from $senderName',
        'body': message,
        'data': notificationData,
        'fcmToken': receiverToken,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, sent, failed
      });

      print('✅ Notification queued for sending');
      return true;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Subscribe to topic for general notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
