import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/unified_upload_service.dart';

class MediaSelectionBottomSheet extends StatelessWidget {
  final Function(MediaType mediaType, ImageSource? source) onMediaSelected;

  const MediaSelectionBottomSheet({super.key, required this.onMediaSelected});

  static Future<void> show(
    BuildContext context, {
    required Function(MediaType mediaType, ImageSource? source) onMediaSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MediaSelectionBottomSheet(onMediaSelected: onMediaSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            'Send Media',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 24),

          // Media options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Image options
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaOption(
                        context,
                        icon: Icons.camera_alt,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          onMediaSelected(MediaType.image, ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        context,
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        subtitle: 'Choose photo',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          onMediaSelected(MediaType.image, ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Video options
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaOption(
                        context,
                        icon: Icons.videocam,
                        title: 'Video',
                        subtitle: 'Record video',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          onMediaSelected(MediaType.video, ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        context,
                        icon: Icons.video_library,
                        title: 'Video Gallery',
                        subtitle: 'Choose video',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          onMediaSelected(MediaType.video, ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMediaOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
