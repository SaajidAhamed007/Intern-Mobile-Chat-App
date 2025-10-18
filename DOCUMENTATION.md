# 📱 Hasa Chat App - Complete Documentation

## 📋 Table of Contents

1. [App Overview](#app-overview)
2. [Project Structure](#project-structure)
3. [Core Features](#core-features)
4. [Authentication System](#authentication-system)
5. [Chat System](#chat-system)
6. [Notification System](#notification-system)
7. [Theme System](#theme-system)
8. [Firebase Integration](#firebase-integration)
9. [Workflow Diagrams](#workflow-diagrams)
10. [Function Documentation](#function-documentation)

---

## 🎯 App Overview

**Hasa** is a modern real-time chat application built with Flutter and Firebase. It features secure authentication, real-time messaging, push notifications, and a beautiful Material 3 design with dark/light theme support.

### Key Technologies

- **Frontend**: Flutter 3.35.3 with Material 3 Design
- **Backend**: Firebase (Authentication, Firestore, Cloud Messaging)
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences
- **Notifications**: Firebase Cloud Messaging + flutter_local_notifications

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point & Firebase initialization
├── models/                      # Data models
│   ├── user_model.dart         # User data structure
│   └── message_model.dart      # Message data structure
├── providers/                   # State management
│   ├── auth_provider.dart      # Authentication state
│   ├── chat_provider.dart      # Chat functionality state
│   ├── notification_provider.dart # Notification settings
│   └── theme_provider.dart     # Dark/Light theme management
├── services/                    # Business logic
│   ├── auth_service.dart       # Firebase Authentication
│   ├── chat_service.dart       # Chat & messaging logic
│   └── notification_service.dart # Push notifications
├── screens/                     # UI screens
│   ├── splash_screen.dart      # Loading screen
│   ├── login_screen.dart       # Authentication UI
│   ├── signup_screen.dart      # User registration
│   ├── home_screen.dart        # Chat list
│   ├── chat_screen.dart        # Individual chat
│   └── profile_screen.dart     # User profile & settings
└── widgets/                     # Reusable UI components
```

---

## 🔥 Core Features

### 1. **Real-time Authentication**

- Google Sign-In integration
- Email/Password authentication
- Persistent login state
- User profile management

### 2. **Real-time Messaging**

- Instant message delivery
- Message status indicators
- Firestore real-time listeners
- User search functionality

### 3. **Push Notifications**

- Firebase Cloud Messaging (FCM)
- Local notifications
- Background message handling
- Notification settings

### 4. **Modern UI/UX**

- Material 3 design system
- Dark/Light theme toggle
- Smooth animations
- Responsive design

---

## 🔐 Authentication System

### Workflow Overview

```
App Start → Splash Screen → Firebase Init → Check Auth State → Login/Home
```

### Components

#### **AuthProvider** (`providers/auth_provider.dart`)

**Purpose**: Manages user authentication state across the app

**Key Functions**:

```dart
// Initialize authentication and check current user
Future<void> initializeAuth()

// Sign in with Google
Future<bool> signInWithGoogle()

// Sign in with email/password
Future<bool> signInWithEmailPassword(String email, String password)

// Register new user
Future<bool> registerWithEmailPassword(String email, String password, String name)

// Sign out user
Future<void> logout()

// Update user profile
Future<bool> updateUserProfile({String? bio, String? phoneNumber})
```

**State Properties**:

- `authState`: Current authentication status
- `user`: Current user data
- `isLoading`: Loading indicator
- `errorMessage`: Error handling

#### **AuthService** (`services/auth_service.dart`)

**Purpose**: Handles Firebase Authentication operations

**Key Functions**:

```dart
// Google Sign-In flow
Future<UserCredential?> signInWithGoogle()

// Email/Password authentication
Future<UserCredential?> signInWithEmailAndPassword(String email, String password)

// User registration
Future<UserCredential?> registerWithEmailAndPassword(String email, String password)

// Save user data to Firestore
Future<void> saveUserToFirestore(User user, String name)

// Search users for chat
Future<List<UserModel>> searchUsers(String query)
```

### Authentication Flow

1. **App Launch**: `AuthWrapper` checks Firebase authentication state
2. **Splash Screen**: Shows while Firebase initializes
3. **State Check**: AuthProvider determines if user is logged in
4. **Navigation**: Redirects to Login or Home based on auth state
5. **Persistence**: User stays logged in between app sessions

---

## 💬 Chat System

### Workflow Overview

```
User Search → Start Chat → Real-time Messages → Notification Trigger
```

### Components

#### **ChatProvider** (`providers/chat_provider.dart`)

**Purpose**: Manages chat state and message operations

**Key Functions**:

```dart
// Send message to chat
Future<void> sendMessage(String chatId, String content)

// Get chat messages stream
Stream<List<MessageModel>> getMessages(String chatId)

// Create new chat room
Future<String> createChatRoom(String receiverId)

// Get user's chat list
Future<List<Chat>> getUserChats()
```

#### **ChatService** (`services/chat_service.dart`)

**Purpose**: Handles Firestore chat operations and notifications

**Key Functions**:

```dart
// Send message with notification
Future<bool> sendMessage({
  required String receiverUserId,
  required String message,
  required String senderName
})

// Create chat document
Future<String> createChat(String user1Id, String user2Id)

// Get messages stream
Stream<QuerySnapshot> getMessages(String chatId)

// Get chat list for user
Stream<QuerySnapshot> getChats(String userId)
```

### Chat Data Structure

#### **MessageModel** (`models/message_model.dart`)

```dart
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
}
```

#### **UserModel** (`models/user_model.dart`)

```dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePic;
  final String? bio;
  final String? phoneNumber;
  final String? fcmToken;
}
```

### Chat Flow

1. **User Search**: Find users by name/email
2. **Chat Creation**: Create chat room between two users
3. **Message Sending**: Send message to Firestore
4. **Real-time Updates**: Listen to message stream
5. **Notification**: Trigger FCM notification to receiver

---

## 🔔 Notification System

### Workflow Overview

```
Message Sent → FCM Token Retrieved → Notification Queued → FCM Delivery → Local Display
```

### Components

#### **NotificationProvider** (`providers/notification_provider.dart`)

**Purpose**: Manages notification settings and permissions

**Key Functions**:

```dart
// Initialize notification service
Future<void> initialize()

// Send notification to user
Future<bool> sendNotificationToUser({
  required String receiverUserId,
  required String senderName,
  required String message
})

// Toggle notification settings
Future<void> setNotificationsEnabled(bool enabled)
Future<void> setSoundEnabled(bool enabled)
Future<void> setVibrationEnabled(bool enabled)

// Check permission status
Future<AuthorizationStatus> getNotificationPermissionStatus()
```

#### **NotificationService** (`services/notification_service.dart`)

**Purpose**: Handles FCM integration and local notifications

**Key Functions**:

```dart
// Initialize FCM and local notifications
Future<bool> initialize()

// Get FCM token
Future<String?> getFCMToken()

// Save token to Firestore
Future<void> saveFCMTokenToFirestore(String token)

// Send notification to specific user
Future<bool> sendNotificationToUser({
  required String receiverUserId,
  required String senderName,
  required String message
})

// Show local notification
Future<void> showLocalNotification(String title, String body)

// Handle foreground messages
void handleForegroundMessage(RemoteMessage message)
```

### Notification Flow

1. **Initialization**: Request permissions and get FCM token
2. **Token Storage**: Save FCM token to user's Firestore document
3. **Message Trigger**: When message is sent, create notification document
4. **FCM Delivery**: Firebase sends push notification to device
5. **Local Display**: App shows notification locally if in foreground
6. **User Interaction**: Notification tap opens specific chat

### Firebase Cloud Messaging Setup

```yaml
# android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />

<service
android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
android:exported="false">
<intent-filter>
<action android:name="com.google.firebase.MESSAGING_EVENT" />
</intent-filter>
</service>
```

---

## 🎨 Theme System

### Components

#### **ThemeProvider** (`providers/theme_provider.dart`)

**Purpose**: Manages app theme and user preferences

**Key Functions**:

```dart
// Initialize theme from storage
Future<void> initializeTheme()

// Toggle between dark/light mode
Future<void> toggleTheme()

// Set specific theme mode
Future<void> setThemeMode(bool isDark)

// Get current theme data
ThemeData get currentTheme
ThemeData get lightTheme
ThemeData get darkTheme
```

**Theme Features**:

- Material 3 design system
- Persistent theme selection
- Smooth theme transitions
- Custom color schemes
- Consistent component styling

### Theme Persistence

- Uses `SharedPreferences` to store user's theme choice
- Automatically loads saved theme on app restart
- Syncs theme across all app screens

---

## 🔥 Firebase Integration

### Services Used

#### **Firebase Authentication**

- Email/Password authentication
- Google Sign-In provider
- User session management
- Profile data storage

#### **Cloud Firestore**

- Real-time message storage
- User profile data
- Chat room management
- Notification queue

#### **Firebase Cloud Messaging**

- Push notification delivery
- FCM token management
- Background message handling
- Cross-platform support

### Firestore Data Structure

```javascript
// Users Collection
users/{userId} {
  uid: string,
  name: string,
  email: string,
  profilePic?: string,
  bio?: string,
  phoneNumber?: string,
  fcmToken?: string,
  createdAt: timestamp,
  lastSeen: timestamp
}

// Chats Collection
chats/{chatId} {
  participants: [userId1, userId2],
  createdAt: timestamp,
  lastMessage?: {
    content: string,
    senderId: string,
    timestamp: timestamp
  }
}

// Messages Collection
chats/{chatId}/messages/{messageId} {
  senderId: string,
  receiverId: string,
  content: string,
  timestamp: timestamp,
  status: 'sent' | 'delivered' | 'read'
}

// Notifications Collection
notifications/{notificationId} {
  receiverUserId: string,
  senderUserId: string,
  title: string,
  body: string,
  fcmToken: string,
  status: 'pending' | 'sent' | 'delivered',
  createdAt: timestamp
}
```

---

## 📊 Workflow Diagrams

### App Initialization Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│  App Start  │ -> │ Splash Screen│ -> │Firebase Init│ -> │ Auth Check   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
                                                                   │
                                        ┌──────────────┐           │
                                        │ Theme Load   │ <---------┘
                                        └──────────────┘
                                                │
                          ┌─────────────────────┴─────────────────────┐
                          │                                           │
                   ┌──────▼──────┐                           ┌───────▼───────┐
                   │ Login Screen│                           │  Home Screen  │
                   └─────────────┘                           └───────────────┘
```

### Message Sending Flow

```
┌──────────────┐    ┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ User Types   │ -> │Send Message │ -> │Save to       │ -> │Get Receiver │
│ Message      │    │Button       │    │Firestore     │    │FCM Token    │
└──────────────┘    └─────────────┘    └──────────────┘    └─────────────┘
                                                                   │
┌──────────────┐    ┌─────────────┐    ┌──────────────┐           │
│FCM Delivery  │ <- │Queue        │ <- │Create        │ <---------┘
│& Local Show  │    │Notification │    │Notification  │
└──────────────┘    └─────────────┘    └──────────────┘
```

### Authentication Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│Login Screen │ -> │Choose Method │ -> │Google OAuth │
└─────────────┘    └──────────────┘    └─────────────┘
                            │                   │
                   ┌────────▼────────┐         │
                   │Email/Password   │         │
                   └─────────────────┘         │
                            │                   │
                   ┌────────▼───────────────────▼──┐
                   │     Firebase Auth            │
                   └────────┬─────────────────────┘
                            │
                   ┌────────▼────────┐
                   │Save User Data   │
                   │to Firestore     │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │Navigate to      │
                   │Home Screen      │
                   └─────────────────┘
```

---

## 📖 Function Documentation

### Main App Functions

#### **main()** - App Entry Point

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HasaApp());
}
```

**Purpose**: Initialize Flutter and start the app
**Parameters**: None
**Returns**: void
**Side Effects**: Launches the Flutter application

#### **\_initializeFirebase()** - Firebase Setup

```dart
Future<void> _initializeFirebase() async
```

**Purpose**: Initialize Firebase services and test connectivity
**Parameters**: None  
**Returns**: Future<void>
**Side Effects**:

- Initializes Firebase Core
- Tests Firestore connection
- Logs success/error messages

### Authentication Functions

#### **signInWithGoogle()** - Google Authentication

```dart
Future<bool> signInWithGoogle() async
```

**Purpose**: Handle Google Sign-In flow
**Parameters**: None
**Returns**: bool - true if successful, false if failed
**Side Effects**:

- Opens Google Sign-In dialog
- Creates Firebase user account
- Saves user data to Firestore
- Updates authentication state

#### **registerWithEmailPassword()** - Email Registration

```dart
Future<bool> registerWithEmailPassword(String email, String password, String name) async
```

**Purpose**: Register new user with email and password
**Parameters**:

- `email`: User's email address
- `password`: User's password (min 6 characters)
- `name`: User's display name
  **Returns**: bool - true if successful, false if failed
  **Side Effects**:
- Creates Firebase Authentication account
- Saves user profile to Firestore
- Generates FCM token

### Chat Functions

#### **sendMessage()** - Send Chat Message

```dart
Future<bool> sendMessage({
  required String receiverUserId,
  required String message,
  required String senderName
}) async
```

**Purpose**: Send message and trigger notification
**Parameters**:

- `receiverUserId`: ID of message recipient
- `message`: Message content
- `senderName`: Sender's display name
  **Returns**: bool - true if sent successfully
  **Side Effects**:
- Saves message to Firestore
- Creates notification document
- Triggers FCM notification

#### **createChatRoom()** - Create Chat

```dart
Future<String> createChatRoom(String receiverId) async
```

**Purpose**: Create new chat room between two users
**Parameters**:

- `receiverId`: ID of the other user
  **Returns**: String - Chat room ID
  **Side Effects**: Creates chat document in Firestore

### Notification Functions

#### **initialize()** - Setup Notifications

```dart
Future<bool> initialize() async
```

**Purpose**: Initialize notification system
**Parameters**: None
**Returns**: bool - true if initialized successfully
**Side Effects**:

- Requests notification permissions
- Gets FCM token
- Sets up message handlers
- Saves token to Firestore

#### **sendNotificationToUser()** - Send Push Notification

```dart
Future<bool> sendNotificationToUser({
  required String receiverUserId,
  required String senderName,
  required String message
}) async
```

**Purpose**: Send push notification to specific user
**Parameters**:

- `receiverUserId`: Target user ID
- `senderName`: Sender's name for notification
- `message`: Notification message
  **Returns**: bool - true if notification sent
  **Side Effects**: Creates notification document in Firestore

### Theme Functions

#### **toggleTheme()** - Switch Theme

```dart
Future<void> toggleTheme() async
```

**Purpose**: Toggle between dark and light theme
**Parameters**: None
**Returns**: Future<void>
**Side Effects**:

- Switches app theme
- Saves preference to SharedPreferences
- Notifies all listeners

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.35.3+)
- Firebase project setup
- Android/iOS development environment

### Installation

1. Clone repository
2. Run `flutter pub get`
3. Setup Firebase configuration
4. Configure FCM for notifications
5. Run `flutter run`

### Configuration Files

- `android/app/google-services.json` - Firebase config
- `pubspec.yaml` - Dependencies
- `analysis_options.yaml` - Lint rules

---

## 🔧 Troubleshooting

### Common Issues

1. **Firebase not initialized**

   - Ensure Firebase.initializeApp() completes before using services
   - Check google-services.json is in correct location

2. **Notifications not working**

   - Verify FCM permissions in AndroidManifest.xml
   - Check FCM token generation and storage
   - Ensure notification channels are created

3. **Theme not persisting**

   - Check SharedPreferences initialization
   - Verify theme provider is in widget tree

4. **Chat messages not updating**
   - Confirm Firestore rules allow read/write
   - Check stream listeners are properly disposed
   - Verify user authentication

---

## 📱 Platform Support

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Web**: Limited (FCM not fully supported)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

_This documentation covers the complete architecture and functionality of the Hasa Chat App. For specific implementation details, refer to the individual source files._
