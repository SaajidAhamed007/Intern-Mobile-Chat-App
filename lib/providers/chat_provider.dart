import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentChatUserId;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  // Getters
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get currentChatUserId => _currentChatUserId;
  String get currentUserId => _chatService.currentUserId;

  /// Initialize chat with another user
  void initializeChat(String otherUserId) {
    if (_currentChatUserId == otherUserId)
      return; // Already initialized for this user

    _clearChat();
    _currentChatUserId = otherUserId;
    _listenToMessages();
    _markMessagesAsSeen();
  }

  /// Listen to real-time messages
  void _listenToMessages() {
    if (_currentChatUserId == null) return;

    _isLoading = true;
    _clearError();
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessagesStream(_currentChatUserId!)
        .listen(
          (messagesList) {
            // Get pending messages that haven't been sent yet
            final pendingMessages = _messages
                .where(
                  (msg) =>
                      msg.status == 'pending' &&
                      msg.messageId.startsWith('temp_'),
                )
                .toList();

            // Process server messages to update status based on isSeen field
            final processedMessages = messagesList.map((msg) {
              if (msg.senderId == currentUserId) {
                // For our own messages, update status based on isSeen
                if (msg.isSeen) {
                  return msg.copyWith(status: 'seen');
                } else {
                  return msg.copyWith(status: 'delivered');
                }
              }
              return msg;
            }).toList();

            // Merge pending messages with server messages
            // If a server message matches a pending message (same content, timestamp close),
            // replace the pending with the server message
            final mergedMessages = <MessageModel>[];
            final usedServerMessages = <String>{};

            // First, try to match pending messages with server messages
            for (final pendingMsg in pendingMessages) {
              bool matched = false;
              for (final serverMsg in processedMessages) {
                if (!usedServerMessages.contains(serverMsg.messageId) &&
                    serverMsg.senderId == currentUserId &&
                    serverMsg.message == pendingMsg.message &&
                    serverMsg.timestamp
                            .difference(pendingMsg.timestamp)
                            .abs()
                            .inSeconds <
                        10) {
                  // Found a match - use server message with updated status
                  mergedMessages.add(serverMsg);
                  usedServerMessages.add(serverMsg.messageId);
                  matched = true;
                  break;
                }
              }

              // If no match found, keep the pending message
              if (!matched) {
                mergedMessages.add(pendingMsg);
              }
            }

            // Add remaining server messages that weren't matched
            for (final serverMsg in processedMessages) {
              if (!usedServerMessages.contains(serverMsg.messageId)) {
                mergedMessages.add(serverMsg);
              }
            }

            _messages = mergedMessages;
            _isLoading = false;
            _clearError();
            notifyListeners();

            // Mark messages as seen when received
            _markMessagesAsSeen();
          },
          onError: (error) {
            _setError('Failed to load messages: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Send a text message with immediate UI update
  Future<bool> sendMessage(String message, {String type = 'text'}) async {
    if (_currentChatUserId == null || message.trim().isEmpty || _isSending) {
      return false;
    }

    _isSending = true;
    _clearError();
    notifyListeners();

    // Generate a temporary message ID
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create a pending message that appears immediately in UI
    // Note: Uses local timestamp for immediate display, but server will use
    // server timestamp for proper ordering
    final pendingMessage = MessageModel(
      messageId: tempMessageId,
      senderId: currentUserId,
      receiverId: _currentChatUserId!,
      message: message.trim(),
      type: type,
      timestamp: DateTime.now(), // Local time for pending display
      isSeen: false,
      status: 'pending', // This will show the clock icon
    );

    // Add the pending message to UI immediately
    _messages.insert(
      0,
      pendingMessage,
    ); // Insert at beginning since we use reverse order
    notifyListeners();

    try {
      // Send the actual message to server
      await _chatService.sendMessage(
        receiverId: _currentChatUserId!,
        message: message.trim(),
        type: type,
      );

      // If we reach here, the message was sent successfully
      // Don't remove the pending message here - let the stream matching logic handle it
      // The pending message will be replaced by the server message when it arrives
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      // If sending failed, update status to failed
      final messageIndex = _messages.indexWhere(
        (msg) => msg.messageId == tempMessageId,
      );
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          status: 'failed',
        );
        notifyListeners();
      }
      _setError('Error sending message: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as seen
  Future<void> _markMessagesAsSeen() async {
    if (_currentChatUserId == null) return;

    try {
      await _chatService.markMessagesAsSeen(_currentChatUserId!);
    } catch (e) {
      // Silent error - marking as seen is not critical
      debugPrint('Error marking messages as seen: $e');
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    if (_currentChatUserId == null) return false;

    try {
      final success = await _chatService.deleteMessage(
        _currentChatUserId!,
        messageId,
      );
      if (!success) {
        _setError('Failed to delete message');
      }
      return success;
    } catch (e) {
      _setError('Error deleting message: $e');
      return false;
    }
  }

  /// Get unread message count for a specific user
  int getUnreadCount(String userId) {
    if (_currentChatUserId != userId) return 0;

    return _messages
        .where((msg) => msg.senderId == userId && !msg.isSeen)
        .length;
  }

  /// Clear current chat data
  void _clearChat() {
    _messagesSubscription?.cancel();
    _messages.clear();
    _currentChatUserId = null;
    _isLoading = false;
    _isSending = false;
    _clearError();
  }

  /// Clear chat when navigating away
  void clearChat() {
    _clearChat();
    notifyListeners();
  }

  /// Error handling
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
