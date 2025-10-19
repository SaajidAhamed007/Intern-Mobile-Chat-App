import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/contact_request_model.dart';
import '../models/contact_model.dart';
import '../models/user_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Send push notification for contact requests
  Future<void> sendContactRequestNotification(
    String fcmToken,
    String title,
    String body,
  ) async {
    final url = Uri.parse(
      "https://hasa-chat-backend-services.onrender.com/send-notification",
    );
    final payload = {'fcmToken': fcmToken, 'title': title, 'body': body};

    debugPrint("📤 Sending contact request notification: $payload");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint(
        "📥 Notification response: ${response.statusCode} - ${response.body}",
      );
    } catch (e) {
      debugPrint("❌ Error sending contact request notification: $e");
    }
  }

  // Send contact request
  Future<bool> sendContactRequest({
    required String receiverId,
    required String receiverName,
    required String receiverEmail,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user');
        return false;
      }

      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ Current user document not found');
        return false;
      }

      final userData = userDoc.data()!;
      final requestId =
          '${currentUser.uid}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('contact_requests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: ContactRequestStatus.pending.toString())
          .get();

      if (existingRequest.docs.isNotEmpty) {
        debugPrint('❌ Contact request already exists');
        return false;
      }

      // Check if they are already contacts
      final areAlreadyContacts = await _checkIfAlreadyContacts(receiverId);
      if (areAlreadyContacts) {
        debugPrint('❌ Users are already contacts');
        return false;
      }

      final contactRequest = ContactRequestModel(
        id: requestId,
        senderId: currentUser.uid,
        senderName: userData['name'] ?? currentUser.displayName ?? '',
        senderEmail: userData['email'] ?? currentUser.email ?? '',
        senderProfilePic: userData['profilePic'],
        receiverId: receiverId,
        receiverName: receiverName,
        receiverEmail: receiverEmail,
        status: ContactRequestStatus.pending,
        createdAt: DateTime.now(),
        message: message,
      );

      await _firestore
          .collection('contact_requests')
          .doc(requestId)
          .set(contactRequest.toMap());

      // 🔔 Send push notification to receiver
      try {
        final receiverDoc = await _firestore
            .collection('users')
            .doc(receiverId)
            .get();

        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data()!;
          final fcmToken = receiverData['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            final senderName =
                userData['name'] ?? currentUser.displayName ?? 'Someone';
            await sendContactRequestNotification(
              fcmToken,
              "📩 New Contact Request",
              "$senderName wants to connect with you",
            );
          } else {
            debugPrint("⚠️ No FCM token found for receiver");
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error sending contact request notification: $e');
        // Don't fail the entire operation if notification fails
      }

      debugPrint('✅ Contact request sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending contact request: $e');
      return false;
    }
  }

  // Accept contact request
  Future<bool> acceptContactRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('contact_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        debugPrint('❌ Contact request not found');
        return false;
      }

      final request = ContactRequestModel.fromMap(requestDoc.data()!);

      // Debug: Verify that the current user is the receiver
      debugPrint('📋 Contact request details:');
      debugPrint(
        '   Request sender: ${request.senderName} (${request.senderId})',
      );
      debugPrint(
        '   Request receiver: ${request.receiverName} (${request.receiverId})',
      );
      debugPrint('   Current user ID: $currentUserId');
      debugPrint(
        '   Is current user the receiver? ${request.receiverId == currentUserId}',
      );

      if (request.receiverId != currentUserId) {
        debugPrint('❌ Not authorized to accept this request');
        return false;
      }

      if (request.status != ContactRequestStatus.pending) {
        debugPrint('❌ Request is not pending');
        return false;
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Update request status
      batch.update(_firestore.collection('contact_requests').doc(requestId), {
        'status': ContactRequestStatus.accepted.toString(),
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Get receiver's profile info for complete contact data
      final receiverDoc = await _firestore
          .collection('users')
          .doc(request.receiverId)
          .get();

      String? receiverProfilePic;
      if (receiverDoc.exists) {
        receiverProfilePic = receiverDoc.data()?['profilePic'];
      }

      // Add contact to sender's contacts list (add receiver's info)
      final senderContact = ContactModel(
        id: request.receiverId,
        name: request.receiverName,
        email: request.receiverEmail,
        profilePic: receiverProfilePic,
        addedAt: DateTime.now(),
      );

      // Add contact to receiver's contacts list (add sender's info)
      final receiverContact = ContactModel(
        id: request.senderId,
        name: request.senderName,
        email: request.senderEmail,
        profilePic: request.senderProfilePic,
        addedAt: DateTime.now(),
      );

      // Update both users' contact lists
      batch.update(_firestore.collection('users').doc(request.senderId), {
        'contacts': FieldValue.arrayUnion([senderContact.toMap()]),
      });

      batch.update(_firestore.collection('users').doc(request.receiverId), {
        'contacts': FieldValue.arrayUnion([receiverContact.toMap()]),
      });

      await batch.commit();

      debugPrint('✅ Contact acceptance completed:');
      debugPrint(
        '   Sender: ${request.senderId} gets contact: ${senderContact.name} (${senderContact.id})',
      );
      debugPrint(
        '   Receiver: ${request.receiverId} gets contact: ${receiverContact.name} (${receiverContact.id})',
      );
      debugPrint('   Current user: $currentUserId');

      // 🔔 Send push notification to the original sender
      try {
        final senderDoc = await _firestore
            .collection('users')
            .doc(request.senderId)
            .get();

        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          final fcmToken = senderData['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await sendContactRequestNotification(
              fcmToken,
              "✅ Contact Request Accepted",
              "${request.receiverName} accepted your contact request! You can now message each other.",
            );
          } else {
            debugPrint("⚠️ No FCM token found for sender");
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error sending acceptance notification: $e');
        // Don't fail the entire operation if notification fails
      }

      debugPrint('✅ Contact request accepted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error accepting contact request: $e');
      return false;
    }
  }

  // Reject contact request
  Future<bool> rejectContactRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('contact_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        debugPrint('❌ Contact request not found');
        return false;
      }

      final request = ContactRequestModel.fromMap(requestDoc.data()!);

      if (request.receiverId != currentUserId) {
        debugPrint('❌ Not authorized to reject this request');
        return false;
      }

      await _firestore.collection('contact_requests').doc(requestId).update({
        'status': ContactRequestStatus.rejected.toString(),
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // 🔔 Send push notification to the original sender (optional)
      try {
        final senderDoc = await _firestore
            .collection('users')
            .doc(request.senderId)
            .get();

        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          final fcmToken = senderData['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await sendContactRequestNotification(
              fcmToken,
              "❌ Contact Request Declined",
              "${request.receiverName} declined your contact request.",
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error sending rejection notification: $e');
        // Don't fail the entire operation if notification fails
      }

      debugPrint('✅ Contact request rejected successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting contact request: $e');
      return false;
    }
  }

  // Cancel sent contact request
  Future<bool> cancelContactRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('contact_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        debugPrint('❌ Contact request not found');
        return false;
      }

      final request = ContactRequestModel.fromMap(requestDoc.data()!);

      if (request.senderId != currentUserId) {
        debugPrint('❌ Not authorized to cancel this request');
        return false;
      }

      await _firestore.collection('contact_requests').doc(requestId).update({
        'status': ContactRequestStatus.cancelled.toString(),
        'respondedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Contact request cancelled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling contact request: $e');
      return false;
    }
  }

  // Get received contact requests (pending)
  Stream<List<ContactRequestModel>> getReceivedContactRequests() {
    return _firestore
        .collection('contact_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: ContactRequestStatus.pending.toString())
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ContactRequestModel.fromMap(doc.data()))
              .toList();

          // Sort manually by createdAt in descending order
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get sent contact requests
  Stream<List<ContactRequestModel>> getSentContactRequests() {
    return _firestore
        .collection('contact_requests')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ContactRequestModel.fromMap(doc.data()))
              .toList();

          // Sort manually by createdAt in descending order
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Search users by email or name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Search by name (case insensitive)
      final nameQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .limit(20)
          .get();

      final users = <UserModel>[];
      final addedUserIds = <String>{};

      // Add users from name search
      for (final doc in nameQuery.docs) {
        if (doc.id != currentUserId && !addedUserIds.contains(doc.id)) {
          users.add(UserModel.fromMap(doc.data()));
          addedUserIds.add(doc.id);
        }
      }

      // Add users from email search
      for (final doc in emailQuery.docs) {
        if (doc.id != currentUserId && !addedUserIds.contains(doc.id)) {
          users.add(UserModel.fromMap(doc.data()));
          addedUserIds.add(doc.id);
        }
      }

      return users;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // Check if users are already contacts
  Future<bool> _checkIfAlreadyContacts(String userId) async {
    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists) return false;

      final userData = currentUserDoc.data()!;
      final contacts = userData['contacts'] as List? ?? [];

      return contacts.any((contact) => contact['id'] == userId);
    } catch (e) {
      debugPrint('❌ Error checking if already contacts: $e');
      return false;
    }
  }

  // Check if contact request exists between users
  Future<ContactRequestModel?> getExistingContactRequest(String userId) async {
    try {
      // Check if current user sent a request to userId
      final sentRequest = await _firestore
          .collection('contact_requests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: ContactRequestStatus.pending.toString())
          .get();

      if (sentRequest.docs.isNotEmpty) {
        return ContactRequestModel.fromMap(sentRequest.docs.first.data());
      }

      // Check if userId sent a request to current user
      final receivedRequest = await _firestore
          .collection('contact_requests')
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: ContactRequestStatus.pending.toString())
          .get();

      if (receivedRequest.docs.isNotEmpty) {
        return ContactRequestModel.fromMap(receivedRequest.docs.first.data());
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking existing contact request: $e');
      return null;
    }
  }

  // Check relationship status between current user and another user
  Future<UserRelationshipStatus> getRelationshipStatus(String userId) async {
    try {
      // Check if already contacts
      final areContacts = await _checkIfAlreadyContacts(userId);
      if (areContacts) {
        return UserRelationshipStatus.contacts;
      }

      // Check for existing contact request
      final existingRequest = await getExistingContactRequest(userId);
      if (existingRequest != null) {
        if (existingRequest.senderId == currentUserId) {
          return UserRelationshipStatus.requestSent;
        } else {
          return UserRelationshipStatus.requestReceived;
        }
      }

      return UserRelationshipStatus.none;
    } catch (e) {
      debugPrint('❌ Error getting relationship status: $e');
      return UserRelationshipStatus.none;
    }
  }

  // Remove contact
  Future<bool> removeContact(String contactId) async {
    try {
      final batch = _firestore.batch();

      // Remove from current user's contacts
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data()!;
        final contacts = List<Map<String, dynamic>>.from(
          userData['contacts'] ?? [],
        );
        contacts.removeWhere((contact) => contact['id'] == contactId);

        batch.update(_firestore.collection('users').doc(currentUserId), {
          'contacts': contacts,
        });
      }

      // Remove from other user's contacts
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(contactId)
          .get();

      if (otherUserDoc.exists) {
        final userData = otherUserDoc.data()!;
        final contacts = List<Map<String, dynamic>>.from(
          userData['contacts'] ?? [],
        );
        contacts.removeWhere((contact) => contact['id'] == currentUserId);

        batch.update(_firestore.collection('users').doc(contactId), {
          'contacts': contacts,
        });
      }

      await batch.commit();

      debugPrint('✅ Contact removed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing contact: $e');
      return false;
    }
  }

  /// Get user contacts as a real-time stream
  Stream<List<ContactModel>> getUserContactsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return <ContactModel>[];

      final userData = snapshot.data()!;
      final contactsData = userData['contacts'] as List? ?? [];

      return contactsData.map((contactData) {
        return ContactModel.fromMap(contactData as Map<String, dynamic>);
      }).toList();
    });
  }
}

enum UserRelationshipStatus {
  none, // No relationship
  contacts, // Already contacts
  requestSent, // Current user sent request
  requestReceived, // Current user received request
}

extension UserRelationshipStatusExtension on UserRelationshipStatus {
  String get displayName {
    switch (this) {
      case UserRelationshipStatus.none:
        return 'Send Request';
      case UserRelationshipStatus.contacts:
        return 'Contact';
      case UserRelationshipStatus.requestSent:
        return 'Request Sent';
      case UserRelationshipStatus.requestReceived:
        return 'Accept Request';
    }
  }

  bool get canSendMessage {
    return this == UserRelationshipStatus.contacts;
  }

  bool get canSendRequest {
    return this == UserRelationshipStatus.none;
  }

  bool get canAcceptRequest {
    return this == UserRelationshipStatus.requestReceived;
  }
}
