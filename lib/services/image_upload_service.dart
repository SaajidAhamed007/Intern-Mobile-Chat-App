import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'unified_upload_service.dart';

class ImageUploadService {
  /// Upload profile picture (combines picking and uploading) using unified service
  static Future<String?> uploadProfilePicture({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      UploadResult result;

      if (source == ImageSource.camera) {
        result = await UnifiedUploadService.uploadImageFromCamera();
      } else {
        result = await UnifiedUploadService.uploadImageFromGallery();
      }

      if (result.success && result.url != null) {
        return result.url;
      } else {
        debugPrint('❌ Profile picture upload failed: ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in uploadProfilePicture: $e');
      return null;
    }
  }

  /// Legacy methods for backward compatibility - these now use the unified service

  /// Pick image from gallery or camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    return await UnifiedUploadService.pickMedia(
      type: MediaType.image,
      source: source,
    ).then((mediaFile) {
      if (mediaFile != null) {
        return XFile(mediaFile.path);
      }
      return null;
    });
  }

  /// Upload image to server
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final mediaFile = MediaFile.fromXFile(imageFile, MediaType.image);
      final result = await UnifiedUploadService.uploadMedia(
        mediaFile: mediaFile,
      );

      return result.success ? result.url : null;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Show image source selection dialog options
  static List<Map<String, dynamic>> get imageSourceOptions => [
    {'title': 'Camera', 'icon': 'camera', 'source': ImageSource.camera},
    {'title': 'Gallery', 'icon': 'gallery', 'source': ImageSource.gallery},
  ];
}
