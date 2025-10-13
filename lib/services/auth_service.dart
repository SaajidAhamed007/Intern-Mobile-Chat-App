import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserModel?> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc =
        await _firestore.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<UserModel?> googleSignIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final user = UserModel(
      uid: userCred.user!.uid,
      name: googleUser.displayName ?? '',
      email: googleUser.email,
      profilePic: googleUser.photoUrl,
    );

    await _firestore.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );

    return user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
