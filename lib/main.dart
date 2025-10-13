import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");

    // Test Firestore connection with better error handling
    await testFirestoreConnection();
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(HasaApp());
}

Future<void> testFirestoreConnection() async {
  try {
    // Set a timeout for the Firestore operation
    await FirebaseFirestore.instance
        .collection('test')
        .doc('ping')
        .set({'status': 'connected', 'timestamp': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 10));
    print("Firestore Connected!");
  } catch (e) {
    print("Firestore connection error: $e");
    // Don't prevent app from starting if Firestore fails
  }
}

class HasaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasa Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: SplashScreen(),
    );
  }
}
