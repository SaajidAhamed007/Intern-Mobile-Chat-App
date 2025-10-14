# 🔔 Testing Notifications in Your Chat App

## ✅ **Current Setup Status**

Your notification system is now configured with:

- ✅ **Local notification listener** - Shows notifications when messages arrive
- ✅ **FCM token management** - Tokens saved to Firestore
- ✅ **Message notification queuing** - Notifications saved to Firestore
- ✅ **Real-time notification display** - Local notifications shown immediately

## 🧪 **How to Test Notifications**

### **Method 1: Two Device Testing (Recommended)**

1. **Setup:**

   - Install app on Device A and Device B
   - Create different accounts on each device
   - Add each other as contacts

2. **Test Steps:**

   - **Device A**: Send message to Device B contact
   - **Device B**: Should receive notification (when app is in background/foreground)
   - **Device B**: Tap notification to open chat

3. **Check Debug Info:**
   - Go to **Profile → Debug Info** on both devices
   - Verify FCM tokens are different
   - Check notification status

### **Method 2: Single Device Testing**

1. **Setup:**

   - Create Account A, login, go to Profile
   - Copy FCM token from Debug Info
   - Logout and create Account B
   - Add Account A as contact

2. **Test:**
   - Send message from Account B to Account A
   - Check Firestore console for notification entries
   - Switch back to Account A to see if local notification appears

### **Method 3: Firestore Manual Testing**

1. **Open Firebase Console → Firestore**
2. **Check Collections:**
   - `users` - Verify FCM tokens are saved
   - `notifications` - See queued notifications
   - `chats` - Verify messages are saved

## 🔍 **Debug Steps**

### **1. Check Profile Settings**

- Go to **Profile → Notification Settings**
- Verify:
  - ✅ "Enable Notifications" is ON
  - ✅ FCM token shows in Debug Info
  - ✅ Status shows "Initialized"

### **2. Check Console Logs**

Look for these messages in the debug console:

```
✅ NotificationService initialized successfully
✅ FCM token saved to Firestore
🔔 Starting to listen for notifications for user: [userId]
📧 Attempting to send notification to [receiverId] from [senderName]
✅ Notification queued in Firestore
🔔 New notification received: [title]
✅ Local notification shown successfully
```

### **3. Check Firestore Database**

1. **Users Collection:**

   ```json
   {
     "name": "John Doe",
     "email": "john@example.com",
     "fcmToken": "eXaMpLeToKeN...",
     "lastTokenUpdate": "timestamp"
   }
   ```

2. **Notifications Collection:**
   ```json
   {
     "receiverUserId": "user123",
     "senderUserId": "user456",
     "senderName": "Alice",
     "title": "New message from Alice",
     "body": "Hello there!",
     "status": "pending" // or "shown"
   }
   ```

## ⚡ **Quick Test Checklist**

- [ ] App builds and runs without errors
- [ ] Can login and see profile
- [ ] FCM token visible in Profile → Debug Info
- [ ] Can add contacts successfully
- [ ] Can send messages in chat
- [ ] Messages appear in Firestore `chats` collection
- [ ] Notifications appear in Firestore `notifications` collection
- [ ] Local notifications show when app receives new messages

## 🐛 **Common Issues & Solutions**

### **No Notifications Appearing:**

1. Check notification permissions in phone settings
2. Verify FCM token is saved in Firestore
3. Ensure both users have added each other as contacts
4. Check if notification listener is initialized

### **FCM Token Not Saved:**

1. Verify user is authenticated before token generation
2. Check Firestore security rules allow token updates
3. Ensure internet connection during login

### **Messages Not Triggering Notifications:**

1. Verify message is saved to Firestore
2. Check sender and receiver IDs are correct
3. Ensure notification listener is active for receiver

## 🚀 **Next Steps for Production**

1. **Deploy Cloud Functions** to send actual FCM push notifications
2. **Add image/media notifications** for multimedia messages
3. **Implement notification sound customization**
4. **Add notification batching** for multiple messages
5. **Set up APNs certificates** for iOS push notifications

Your notification system is now ready for testing! 🎉
