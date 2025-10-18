import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });

    // Refresh token listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
      });
    });
  }
}
