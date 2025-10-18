import '../models/contact_model.dart';
import '../models/message_model.dart';

class ChatListItem {
  final ContactModel contact;
  final MessageModel? lastMessage;
  final int unreadCount;

  ChatListItem({required this.contact, this.lastMessage, this.unreadCount = 0});

  /// Get formatted last message text for display (WhatsApp style)
  String getLastMessageText() {
    if (lastMessage == null) return 'No messages yet';

    final message = lastMessage!.message;

    // For text messages, truncate long messages (like WhatsApp)
    if (message.length > 30) {
      return '${message.substring(0, 30)}...';
    }
    return message;
  }

  /// Get formatted time string (WhatsApp style)
  String getLastMessageTime() {
    if (lastMessage == null) return '';

    final now = DateTime.now();
    final messageTime = lastMessage!.timestamp;
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays == 0) {
      // Today - show time
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[messageTime.weekday - 1];
    } else {
      // Older - show date
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  /// Check if the last message was sent by current user
  bool isLastMessageFromMe(String currentUserId) {
    return lastMessage?.senderId == currentUserId;
  }

  /// Get the message status for sent messages
  String getMessageStatus() {
    if (lastMessage == null) return '';
    return lastMessage!.status;
  }

  /// Check if last message is seen (for sent messages)
  bool isLastMessageSeen() {
    return lastMessage?.isSeen ?? false;
  }
}
