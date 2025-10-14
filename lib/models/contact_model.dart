class ContactModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePic;
  final DateTime addedAt;
  final bool isBlocked;

  ContactModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePic,
    required this.addedAt,
    this.isBlocked = false,
  });

  // Convert ContactModel to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'addedAt': addedAt.toIso8601String(),
      'isBlocked': isBlocked,
    };
  }

  // Create ContactModel from Map (from Firestore)
  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profilePic: map['profilePic'],
      addedAt: DateTime.parse(
        map['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
      isBlocked: map['isBlocked'] ?? false,
    );
  }

  // Create a copy with modified fields
  ContactModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePic,
    DateTime? addedAt,
    bool? isBlocked,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePic: profilePic ?? this.profilePic,
      addedAt: addedAt ?? this.addedAt,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $name, email: $email, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
