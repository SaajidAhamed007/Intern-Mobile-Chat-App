class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePic; // optional
  final String? bio;
  final bool isOnline;
  final String? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePic,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
  });

  // Convert from Firestore document → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'],
      bio: map['bio'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'],
    );
  }

  // Convert from UserModel → Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }
}
