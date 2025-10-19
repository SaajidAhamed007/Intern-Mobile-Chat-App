import 'package:flutter/material.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../screens/fullscreen_media_viewer.dart';
import 'message_status_icon.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Animation<double>? animation;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final messageWidget = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageContent(context, message, isMe, theme),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(status: message.status, isMe: isMe),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    // Apply animation only if provided
    if (animation != null) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation!, curve: Curves.easeOutBack),
            ),
        child: FadeTransition(opacity: animation!, child: messageWidget),
      );
    }

    return messageWidget;
  }

  Widget _buildMessageContent(
    BuildContext context,
    MessageModel message,
    bool isMe,
    ThemeData theme,
  ) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage(context, message, isMe, theme);
      case 'video':
        return _buildVideoMessage(context, message, isMe, theme);
      case 'audio':
        return _buildAudioMessage(context, message, isMe, theme);
      case 'document':
        return _buildDocumentMessage(context, message, isMe, theme);
      case 'text':
      default:
        return _buildTextMessage(message, isMe, theme);
    }
  }

  Widget _buildTextMessage(MessageModel message, bool isMe, ThemeData theme) {
    return Text(
      message.message,
      style: TextStyle(
        color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageMessage(
    BuildContext context,
    MessageModel message,
    bool isMe,
    ThemeData theme,
  ) {
    final heroTag = 'image_${message.messageId}';
    final isLocalFile =
        message.message.startsWith('/') || message.message.contains('\\');

    // Parse image URL and caption from message
    String imageUrl = message.message;
    String? caption;

    if (message.message.contains('\n\n')) {
      final parts = message.message.split('\n\n');
      imageUrl = parts[0];
      caption = parts.length > 1 ? parts[1] : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Only open fullscreen for network images (not local pending images)
            if (!isLocalFile) {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FullscreenMediaViewer(
                      mediaUrl: imageUrl,
                      mediaType: FullscreenMediaType.image,
                      heroTag: heroTag,
                    );
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                  maxHeight: 300,
                ),
                child: Stack(
                  children: [
                    // Image widget - local file or network
                    isLocalFile
                        ? Image.file(
                            File(imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: isMe
                                          ? Colors.white70
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not found',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isMe
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: isMe
                                          ? Colors.white70
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image failed to load',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to retry',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white54
                                            : theme.colorScheme.onSurfaceVariant
                                                  .withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                    // Upload status overlay for pending messages
                    if (message.status == 'pending' ||
                        message.status == 'failed')
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (message.status == 'pending') ...[
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sending...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else if (message.status == 'failed') ...[
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Failed to send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to retry',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Display caption if available
        if (caption != null && caption.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption.trim(),
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMessage(
    BuildContext context,
    MessageModel message,
    bool isMe,
    ThemeData theme,
  ) {
    final heroTag = 'video_${message.messageId}';
    final isLocalFile =
        message.message.startsWith('/') || message.message.contains('\\');

    // Parse video URL and caption from message
    String videoUrl = message.message;
    String? caption;

    if (message.message.contains('\n\n')) {
      final parts = message.message.split('\n\n');
      videoUrl = parts[0];
      caption = parts.length > 1 ? parts[1] : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Only open fullscreen for network videos (not local pending videos)
            if (!isLocalFile) {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FullscreenMediaViewer(
                      mediaUrl: videoUrl,
                      mediaType: FullscreenMediaType.video,
                      heroTag: heroTag,
                    );
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }
          },
          child: Hero(
            tag: heroTag,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.videocam,
                          size: 48,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),

                  // Play button overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  // Video duration overlay (if available)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upload status overlay for pending messages
                  if (message.status == 'pending' || message.status == 'failed')
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (message.status == 'pending') ...[
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sending...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else if (message.status == 'failed') ...[
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to send',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to retry',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Display caption if available
        if (caption != null && caption.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption.trim(),
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioMessage(
    BuildContext context,
    MessageModel message,
    bool isMe,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            color: isMe ? Colors.white : theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Audio message',
            style: TextStyle(
              color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.play_arrow,
            color: isMe ? Colors.white : theme.colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentMessage(
    BuildContext context,
    MessageModel message,
    bool isMe,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description,
            color: isMe ? Colors.white : theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Document',
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
