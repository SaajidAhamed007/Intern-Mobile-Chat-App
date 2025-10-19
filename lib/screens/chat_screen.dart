import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/contact_model.dart';
import '../models/message_model.dart';
import '../providers/chat_provider.dart';
import '../services/unified_upload_service.dart';
import '../widgets/message_skeleton.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/profile_picture.dart';
import '../widgets/media_selection_bottom_sheet.dart';
import 'media_preview_screen.dart' as preview;

class ChatScreen extends StatefulWidget {
  final ContactModel contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastMessageId;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();

    // Initialize chat when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.initializeChat(widget.contact.id);
      _scrollToBottomInstant();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for message changes
    _updateMessages();
  }

  void _updateMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final newMessages = chatProvider.messages;

    // Check if we have new messages
    if (newMessages.isNotEmpty &&
        (newMessages.first.messageId != _lastMessageId)) {
      _lastMessageId = newMessages.first.messageId;
      // Auto-scroll to bottom for new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a small delay to ensure the message is rendered first
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // For reversed list, 0.0 is the bottom
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _scrollToBottomInstant() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Clear chat when leaving screen
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearChat();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear the input field immediately (like WhatsApp)
    _messageController.clear();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Send message (this will add it to UI immediately with pending status)
    await chatProvider.sendMessage(message);

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _showMediaPicker() async {
    await MediaSelectionBottomSheet.show(
      context,
      onMediaSelected: _handleMediaSelection,
    );
  }

  Future<void> _handleMediaSelection(
    MediaType mediaType,
    ImageSource? source,
  ) async {
    setState(() {
      _isUploadingMedia = true;
    });

    try {
      debugPrint(
        '🎯 Handling media selection: ${mediaType.name} with source: $source',
      );

      switch (mediaType) {
        case MediaType.image:
          await _handleImageSelection(source!);
          break;
        case MediaType.video:
          await _handleVideoSelection(source!);
          break;
        case MediaType.audio:
          await _handleAudioSelection();
          break;
        case MediaType.document:
          await _handleDocumentSelection();
          break;
      }
    } catch (e) {
      debugPrint('❌ Error in media selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error handling ${mediaType.name}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      // First, pick the image
      final mediaFile = await UnifiedUploadService.pickMedia(
        type: MediaType.image,
        source: source,
      );

      if (mediaFile == null || !mounted) return;

      final imageFile = File(mediaFile.path);

      // Show preview screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => preview.MediaPreviewScreen(
            mediaFile: imageFile,
            mediaType: preview.MediaType.image,
            onSend: (caption) async {
              await _sendImageMessage(imageFile, caption);
            },
          ),
        ),
      );

      // If user cancelled, clean up the temp file if needed
      if (result != true) {
        debugPrint('📸 Image sending cancelled by user');
      }
    } catch (e) {
      debugPrint('❌ Error in image selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendImageMessage(File imageFile, String caption) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Create a temporary message ID for immediate UI display
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create pending message with local image path (for immediate display)
    final pendingMessage = MessageModel(
      messageId: tempMessageId,
      senderId: chatProvider.currentUserId,
      receiverId: widget.contact.id,
      message: imageFile.path, // Use local path temporarily
      type: 'image',
      timestamp: DateTime.now(),
      isSeen: false,
      status: 'pending',
    );

    // Add to chat immediately with pending status
    chatProvider.addPendingMessage(pendingMessage);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Upload the image
      final mediaFile = MediaFile(
        path: imageFile.path,
        name: imageFile.path.split('/').last,
        type: MediaType.image,
        size: await imageFile.length(),
      );

      final uploadResult = await UnifiedUploadService.uploadMedia(
        mediaFile: mediaFile,
      );

      if (uploadResult.success && uploadResult.url != null) {
        // Update message status to sent and use the uploaded URL
        await chatProvider.sendMessage(
          caption.isNotEmpty
              ? '${uploadResult.url}\n\n$caption'
              : uploadResult.url!,
          type: 'image',
          tempMessageId: tempMessageId,
        );

        debugPrint('✅ Image sent successfully: ${uploadResult.url}');
      } else {
        // Update message status to failed
        chatProvider.updateMessageStatus(tempMessageId, 'failed');
        throw Exception(uploadResult.error ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('❌ Error sending image: $e');
      // Update message status to failed
      chatProvider.updateMessageStatus(tempMessageId, 'failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendImageMessage(imageFile, caption),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendVideoMessage(File videoFile, String caption) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Create a temporary message ID for immediate UI display
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create pending message with local video path (for immediate display)
    final pendingMessage = MessageModel(
      messageId: tempMessageId,
      senderId: chatProvider.currentUserId,
      receiverId: widget.contact.id,
      message: videoFile.path, // Use local path temporarily
      type: 'video',
      timestamp: DateTime.now(),
      isSeen: false,
      status: 'pending',
    );

    // Add to chat immediately with pending status
    chatProvider.addPendingMessage(pendingMessage);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Upload the video
      final mediaFile = MediaFile(
        path: videoFile.path,
        name: videoFile.path.split('/').last,
        type: MediaType.video,
        size: await videoFile.length(),
      );

      final uploadResult = await UnifiedUploadService.uploadMedia(
        mediaFile: mediaFile,
      );

      if (uploadResult.success && uploadResult.url != null) {
        // Update message status to sent and use the uploaded URL
        await chatProvider.sendMessage(
          caption.isNotEmpty
              ? '${uploadResult.url}\n\n$caption'
              : uploadResult.url!,
          type: 'video',
          tempMessageId: tempMessageId,
        );

        debugPrint('✅ Video sent successfully: ${uploadResult.url}');
      } else {
        // Update message status to failed
        chatProvider.updateMessageStatus(tempMessageId, 'failed');
        throw Exception(uploadResult.error ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('❌ Error sending video: $e');
      // Update message status to failed
      chatProvider.updateMessageStatus(tempMessageId, 'failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send video: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendVideoMessage(videoFile, caption),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleVideoSelection(ImageSource source) async {
    try {
      // First, pick the video
      final mediaFile = await UnifiedUploadService.pickMedia(
        type: MediaType.video,
        source: source,
      );

      if (mediaFile == null || !mounted) return;

      final videoFile = File(mediaFile.path);

      // Show preview screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => preview.MediaPreviewScreen(
            mediaFile: videoFile,
            mediaType: preview.MediaType.video,
            onSend: (caption) async {
              await _sendVideoMessage(videoFile, caption);
            },
          ),
        ),
      );

      // If user cancelled, clean up the temp file if needed
      if (result != true) {
        debugPrint('🎥 Video sending cancelled by user');
      }
    } catch (e) {
      debugPrint('❌ Error in video selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleAudioSelection() async {
    debugPrint('🎵 Starting audio upload');
    final result = await UnifiedUploadService.uploadAudio();
    await _processUploadResult(result, 'audio');
  }

  Future<void> _handleDocumentSelection() async {
    debugPrint('📄 Starting document upload');
    final result = await UnifiedUploadService.uploadDocument();
    await _processUploadResult(result, 'document');
  }

  Future<void> _processUploadResult(
    UploadResult result,
    String mediaType,
  ) async {
    if (result.success &&
        result.url != null &&
        result.url!.isNotEmpty &&
        mounted) {
      debugPrint('✅ Media upload successful, sending message: ${result.url}');
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(result.url!, type: mediaType);

      // Scroll to bottom after sending media
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mediaType.toUpperCase()} sent successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      debugPrint('❌ Media upload failed: ${result.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ?? 'Failed to upload $mediaType. Please try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        elevation: 0.3,
        title: Row(
          children: [
            SmallProfilePicture(
              imageUrl: widget.contact.profilePic,
              name: widget.contact.name,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add voice call functionality
            },
            icon: Icon(Icons.call, color: theme.colorScheme.onSurface),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add video call functionality
            },
            icon: Icon(Icons.videocam, color: theme.colorScheme.onSurface),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'contact_info',
                child: Text('Contact info'),
              ),
              const PopupMenuItem(
                value: 'clear_chat',
                child: Text('Clear chat'),
              ),
              const PopupMenuItem(value: 'block', child: Text('Block contact')),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const MessageSkeleton();
          }

          return Column(
            children: [
              // Messages List
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation with ${widget.contact.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        children: _buildChatItems(
                          chatProvider.messages,
                          chatProvider.currentUserId,
                          theme,
                        ),
                      ),
              ),

              // Message Input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isUploadingMedia ? null : _showMediaPicker,
                      icon: _isUploadingMedia
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.attach_file,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant
                              .withOpacity(0.3),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // This week - show day name
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[messageDate.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<Widget> _buildChatItems(
    List<MessageModel> messages,
    String currentUserId,
    ThemeData theme,
  ) {
    if (messages.isEmpty) return [];

    List<Widget> items = [];

    // ✅ Sort messages by timestamp (oldest first)
    final sortedMessages = List<MessageModel>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // ✅ Group messages by date (same day = same key)
    Map<String, List<MessageModel>> messagesByDate = {};
    for (final message in sortedMessages) {
      final dateKey = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      ).toIso8601String();

      messagesByDate.putIfAbsent(dateKey, () => []);
      messagesByDate[dateKey]!.add(message);
    }

    // ✅ Sort date groups (oldest first)
    final sortedDates = messagesByDate.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    // ✅ Build widgets for each date group
    for (final dateKey in sortedDates) {
      final messagesForDate = messagesByDate[dateKey]!;

      // Add date separator first
      items.add(
        _buildDateSeparator(
          _formatDateHeader(messagesForDate.first.timestamp),
          theme,
        ),
      );

      // Add all messages for that date (oldest first)
      for (final message in messagesForDate) {
        final isMe = message.senderId == currentUserId;
        items.add(ChatBubble(message: message, isMe: isMe));
      }
    }

    // ✅ Since ListView(reverse: true) shows bottom-up, reverse the list here
    return items.reversed.toList();
  }

  Widget _buildDateSeparator(String dateText, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
