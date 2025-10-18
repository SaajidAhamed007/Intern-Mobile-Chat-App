import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceDialog extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const ImageSourceDialog({Key? key, required this.onSourceSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Select Image Source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera, color: colorScheme.primary),
            title: const Text('Camera'),
            subtitle: const Text('Take a new photo'),
            onTap: () {
              Navigator.of(context).pop();
              onSourceSelected(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: colorScheme.primary),
            title: const Text('Gallery'),
            subtitle: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(context).pop();
              onSourceSelected(ImageSource.gallery);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Show the image source selection dialog
  static Future<void> show(
    BuildContext context, {
    required Function(ImageSource) onSourceSelected,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ImageSourceDialog(onSourceSelected: onSourceSelected);
      },
    );
  }
}

/// Bottom sheet alternative for image source selection
class ImageSourceBottomSheet extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const ImageSourceBottomSheet({Key? key, required this.onSourceSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Image Source',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceOption(
                context,
                icon: Icons.photo_camera,
                title: 'Camera',
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.camera);
                },
              ),
              _buildSourceOption(
                context,
                icon: Icons.photo_library,
                title: 'Gallery',
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the image source selection bottom sheet
  static Future<void> show(
    BuildContext context, {
    required Function(ImageSource) onSourceSelected,
  }) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImageSourceBottomSheet(onSourceSelected: onSourceSelected);
      },
    );
  }
}
