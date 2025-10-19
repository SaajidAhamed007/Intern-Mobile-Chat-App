import 'package:flutter/material.dart';

class MessageStatusIcon extends StatefulWidget {
  final String status;
  final bool isMe;
  final Color? color;

  const MessageStatusIcon({
    super.key,
    required this.status,
    required this.isMe,
    this.color,
  });

  @override
  State<MessageStatusIcon> createState() => _MessageStatusIconState();
}

class _MessageStatusIconState extends State<MessageStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Start animation when widget is created
    _animationController.forward();
  }

  @override
  void didUpdateWidget(MessageStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when status changes
    if (oldWidget.status != widget.status) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatusIcon() {
    if (!widget.isMe) return const SizedBox.shrink();

    final Color iconColor =
        widget.color ??
        (widget.isMe ? Colors.white.withOpacity(0.7) : Colors.grey);

    switch (widget.status) {
      case 'pending':
        return Icon(Icons.access_time, size: 16, color: iconColor);
      case 'sent':
        return Icon(Icons.check, size: 16, color: iconColor);
      case 'delivered':
        return Stack(
          children: [
            Icon(Icons.check, size: 16, color: iconColor),
            Positioned(
              left: 4,
              child: Icon(Icons.check, size: 16, color: iconColor),
            ),
          ],
        );
      case 'seen':
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: Colors.blue, // Blue for seen messages
            ),
            Positioned(
              left: 4,
              child: Icon(
                Icons.check,
                size: 16,
                color: Colors.blue, // Blue for seen messages
              ),
            ),
          ],
        );
      case 'failed':
        return Icon(Icons.error_outline, size: 16, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildStatusIcon(),
        );
      },
    );
  }
}

/// Utility class for creating status icons with different styles
class MessageStatusUtils {
  /// Get status text for user feedback
  static String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Sending...';
      case 'sent':
        return 'Sent';
      case 'delivered':
        return 'Delivered';
      case 'seen':
        return 'Seen';
      case 'failed':
        return 'Failed to send';
      default:
        return '';
    }
  }

  /// Get appropriate color for status
  static Color getStatusColor(String status, {bool isMe = true}) {
    switch (status) {
      case 'pending':
        return isMe ? Colors.white.withOpacity(0.7) : Colors.grey;
      case 'sent':
        return isMe ? Colors.white.withOpacity(0.7) : Colors.grey;
      case 'delivered':
        return isMe ? Colors.white.withOpacity(0.7) : Colors.grey;
      case 'seen':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return isMe ? Colors.white.withOpacity(0.7) : Colors.grey;
    }
  }

  /// Check if status should be shown (only for outgoing messages)
  static bool shouldShowStatus(String status, bool isMe) {
    return isMe && status.isNotEmpty;
  }
}
