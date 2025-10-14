import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Generate chat room ID for two users (consistent regardless of order)
  String getChatRoomId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2];
    userIds.sort(); // Ensure consistent order
    return '${userIds[0]}_${userIds[1]}';
  }

  /// Send a message to a chat room
  Future<bool> sendMessage({
    required String receiverId,
    required String message,
    String type = 'text',
  }) async {
    try {
      final senderId = currentUserId;
      if (senderId.isEmpty) return false;

      final chatRoomId = getChatRoomId(senderId, receiverId);
      final messageId = _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc()
          .id;

      final messageModel = MessageModel(
        messageId: messageId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isSeen: false,
      );

      // Create or update chat room document
      await _firestore.collection('chats').doc(chatRoomId).set({
        'chatRoomId': chatRoomId,
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageTime': messageModel.timestamp.toIso8601String(),
        'lastMessageSenderId': senderId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(messageModel.toMap());

      // Send notification to receiver
      await _sendMessageNotification(receiverId, message, senderId);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Send notification for new message
  Future<void> _sendMessageNotification(
    String receiverId,
    String message,
    String senderId,
  ) async {
    try {
      // Get sender's information
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      if (!senderDoc.exists) return;

      final senderData = senderDoc.data() as Map<String, dynamic>;
      final senderName = senderData['name'] as String? ?? 'Someone';

      print(
        '📧 Attempting to send notification to $receiverId from $senderName',
      );

      // Get receiver's FCM token from Firestore
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();

      if (!receiverDoc.exists) {
        print('❌ Receiver user not found');
        return;
      }

      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final receiverToken = receiverData['fcmToken'] as String?;

      if (receiverToken == null) {
        print('❌ Receiver FCM token not found');
        return;
      }

      print('✅ Found receiver FCM token: ${receiverToken.substring(0, 20)}...');

      // For now, save notification to Firestore for Cloud Functions to process
      // In the future, you'd use Cloud Functions to send actual FCM messages
      await _firestore.collection('notifications').add({
        'receiverUserId': receiverId,
        'senderUserId': senderId,
        'senderName': senderName,
        'title': 'New message from $senderName',
        'body': message,
        'data': {
          'chatUserId': senderId,
          'senderName': senderName,
          'message': message,
          'messageType': 'chat_message',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'fcmToken': receiverToken,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, sent, failed
      });

      print('✅ Notification queued in Firestore for $senderName -> receiver');

      // Also show a local notification if the receiver is the current user
      // This is for testing when using the same device
      if (receiverId == _auth.currentUser?.uid) {
        print('🔔 Showing local notification for same-device testing');
        // This won't work as intended because it's the same user, but useful for debugging
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      // Don't fail the message send if notification fails
    }
  }

  /// Get messages stream for a chat room
  Stream<List<MessageModel>> getMessagesStream(String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data());
          }).toList();
        });
  }

  /// Mark messages as seen
  Future<void> markMessagesAsSeen(String otherUserId) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, otherUserId);

      // Get unread messages sent by the other user
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      // Mark each message as seen
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  /// Get all chat rooms for current user
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Delete a message
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
      print('Error deleting message: $e');
      return false;
    }
  }
}
