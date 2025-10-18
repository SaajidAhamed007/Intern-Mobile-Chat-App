import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static const String _baseUrl =
      'http://10.166.122.43:3000'; // Your backend server URL
  static const String _uploadEndpoint = '/upload';

  /// Pick image from gallery or camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress to reduce file size
        maxWidth: 800, // Limit width to 800px
        maxHeight: 800, // Limit height to 800px
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload image to your backend server
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_uploadEndpoint'),
      );

      // Add file to request
      var multipartFile = await http.MultipartFile.fromPath(
        'image', // This matches the field name expected by your backend
        imageFile.path,
      );

      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'];

        debugPrint('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload profile picture (combines picking and uploading)
  static Future<String?> uploadProfilePicture({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image
      final XFile? imageFile = await pickImage(source: source);
      if (imageFile == null) {
        return null; // User cancelled or no image selected
      }

      // Upload image
      final String? imageUrl = await uploadImage(imageFile);
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Error in uploadProfilePicture: $e');
      return null;
    }
  }

  /// Show image source selection dialog options
  static List<Map<String, dynamic>> get imageSourceOptions => [
    {'title': 'Camera', 'icon': 'camera', 'source': ImageSource.camera},
    {'title': 'Gallery', 'icon': 'gallery', 'source': ImageSource.gallery},
  ];
}
