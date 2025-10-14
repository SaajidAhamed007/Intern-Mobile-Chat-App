import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String? _fcmToken;
  String? _errorMessage;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String? get fcmToken => _fcmToken;
  String? get errorMessage => _errorMessage;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      _isInitialized = _notificationService.isInitialized;
      _fcmToken = _notificationService.fcmToken;
      _clearError();
      notifyListeners();

      print('✅ NotificationProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      print('❌ NotificationProvider initialization failed: $e');
    }
  }

  /// Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String receiverUserId,
    required String senderName,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!_isInitialized) {
        _setError('Notification service not initialized');
        return false;
      }

      final success = await _notificationService.sendNotificationToUser(
        receiverUserId: receiverUserId,
        senderName: senderName,
        message: message,
        additionalData: additionalData,
      );

      if (!success) {
        _setError('Failed to send notification');
      } else {
        _clearError();
      }

      return success;
    } catch (e) {
      _setError('Error sending notification: $e');
      return false;
    }
  }

  /// Toggle notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    // Save preference to local storage or Firestore
    // await _saveNotificationPreferences();
  }

  /// Toggle sound settings
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();

    // Save preference to local storage or Firestore
    // await _saveNotificationPreferences();
  }

  /// Toggle vibration settings
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();

    // Save preference to local storage or Firestore
    // await _saveNotificationPreferences();
  }

  /// Get current notification permission status
  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      _setError('Error checking notification permissions: $e');
      return AuthorizationStatus.denied;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      await _notificationService.initialize();
      final settings = await _notificationService.getNotificationSettings();

      final isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isGranted) {
        _clearError();
      } else {
        _setError('Notification permissions denied');
      }

      return isGranted;
    } catch (e) {
      _setError('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Subscribe to notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
      _clearError();
    } catch (e) {
      _setError('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
      _clearError();
    } catch (e) {
      _setError('Error unsubscribing from topic: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      _clearError();
    } catch (e) {
      _setError('Error clearing notifications: $e');
    }
  }

  /// Check if notifications are available on this device
  bool get isNotificationSupported {
    return _isInitialized && _fcmToken != null;
  }

  /// Get FCM token for debugging
  String get debugFCMToken => _fcmToken ?? 'No token available';

  /// Error handling
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  /// Save notification preferences to Firestore/SharedPreferences
  // Future<void> _saveNotificationPreferences() async {
  //   try {
  //     // Implementation for saving preferences
  //     // You can save to SharedPreferences or Firestore user document
  //   } catch (e) {
  //     print('Error saving notification preferences: $e');
  //   }
  // }

  /// Load notification preferences from Firestore/SharedPreferences
  // Future<void> _loadNotificationPreferences() async {
  //   try {
  //     // Implementation for loading preferences
  //   } catch (e) {
  //     print('Error loading notification preferences: $e');
  //   }
  // }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
