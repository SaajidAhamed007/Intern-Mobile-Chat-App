import 'contact_model.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber; // optional
  final String? profilePic; // optional
  final String? bio;
  final bool isOnline;
  final String? lastSeen;
  final List<ContactModel> contacts; // Added contacts array

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePic,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    this.contacts = const [], // Initialize empty contacts list
  });

  // Convert from Firestore document → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Parse contacts from map
    List<ContactModel> contactsList = [];
    if (map['contacts'] != null) {
      contactsList = (map['contacts'] as List)
          .map(
            (contactMap) =>
                ContactModel.fromMap(contactMap as Map<String, dynamic>),
          )
          .toList();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profilePic: map['profilePic'],
      bio: map['bio'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'],
      contacts: contactsList,
    );
  }

  // Convert from UserModel → Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'contacts': contacts
          .map((contact) => contact.toMap())
          .toList(), // Convert contacts to map
    };
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePic,
    String? bio,
    bool? isOnline,
    String? lastSeen,
    List<ContactModel>? contacts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      contacts: contacts ?? this.contacts,
    );
  }
}
