import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/contact_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// ----------------------------
  /// 🔹 Email & Password Sign Up
  /// ----------------------------
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
      print('FirebaseAuth error in signUp: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error in signUp: $e');
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Email & Password Login
  /// ----------------------------
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
        print('⚠️ No Firestore user found for uid: ${user.uid}');
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error in login: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error in login: $e');
      rethrow;
    }
  }

  /// ----------------------------
  /// 🔹 Google Sign-In
  /// ----------------------------
  Future<UserModel?> googleSignIn() async {
    try {
      // Initialize Google Sign-In
      await _googleSignIn.initialize();

      // Begin the authentication process
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) return null; // cancelled by user

      // Get ID token for Firebase
      const List<String> scopes = ['email', 'profile'];

      // Authorize the required scopes
      await googleUser.authorizationClient.authorizeScopes(scopes);

      // For Firebase, we need to get the authentication headers and extract the token
      final headers = await googleUser.authorizationClient.authorizationHeaders(
        scopes,
      );
      if (headers == null) {
        throw Exception('Failed to get authorization headers');
      }

      // Extract the Bearer token from the Authorization header
      final authHeader = headers['Authorization'];
      final accessToken = authHeader?.replaceFirst('Bearer ', '');

      // For ID token, we might need to use a different approach
      // This is a simplified approach - in production, you might need to
      // implement a proper OAuth flow or use server-side authentication
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        // Note: idToken might not be directly available in the new API
        // You might need to implement server-side authentication for full compatibility
      );

      // Sign in with Firebase
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return null;

      // Create or update user in Firestore
      final userModel = UserModel(
        uid: user.uid,
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        profilePic: googleUser.photoUrl,
        // Phone number not available from Google Sign-In by default
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap(), SetOptions(merge: true));

      return userModel;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error in googleSignIn: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error in googleSignIn: $e');
      rethrow;
    }
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
        print('⚠️ No Firestore user found for uid: ${user.uid}');
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting current user: $e');
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
      print('Error checking user existence: $e');
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
        print('⚠️ No Firestore user found for uid: ${user.uid}');
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
      print('Error updating user profile: $e');
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
      print('FirebaseAuth error in addContact: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error adding contact: $e');
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
      print('FirebaseAuth error in removeContact: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error removing contact: $e');
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
      print('Error searching users: $e');
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
