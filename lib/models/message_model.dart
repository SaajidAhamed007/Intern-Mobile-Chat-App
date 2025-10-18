import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final String type; // "text", "image", "audio", "video"
  final DateTime timestamp;
  final bool isSeen;
  final String status; // "pending", "sent", "delivered", "seen"

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isSeen = false,
    this.status = "sent", // Default to sent for existing messages
  });

  // From Firestore → Model
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp - could be Timestamp, String, or null
    DateTime timestamp;
    final timestampValue = map['timestamp'];

    if (timestampValue == null) {
      timestamp = DateTime.now(); // Fallback for null timestamps
    } else if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate(); // Firebase Timestamp
    } else if (timestampValue is String) {
      timestamp = DateTime.parse(timestampValue); // ISO String
    } else {
      timestamp = DateTime.now(); // Fallback for unknown types
    }

    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: timestamp,
      isSeen: map['isSeen'] ?? false,
      status:
          map['status'] ?? 'sent', // Default to sent for backward compatibility
    );
  }

  // Model → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isSeen': isSeen,
      'status': status,
    };
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isSeen,
    String? status,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      status: status ?? this.status,
    );
  }
}
