import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/contact_model.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import '../utils/fcm.dart';

enum AuthState {
  unknown,
  authenticated,
  unauthenticated,
  authenticatedWithoutProfile,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitializing = true; // Separate flag for initial auth state check
  bool _isUploadingProfilePic =
      false; // Separate loading state for profile picture
  String? _errorMessage;
  AuthState _authState = AuthState.unknown;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isUploadingProfilePic => _isUploadingProfilePic;
  String? get errorMessage => _errorMessage;
  AuthState get authState => _authState;
  bool get isAuthenticated => _authState == AuthState.authenticated;

  AuthProvider() {
    _initializeAuthState();
  }

  /// Initialize authentication state on app start
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      await _handleAuthStateChange(firebaseUser);
    });
  }

  /// Handle Firebase auth state changes
  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    // Only show loading for operations, not for initial state check
    if (!_isInitializing) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (firebaseUser == null) {
        // User is not authenticated
        _user = null;
        _authState = AuthState.unauthenticated;
      } else {
        // User is authenticated, check if profile exists in Firestore
        final userModel = await _authService.getCurrentUser();

        if (userModel != null) {
          // User is authenticated and has profile
          _user = userModel;
          _authState = AuthState.authenticated;
        } else {
          // User is authenticated but no profile in Firestore
          _user = null;
          _authState = AuthState.authenticatedWithoutProfile;
        }
      }
    } catch (e) {
      // Only set error message for operations, not initialization
      if (!_isInitializing) {
        _errorMessage = 'Error checking user state: $e';
      }
      _authState = _isInitializing
          ? AuthState.unauthenticated
          : AuthState.unknown;
    }

    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Create user profile in Firestore (for users who authenticated but don't have profile)
  Future<bool> createUserProfile(
    String name, {
    String? bio,
    String? profilePic,
  }) async {
    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser == null) return false;

      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: firebaseUser.email ?? '',
        bio: bio,
        profilePic: profilePic,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toMap());

      _user = userModel;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error creating user profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String name,
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    _setLoading(true);

    try {
      final newUser = await _authService.signUp(
        name,
        email,
        password,
        phoneNumber: phoneNumber,
      );
      if (newUser != null) {
        _user = newUser;
        _authState = AuthState.authenticated;
        _clearError();
        await FCMService().saveDeviceToken();
        return true;
      } else {
        _setError('Failed to create user account');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);

    try {
      final loggedUser = await _authService.login(email, password);
      if (loggedUser != null) {
        _user = loggedUser;
        _authState = AuthState.authenticated;
        _clearError();
        await FCMService().saveDeviceToken();
        return true;
      } else {
        _setError('Failed to login. Please check your credentials.');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final googleUser = await _authService.googleSignIn();
      if (googleUser != null) {
        _user = googleUser;
        _authState = AuthState.authenticated;
        _clearError();
        return true;
      } else {
        _setError('Google sign-in was cancelled');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _authState = AuthState.unauthenticated;
      _clearError();
    } catch (e) {
      _setError('Failed to logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? bio,
    String? profilePic,
  }) async {
    _setLoading(true);

    try {
      final updatedUser = await _authService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        bio: bio,
        profilePic: profilePic,
      );

      if (updatedUser != null) {
        // Defensive programming: ensure contacts are preserved
        final currentContacts = _user?.contacts ?? [];
        _user = updatedUser.contacts.isEmpty && currentContacts.isNotEmpty
            ? updatedUser.copyWith(contacts: currentContacts)
            : updatedUser;
        _clearError();
        return true;
      } else {
        _setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload and update profile picture
  Future<bool> updateProfilePicture({
    ImageSource source = ImageSource.gallery,
  }) async {
    _isUploadingProfilePic = true;
    _clearError();
    notifyListeners();

    try {
      // Upload image to your backend server
      final imageUrl = await ImageUploadService.uploadProfilePicture(
        source: source,
      );

      if (imageUrl == null) {
        _setError('Failed to upload image. Please try again.');
        return false;
      }

      // Update user profile with new image URL without triggering global loading
      final updatedUser = await _authService.updateUserProfile(
        profilePic: imageUrl,
      );

      if (updatedUser != null) {
        // Defensive programming: ensure contacts are preserved
        final currentContacts = _user?.contacts ?? [];
        _user = updatedUser.contacts.isEmpty && currentContacts.isNotEmpty
            ? updatedUser.copyWith(contacts: currentContacts)
            : updatedUser;
        _clearError();
        return true;
      } else {
        _setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('Error updating profile picture: $e');
      return false;
    } finally {
      _isUploadingProfilePic = false;
      notifyListeners();
    }
  }

  /// Remove profile picture
  Future<bool> removeProfilePicture() async {
    return await updateUserProfile(profilePic: null);
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    _isUploadingProfilePic = false; // Reset upload state on error
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ----------------------------
  /// 🔹 Add Contact
  /// ----------------------------
  Future<bool> addContact({
    required String contactEmail,
    required String contactName,
    String? contactPhone,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      final updatedUser = await _authService.addContact(
        contactEmail: contactEmail,
        contactName: contactName,
        contactPhone: contactPhone,
      );

      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ----------------------------
  /// 🔹 Remove Contact
  /// ----------------------------
  Future<bool> removeContact(String contactId) async {
    _clearError();
    _setLoading(true);

    try {
      final updatedUser = await _authService.removeContact(contactId);

      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _authService.searchUsers(query);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// ----------------------------
  /// 🔹 Get User Contacts
  /// ----------------------------
  List<ContactModel> get userContacts => _user?.contacts ?? [];

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
