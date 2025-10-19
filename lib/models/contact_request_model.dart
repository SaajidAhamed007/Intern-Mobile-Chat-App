class ContactRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderProfilePic;
  final String receiverId;
  final String receiverName;
  final String receiverEmail;
  final ContactRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message; // Optional message when sending request

  ContactRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderProfilePic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderProfilePic': senderProfilePic,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'message': message,
    };
  }

  // Create from Firestore Map
  factory ContactRequestModel.fromMap(Map<String, dynamic> map) {
    return ContactRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      senderProfilePic: map['senderProfilePic'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverEmail: map['receiverEmail'] ?? '',
      status: ContactRequestStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ContactRequestStatus.pending,
      ),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
      message: map['message'],
    );
  }

  // Create copy with modified fields
  ContactRequestModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderProfilePic,
    String? receiverId,
    String? receiverName,
    String? receiverEmail,
    ContactRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return ContactRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderProfilePic: senderProfilePic ?? this.senderProfilePic,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'ContactRequestModel(id: $id, from: $senderName, to: $receiverName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ContactRequestStatus { pending, accepted, rejected, cancelled }

extension ContactRequestStatusExtension on ContactRequestStatus {
  String get displayName {
    switch (this) {
      case ContactRequestStatus.pending:
        return 'Pending';
      case ContactRequestStatus.accepted:
        return 'Accepted';
      case ContactRequestStatus.rejected:
        return 'Rejected';
      case ContactRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == ContactRequestStatus.pending;
  bool get isResolved =>
      this == ContactRequestStatus.accepted ||
      this == ContactRequestStatus.rejected;
}
