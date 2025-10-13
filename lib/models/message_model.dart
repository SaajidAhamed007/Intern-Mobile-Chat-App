class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final String type; // "text", "image", "audio", "video"
  final DateTime timestamp;
  final bool isSeen;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isSeen = false,
  });

  // From Firestore → Model
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: DateTime.parse(map['timestamp']),
      isSeen: map['isSeen'] ?? false,
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
    };
  }
}
