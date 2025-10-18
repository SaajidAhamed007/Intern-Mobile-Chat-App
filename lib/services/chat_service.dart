import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String getChatRoomId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2];
    userIds.sort();
    return '${userIds[0]}_${userIds[1]}';
  }

Future<void> sendPushNotification(String fcmToken, String title, String body) async {
  final url = Uri.parse("http://10.166.122.43:3000/send-notification"); // your Node.js server URL
  final payload = {
    'fcmToken': fcmToken,
    'title': title,
    'body': body,
  };

  print("📤 Sending notification to server: $payload");

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print("📥 Response from server: ${response.statusCode} - ${response.body}");
  } catch (e) {
    print("❌ Error while sending notification: $e");
  }
}

Future<void> sendMessage({
  required String receiverId,
  required String message,
  String type = 'text',
}) async {
  try {
    final senderId = currentUserId;
    if (senderId.isEmpty) {
      debugPrint("❌ Sender ID empty");
      return;
    }

    final chatRoomId = getChatRoomId(senderId, receiverId);
    final messageId = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc()
        .id;

    // 🔹 Firestore message data
    final messageData = {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'status': 'sent',
    };

    // 🔹 Create/update chat room
    await _firestore.collection('chats').doc(chatRoomId).set({
      'chatRoomId': chatRoomId,
      'participants': [senderId, receiverId],
      'lastMessage': message,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 🔹 Add message to Firestore
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .set(messageData);

    // 🔹 Get sender name
    final senderDoc = await _firestore.collection('users').doc(senderId).get();
    final senderName = senderDoc.data()?['name'] ?? 'Someone';

    // 🔹 Get receiver’s FCM token
    final receiverDoc =
        await _firestore.collection('users').doc(receiverId).get();
    final fcmToken = receiverDoc.data()?['fcmToken'];

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint("⚠️ No FCM token found for receiver");
      return;
    }

    // 🔹 Send notification: show sender name + message
    await sendPushNotification(
      fcmToken,
      "$senderName 💬", // ✅ title shows sender name
      message,           // ✅ body shows the message text
    );

  } catch (e) {
    debugPrint('❌ Error sending message: $e');
  }
}

  /// ✅ Stream messages in ascending order (oldest → newest)
  Stream<List<MessageModel>> getMessagesStream(String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // oldest first like WhatsApp
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// ✅ Mark messages as seen
  Future<void> markMessagesAsSeen(String otherUserId) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, otherUserId);

      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isSeen': true, 'status': 'seen'});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  /// ✅ Stream chat list (sorted by last message time)
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// ✅ Fetch last message between users
  Future<MessageModel?> getLastMessage(String otherUserId) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, otherUserId);
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return MessageModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  /// ✅ Get unread message count
  Future<int> getUnreadCount(String otherUserId) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, otherUserId);
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// ✅ Real-time summary (last message + unread count)
  Stream<Map<String, dynamic>> getChatSummaryStream(String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Get more messages to properly calculate unread count
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              return {'lastMessage': null, 'unreadCount': 0};
            }

            // Get the latest message
            final lastMessageData = snapshot.docs.first.data();
            final lastMessage = MessageModel.fromMap(lastMessageData);

            // Update the last message status based on isSeen field for sent messages
            MessageModel updatedLastMessage = lastMessage;
            if (lastMessage.senderId == currentUserId) {
              // For our sent messages, update status based on isSeen
              if (lastMessage.isSeen) {
                updatedLastMessage = lastMessage.copyWith(status: 'seen');
              } else {
                updatedLastMessage = lastMessage.copyWith(status: 'delivered');
              }
            }

            // Calculate unread count from the snapshot (messages from other user that are not seen)
            int unreadCount = 0;
            for (final doc in snapshot.docs) {
              try {
                final data = doc.data();
                if (data['senderId'] == otherUserId &&
                    (data['isSeen'] == false || data['isSeen'] == null)) {
                  unreadCount++;
                }
              } catch (e) {
                debugPrint('Error processing message for unread count: $e');
              }
            }

            debugPrint(
              'Chat summary for $otherUserId: lastMessage=${updatedLastMessage.message}, unreadCount=$unreadCount',
            );

            return {
              'lastMessage': updatedLastMessage,
              'unreadCount': unreadCount,
            };
          } catch (e) {
            debugPrint('Error in getChatSummaryStream: $e');
            return {'lastMessage': null, 'unreadCount': 0};
          }
        })
        .handleError((error) {
          debugPrint('Error in chat summary stream: $error');
          return {'lastMessage': null, 'unreadCount': 0};
        });
  }

  /// ✅ Delete a message
  Future<bool> deleteMessage(String otherUserId, String messageId) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, otherUserId);
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
}
