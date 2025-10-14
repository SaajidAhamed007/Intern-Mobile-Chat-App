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
            _messages = messagesList;
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

  /// Send a text message
  Future<bool> sendMessage(String message, {String type = 'text'}) async {
    if (_currentChatUserId == null || message.trim().isEmpty) return false;

    _isSending = true;
    _clearError();
    notifyListeners();

    try {
      final success = await _chatService.sendMessage(
        receiverId: _currentChatUserId!,
        message: message.trim(),
        type: type,
      );

      if (!success) {
        _setError('Failed to send message');
      }

      return success;
    } catch (e) {
      _setError('Error sending message: $e');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
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
