import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message_model.dart';
import '../models/contact_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String getChatRoomId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2];
    userIds.sort();
    return '${userIds[0]}_${userIds[1]}';
  }

  Future<void> sendPushNotification(
    String fcmToken,
    String title,
    String body,
  ) async {
    final url = Uri.parse(
      "https://hasa-chat-backend-services.onrender.com/send-notification",
    );
    final payload = {'fcmToken': fcmToken, 'title': title, 'body': body};

    print("📤 Sending notification to server: $payload");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print(
        "📥 Response from server: ${response.statusCode} - ${response.body}",
      );
    } catch (e) {
      print("❌ Error while sending notification: $e");
    }
  }

  /// Check if two users are contacts (have accepted contact request)
  Future<bool> areUsersContacts(String userId1, String userId2) async {
    try {
      // Check if userId2 is in userId1's contacts list
      final user1Doc = await _firestore.collection('users').doc(userId1).get();
      if (!user1Doc.exists) return false;

      final user1Data = user1Doc.data()!;
      final user1Contacts = user1Data['contacts'] as List? ?? [];

      final isUserInContacts = user1Contacts.any(
        (contact) => contact['id'] == userId2,
      );

      debugPrint('📋 Contact check: $userId1 -> $userId2 = $isUserInContacts');
      return isUserInContacts;
    } catch (e) {
      debugPrint('❌ Error checking if users are contacts: $e');
      return false;
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

      // ✅ CHECK: Ensure users are contacts before allowing message sending
      final areContacts = await areUsersContacts(senderId, receiverId);
      if (!areContacts) {
        debugPrint("❌ Cannot send message: Users are not contacts");
        throw Exception(
          "You can only message your contacts. Please send a contact request first.",
        );
      }

      final chatRoomId = getChatRoomId(senderId, receiverId);
      final currentTime = Timestamp.now();
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
        'timestamp': currentTime, // Use same timestamp for consistency
        'isSeen': false,
        'status': 'sent',
      };

      // 🔹 Create/update chat room
      await _firestore.collection('chats').doc(chatRoomId).set({
        'chatRoomId': chatRoomId,
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageSenderId': senderId,
        'lastMessageTime':
            currentTime, // Use current timestamp for immediate update
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
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      final senderName = senderDoc.data()?['name'] ?? 'Someone';

      // 🔹 Get receiver’s FCM token
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint("⚠️ No FCM token found for receiver");
        return;
      }

      // 🔹 Send notification: show sender name + message
      await sendPushNotification(
        fcmToken,
        "$senderName 💬", // ✅ title shows sender name
        message, // ✅ body shows the message text
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
    if (currentUserId.isEmpty) {
      debugPrint('❌ No current user ID - returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          // Get the data and manually sort by lastMessageTime
          final chatRooms = snapshot.docs.map((doc) => doc.data()).toList();

          // Sort manually by lastMessageTime (most recent first)
          chatRooms.sort((a, b) {
            final aTime = a['lastMessageTime'] as Timestamp?;
            final bTime = b['lastMessageTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // Descending order
          });

          return chatRooms;
        });
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

  /// ✅ Get active chat rooms with contact information
  Stream<List<ChatRoomWithContact>> getActiveChatRoomsStream() {
    if (currentUserId.isEmpty) {
      debugPrint('❌ No current user - cannot load chats');
      return Stream.error('User not authenticated');
    }

    debugPrint('📱 Loading chats for user: $currentUserId');

    return getChatRoomsStream().asyncMap((chatRooms) async {
      debugPrint('📊 Found ${chatRooms.length} chat rooms');
      final List<ChatRoomWithContact> enrichedChats = [];

      for (final chatRoom in chatRooms) {
        try {
          final participants = List<String>.from(
            chatRoom['participants'] ?? [],
          );

          // Find the other participant (not current user)
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            // Get other user's info from Firestore
            final userDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;

              // Create a ContactModel for the other user
              final contact = ContactModel(
                id: otherUserId,
                name: userData['name'] ?? 'Unknown User',
                email: userData['email'] ?? '',
                phoneNumber: userData['phoneNumber'],
                profilePic: userData['profilePic'],
                addedAt: DateTime.now(), // This doesn't matter for display
              );

              enrichedChats.add(
                ChatRoomWithContact(
                  chatRoom: chatRoom,
                  contact: contact,
                  lastMessageTime: chatRoom['lastMessageTime']?.toDate(),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error enriching chat room: $e');
        }
      }

      // Sort by lastMessageTime (most recent first)
      enrichedChats.sort((a, b) {
        if (a.lastMessageTime != null && b.lastMessageTime != null) {
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        }
        if (a.lastMessageTime != null) return -1;
        if (b.lastMessageTime != null) return 1;
        return 0;
      });

      return enrichedChats;
    });
  }
}

/// Helper class to combine chat room data with contact info
class ChatRoomWithContact {
  final Map<String, dynamic> chatRoom;
  final ContactModel contact;
  final DateTime? lastMessageTime;

  ChatRoomWithContact({
    required this.chatRoom,
    required this.contact,
    this.lastMessageTime,
  });
}
