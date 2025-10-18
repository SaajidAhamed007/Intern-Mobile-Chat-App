import 'package:flutter/material.dart';
import '../models/message_model.dart';

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
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
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
                  _buildMessageStatusIcon(message, theme),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageStatusIcon(MessageModel message, ThemeData theme) {
    // Check if message is seen (either by status or isSeen field)
    final isMessageSeen = message.status == 'seen' || message.isSeen;

    switch (message.status) {
      case 'pending':
        return Icon(
          Icons.access_time,
          size: 16,
          color: Colors.white.withOpacity(0.7),
        );
      case 'failed':
        return Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red.withOpacity(0.8),
        );
      case 'sent':
        return Icon(Icons.done, size: 16, color: Colors.white.withOpacity(0.7));
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white.withOpacity(0.7),
        );
      case 'seen':
        return Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        // Fallback to old behavior for backward compatibility
        return Icon(
          isMessageSeen ? Icons.done_all : Icons.done,
          size: 16,
          color: isMessageSeen ? Colors.blue : Colors.white.withOpacity(0.7),
        );
    }
  }
}
