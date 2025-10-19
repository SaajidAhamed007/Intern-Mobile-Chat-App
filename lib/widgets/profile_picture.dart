import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final VoidCallback? onEditTap;
  final bool isUploading;

  const ProfilePicture({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 50,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
    this.onTap,
    this.showEditIcon = false,
    this.onEditTap,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: borderColor ?? colorScheme.primary,
                      width: borderWidth,
                    )
                  : null,
            ),
            child: ClipOval(child: _buildProfileImage(context)),
          ),
          if (isUploading)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha:0.6),
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          if (showEditIcon && !isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: size * 0.25,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to avatar if image fails to load
          return _buildAvatarFallback(context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildAvatarFallback(context);
  }

  Widget _buildAvatarFallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate initials from name
    String initials = '';
    if (name != null && name!.isNotEmpty) {
      final nameParts = name!.trim().split(' ');
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0].toUpperCase();
        if (nameParts.length > 1) {
          initials += nameParts[1][0].toUpperCase();
        }
      }
    }

    // Generate avatar colors based on name
    final colors = _getAvatarColors(colorScheme);
    final colorIndex = (name?.hashCode ?? 0).abs() % colors.length;
    final backgroundColor = colors[colorIndex]['background']!;
    final textColor = colors[colorIndex]['text']!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: textColor,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(Icons.person, size: size * 0.6, color: textColor),
      ),
    );
  }

  List<Map<String, Color>> _getAvatarColors(ColorScheme colorScheme) {
    return [
      {'background': Colors.red.shade300, 'text': Colors.white},
      {'background': Colors.blue.shade300, 'text': Colors.white},
      {'background': Colors.green.shade300, 'text': Colors.white},
      {'background': Colors.orange.shade300, 'text': Colors.white},
      {'background': Colors.purple.shade300, 'text': Colors.white},
      {'background': Colors.teal.shade300, 'text': Colors.white},
      {'background': Colors.indigo.shade300, 'text': Colors.white},
      {'background': Colors.pink.shade300, 'text': Colors.white},
    ];
  }
}

/// Small profile picture for lists and chats
class SmallProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;

  const SmallProfilePicture({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePicture(imageUrl: imageUrl, name: name, size: size);
  }
}

/// Large profile picture for profile screens
class LargeProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final VoidCallback? onEditTap;
  final bool showEditIcon;
  final bool isUploading;

  const LargeProfilePicture({
    super.key,
    this.imageUrl,
    this.name,
    this.onEditTap,
    this.showEditIcon = false,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePicture(
      imageUrl: imageUrl,
      name: name,
      size: 120,
      showBorder: true,
      borderWidth: 3,
      showEditIcon: showEditIcon,
      onEditTap: onEditTap,
      isUploading: isUploading,
    );
  }
}
