import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/contact_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel?> signUp(
    String name,
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return null;

      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Google Sign-In (Currently not implemented)
  /// ----------------------------
  Future<UserModel?> googleSignIn() async {
    // TODO: Implement Google Sign-In when needed
    // The current implementation uses an incompatible API
    throw UnimplementedError(
      'Google Sign-In not yet implemented for this version',
    );
  }

  /// ----------------------------
  /// 🔹 Get Current User Data
  /// ----------------------------
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// ----------------------------
  /// 🔹 Check if user exists in Firestore
  /// ----------------------------
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// ----------------------------
  /// 🔹 Get current Firebase Auth user
  /// ----------------------------
  User? get currentFirebaseUser => _auth.currentUser;

  /// ----------------------------
  /// 🔹 Auth state changes stream
  /// ----------------------------
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ----------------------------
  /// 🔹 Update User Profile
  /// ----------------------------
  Future<UserModel?> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? bio,
    String? profilePic,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get current user data
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final currentUserData = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );

      // Create updated user model with new data
      final updatedUser = UserModel(
        uid: currentUserData.uid,
        name: name ?? currentUserData.name,
        email: currentUserData.email,
        phoneNumber: phoneNumber ?? currentUserData.phoneNumber,
        profilePic: profilePic ?? currentUserData.profilePic,
        bio: bio ?? currentUserData.bio,
        isOnline: currentUserData.isOnline,
        lastSeen: currentUserData.lastSeen,
        contacts: currentUserData.contacts, // 🔹 Preserve contacts array
      );

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toMap());

      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Add Contact
  /// ----------------------------
  Future<UserModel?> addContact({
    required String contactEmail,
    required String contactName,
    String? contactPhone,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
      );

      // Check if contact already exists
      final existingContact = userData.contacts
          .where(
            (contact) =>
                contact.email.toLowerCase() == contactEmail.toLowerCase(),
          )
          .isNotEmpty;

      if (existingContact) {
        throw Exception('Contact already exists');
      }

      // Find the contact user in Firestore by email
      final contactQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: contactEmail.toLowerCase())
          .limit(1)
          .get();

      if (contactQuery.docs.isEmpty) {
        throw Exception('User with this email not found');
      }

      final contactUserData = contactQuery.docs.first.data();

      // Create new contact
      final newContact = ContactModel(
        id: contactUserData['uid'],
        name: contactUserData['name'],
        email: contactUserData['email'],
        phoneNumber: contactUserData['phoneNumber'],
        profilePic: contactUserData['profilePic'],
        addedAt: DateTime.now(),
      );

      // Add contact to user's contacts list
      final updatedContacts = List<ContactModel>.from(userData.contacts)
        ..add(newContact);

      // Update user document with new contacts
      await _firestore.collection('users').doc(currentUser.uid).update({
        'contacts': updatedContacts.map((contact) => contact.toMap()).toList(),
      });

      // Return updated user model
      return userData.copyWith(contacts: updatedContacts);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Remove Contact
  /// ----------------------------
  Future<UserModel?> removeContact(String contactId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
      );

      // Remove contact from list
      final updatedContacts = userData.contacts
          .where((contact) => contact.id != contactId)
          .toList();

      // Update user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'contacts': updatedContacts.map((contact) => contact.toMap()).toList(),
      });

      // Return updated user model
      return userData.copyWith(contacts: updatedContacts);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Search Users by Email or Phone
  /// ----------------------------
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get();

      final List<UserModel> users = [];
      final Set<String> addedUids = {};

      // Add email search results
      for (final doc in emailQuery.docs) {
        final userData = doc.data();
        if (userData['uid'] != currentUser.uid &&
            !addedUids.contains(userData['uid'])) {
          users.add(UserModel.fromMap(userData));
          addedUids.add(userData['uid']);
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  /// ----------------------------
  /// 🔹 Logout
  /// ----------------------------
  Future<void> logout() async {
    try {
      // Sign out from both Firebase and Google
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
