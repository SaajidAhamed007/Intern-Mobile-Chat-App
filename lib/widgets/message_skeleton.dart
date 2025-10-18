import 'package:flutter/material.dart';

class MessageSkeleton extends StatefulWidget {
  const MessageSkeleton({super.key});

  @override
  State<MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          reverse: true,
          padding: const EdgeInsets.all(16),
          children: [
            // Received message skeleton
            _buildMessageSkeleton(isMe: false, theme: theme, width: 200),
            const SizedBox(height: 8),

            // Sent message skeleton
            _buildMessageSkeleton(isMe: true, theme: theme, width: 150),
            const SizedBox(height: 8),

            // Received message skeleton
            _buildMessageSkeleton(isMe: false, theme: theme, width: 180),
            const SizedBox(height: 8),

            // Received message skeleton
            _buildMessageSkeleton(isMe: false, theme: theme, width: 220),
            const SizedBox(height: 8),

            // Sent message skeleton
            _buildMessageSkeleton(isMe: true, theme: theme, width: 160),
            const SizedBox(height: 8),

            // Received message skeleton
            _buildMessageSkeleton(isMe: false, theme: theme, width: 190),
          ],
        );
      },
    );
  }

  Widget _buildMessageSkeleton({
    required bool isMe,
    required ThemeData theme,
    required double width,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary.withOpacity(_animation.value * 0.3)
              : theme.colorScheme.surfaceVariant.withOpacity(
                  _animation.value * 0.5,
                ),
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message text skeleton
            Container(
              height: 16,
              width: width * 0.8,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(_animation.value * 0.6)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(
                        _animation.value * 0.4,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),

            // Second line (shorter)
            Container(
              height: 16,
              width: width * 0.5,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(_animation.value * 0.6)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(
                        _animation.value * 0.4,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),

            // Time skeleton
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(_animation.value * 0.4)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(
                            _animation.value * 0.3,
                          ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_animation.value * 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
