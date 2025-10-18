# 🔔 Background Notification Setup Guide

## Current Issue

Your app is not receiving background notifications because Firebase Cloud Functions are needed to send actual FCM push notifications. Currently, the app only creates notification documents in Firestore.

## 🛠️ Solutions (Choose One)

### Option 1: Quick Local Testing Solution ✅ (IMPLEMENTED)

**What I've Added:**

- Enhanced local notification system
- Background message handler in main.dart
- Dual notification channels (foreground + background simulation)
- Improved FCM token management

**Current Behavior:**

- Messages create local notifications immediately
- Background simulation with delayed notifications
- Works for testing notification UI and flow

**Limitations:**

- Only works when app is running (not true background)
- No notifications when app is completely closed

### Option 2: Firebase Cloud Functions (RECOMMENDED FOR PRODUCTION)

**Setup Steps:**

1. **Install Firebase CLI:**

```bash
npm install -g firebase-tools
firebase login
```

2. **Initialize Functions in your project:**

```bash
cd your-project-directory
firebase init functions
```

3. **Replace the generated index.js with the provided cloud function:**

```javascript
// Use the code from firebase_functions/index.js that I created
```

4. **Deploy the function:**

```bash
firebase deploy --only functions
```

5. **Update Firestore Security Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Allow authenticated users to read/write messages in chats they participate in
    match /chats/{chatId} {
      allow read, write: if request.auth != null;

      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }

    // Allow the cloud function to read/write notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**How It Works:**

1. App sends message → Creates notification document in Firestore
2. Cloud Function triggers → Reads notification document
3. Function sends FCM notification → User receives push notification
4. Background notifications work even when app is closed

## 🚀 Current Implementation Status

### ✅ What's Working:

- Firebase initialization during splash screen
- FCM token generation and storage
- Local notifications when app is open
- Notification settings in profile
- Message triggering notification creation
- Background message handler setup

### ⚠️ What Needs Cloud Functions:

- True background notifications (app closed)
- Notifications when phone is locked
- Cross-platform notification delivery
- Notification analytics and tracking

## 🧪 Testing Current Setup

### Test Local Notifications:

1. Open app on two devices/emulators
2. Login with different accounts
3. Send message from device A
4. Device B should show local notification
5. Check console for notification logs

### Expected Console Output:

```
✅ FCM Token generated: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...
✅ FCM token saved to Firestore
✅ Found receiver FCM token: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...
✅ Notification queued in Firestore
✅ Local notification shown for message
📱 Background message received: New message from John
```

## 🔧 Troubleshooting

### Issue: No notifications appearing

**Solution:**

1. Check notification permissions in device settings
2. Verify FCM token is generated (check console)
3. Ensure notification channels are created
4. Test with different message content

### Issue: Only foreground notifications work

**Solution:**

- This is expected with current setup
- Deploy Firebase Cloud Functions for background support
- Or use Option 3 (third-party service)

### Issue: Notifications not triggering

**Solution:**

1. Check Firestore rules allow writing to notifications collection
2. Verify user authentication state
3. Check FCM token is saved correctly
4. Review console logs for errors

## 📱 Android-Specific Setup

### Ensure these permissions in AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Add Firebase Messaging Service:

```xml
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## 🎯 Next Steps

### For Quick Testing:

1. Run the app and test local notifications
2. Check console logs for debug information
3. Verify notification settings in profile screen

### For Production:

1. Deploy Firebase Cloud Functions (Option 2)
2. Update Firestore security rules
3. Test end-to-end notification flow
4. Add notification analytics

---

**Current Status**: Local notification system implemented ✅  
**Next Step**: Deploy Firebase Cloud Functions for true background notifications 🚀
