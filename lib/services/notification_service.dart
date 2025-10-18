import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _serverKey =
      'YOUR_FCM_SERVER_KEY'; // 🔒 Replace with your actual FCM Server Key

  /// Sends a push notification to a specific receiver
  static Future<void> sendPushNotification({
    required String receiverId,
    required String message,
    required String senderId,
  }) async {
    try {
      // Fetch receiver's FCM token
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!userDoc.exists) return;

      final token = userDoc.data()?['fcmToken'];
      if (token == null) return;

      // Fetch sender name for display
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'New Message';

      // Prepare notification payload
      final payload = {
        'to': token,
        'notification': {
          'title': senderName,
          'body': message,
          'sound': 'default',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'senderId': senderId,
        },
      };

      // Send request to FCM
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        print('❌ Failed to send notification: ${response.body}');
      } else {
        print('✅ Notification sent to $receiverId');
      }
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }
}
