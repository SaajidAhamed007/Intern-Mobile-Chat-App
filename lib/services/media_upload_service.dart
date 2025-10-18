import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class MediaUploadService {
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

  /// Pick video from gallery or camera
  static Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // Limit to 5 minutes
      );

      return video;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick audio file
  static Future<PlatformFile?> pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking audio: $e');
      return null;
    }
  }

  /// Upload any media file to backend server
  static Future<String?> uploadMedia(String filePath, String fieldName) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_uploadEndpoint'),
      );

      // Add file to request
      var multipartFile = await http.MultipartFile.fromPath(
        fieldName, // This matches the field name expected by your backend
        filePath,
      );

      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response
        final responseData = json.decode(response.body);
        final mediaUrl =
            responseData['imageUrl']; // Backend returns 'imageUrl' for all media types

        debugPrint('✅ Media uploaded successfully: $mediaUrl');
        return mediaUrl;
      } else {
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading media: $e');
      return null;
    }
  }

  /// Upload image
  static Future<String?> uploadImage(XFile imageFile) async {
    return await uploadMedia(imageFile.path, 'image');
  }

  /// Upload video
  static Future<String?> uploadVideo(XFile videoFile) async {
    return await uploadMedia(videoFile.path, 'video');
  }

  /// Upload audio
  static Future<String?> uploadAudio(PlatformFile audioFile) async {
    if (audioFile.path == null) return null;
    return await uploadMedia(audioFile.path!, 'audio');
  }

  /// Combined image picker and uploader
  static Future<String?> uploadImageFromSource({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? imageFile = await pickImage(source: source);
      if (imageFile == null) return null;

      return await uploadImage(imageFile);
    } catch (e) {
      debugPrint('❌ Error in uploadImageFromSource: $e');
      return null;
    }
  }

  /// Combined video picker and uploader
  static Future<String?> uploadVideoFromSource({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? videoFile = await pickVideo(source: source);
      if (videoFile == null) return null;

      return await uploadVideo(videoFile);
    } catch (e) {
      debugPrint('❌ Error in uploadVideoFromSource: $e');
      return null;
    }
  }

  /// Combined audio picker and uploader
  static Future<String?> uploadAudioFromPicker() async {
    try {
      final PlatformFile? audioFile = await pickAudio();
      if (audioFile == null) return null;

      return await uploadAudio(audioFile);
    } catch (e) {
      debugPrint('❌ Error in uploadAudioFromPicker: $e');
      return null;
    }
  }

  /// Get file size in a human readable format
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Media source options for images and videos
  static List<Map<String, dynamic>> get mediaSourceOptions => [
    {'title': 'Camera', 'icon': 'camera', 'source': ImageSource.camera},
    {'title': 'Gallery', 'icon': 'gallery', 'source': ImageSource.gallery},
  ];
}
