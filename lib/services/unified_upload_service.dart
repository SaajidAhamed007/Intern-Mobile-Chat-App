import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Enum for different media types
enum MediaType { image, video, audio, document }

/// Upload configuration class
class UploadConfig {
  final String baseUrl;
  final String endpoint;
  final String fieldName;
  final Duration timeout;
  final Map<String, String>? headers;

  const UploadConfig({
    required this.baseUrl,
    this.endpoint = '/upload',
    this.fieldName = 'file',
    this.timeout = const Duration(minutes: 5),
    this.headers,
  });

  /// Default configuration for chat app
  static const UploadConfig defaultConfig = UploadConfig(
    baseUrl: 'https://hasa-chat-backend-services.onrender.com',
    endpoint: '/upload',
    fieldName: 'file',
  );
}

/// Media picker configuration
class MediaPickerConfig {
  final int? imageQuality;
  final double? maxWidth;
  final double? maxHeight;
  final Duration? maxVideoDuration;
  final List<String>? allowedExtensions;
  final bool allowMultiple;

  const MediaPickerConfig({
    this.imageQuality = 70,
    this.maxWidth = 800,
    this.maxHeight = 800,
    this.maxVideoDuration = const Duration(minutes: 5),
    this.allowedExtensions,
    this.allowMultiple = false,
  });

  /// Default configuration for images
  static const MediaPickerConfig imageConfig = MediaPickerConfig(
    imageQuality: 70,
    maxWidth: 800,
    maxHeight: 800,
  );

  /// Default configuration for videos
  static const MediaPickerConfig videoConfig = MediaPickerConfig(
    maxVideoDuration: Duration(minutes: 5),
  );

  /// Default configuration for audio
  static const MediaPickerConfig audioConfig = MediaPickerConfig();

  /// Default configuration for documents
  static const MediaPickerConfig documentConfig = MediaPickerConfig(
    allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
  );
}

/// Upload result class
class UploadResult {
  final bool success;
  final String? url;
  final String? error;
  final Map<String, dynamic>? metadata;

  const UploadResult({
    required this.success,
    this.url,
    this.error,
    this.metadata,
  });

  factory UploadResult.success(String url, {Map<String, dynamic>? metadata}) {
    return UploadResult(success: true, url: url, metadata: metadata);
  }

  factory UploadResult.failure(String error) {
    return UploadResult(success: false, error: error);
  }
}

/// Media file wrapper
class MediaFile {
  final String path;
  final String name;
  final int size;
  final MediaType type;

  const MediaFile({
    required this.path,
    required this.name,
    required this.size,
    required this.type,
  });

  factory MediaFile.fromXFile(XFile file, MediaType type) {
    return MediaFile(
      path: file.path,
      name: file.name,
      size: 0, // Size will be calculated later
      type: type,
    );
  }

  factory MediaFile.fromPlatformFile(PlatformFile file, MediaType type) {
    return MediaFile(
      path: file.path ?? '',
      name: file.name,
      size: file.size,
      type: type,
    );
  }
}

/// Unified Upload Service - The main service class
class UnifiedUploadService {
  static const UploadConfig _defaultConfig = UploadConfig.defaultConfig;

  /// Check and request permissions based on source and media type
  static Future<bool> _checkPermissions(
    ImageSource? source,
    MediaType type,
  ) async {
    if (!Platform.isAndroid) return true;

    List<Permission> permissions = [];

    if (source == ImageSource.camera) {
      permissions.add(Permission.camera);
      if (type == MediaType.video) {
        permissions.add(Permission.microphone);
      }
    } else {
      // Gallery or file picker
      permissions.addAll([
        Permission.storage,
        Permission.photos,
        if (type == MediaType.video) Permission.videos,
      ]);
    }

    for (Permission permission in permissions) {
      final status = await permission.request();
      if (status.isGranted) return true;
    }

    return false;
  }

  /// Pick media based on type and source
  static Future<MediaFile?> pickMedia({
    required MediaType type,
    ImageSource? source,
    MediaPickerConfig? config,
  }) async {
    try {
      config ??= _getDefaultConfigForType(type);

      debugPrint('📱 Picking ${type.name} from ${source ?? 'file picker'}');

      // Check permissions
      final hasPermission = await _checkPermissions(source, type);
      if (!hasPermission) {
        debugPrint('❌ Permission denied for ${type.name}');
        return null;
      }

      switch (type) {
        case MediaType.image:
          return await _pickImage(source!, config);
        case MediaType.video:
          return await _pickVideo(source!, config);
        case MediaType.audio:
          return await _pickAudio(config);
        case MediaType.document:
          return await _pickDocument(config);
      }
    } catch (e) {
      debugPrint('❌ Error picking ${type.name}: $e');
      return null;
    }
  }

  /// Upload media file to server
  static Future<UploadResult> uploadMedia({
    required MediaFile mediaFile,
    UploadConfig? config,
    Function(double)? onProgress,
  }) async {
    config ??= _defaultConfig;

    try {
      debugPrint('🔄 Starting upload for: ${mediaFile.name}');
      debugPrint('🌐 Upload URL: ${config.baseUrl}${config.endpoint}');

      // Validate file
      final file = File(mediaFile.path);
      if (!await file.exists()) {
        return UploadResult.failure('File does not exist: ${mediaFile.path}');
      }

      final fileSize = await file.length();
      debugPrint('📄 File size: ${_formatFileSize(fileSize)}');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${config.baseUrl}${config.endpoint}'),
      );

      // Add headers if provided
      if (config.headers != null) {
        request.headers.addAll(config.headers!);
      }

      // Add file to request
      var multipartFile = await http.MultipartFile.fromPath(
        config.fieldName,
        mediaFile.path,
      );

      request.files.add(multipartFile);
      debugPrint('📤 Sending request with file: ${multipartFile.filename}');

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        config.timeout,
        onTimeout: () {
          throw Exception(
            'Upload timeout after ${config!.timeout.inMinutes} minutes',
          );
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Try different URL field names for backward compatibility
          String? mediaUrl =
              responseData['url']?.toString() ??
              responseData['mediaUrl']?.toString() ??
              responseData['imageUrl']?.toString() ??
              responseData['videoUrl']?.toString() ??
              responseData['audioUrl']?.toString();

          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            debugPrint('✅ Media uploaded successfully: $mediaUrl');

            // Extract additional metadata from server response
            final metadata = {
              'originalName': mediaFile.name,
              'size': fileSize,
              'type': mediaFile.type.name,
              'publicId': responseData['publicId']?.toString(),
              'format': responseData['format']?.toString(),
              'resourceType': responseData['resourceType']?.toString(),
              'serverBytes': responseData['bytes']?.toString(),
              'duration': responseData['duration']
                  ?.toString(), // For videos/audio
              'width': responseData['width']?.toString(), // For images/videos
              'height': responseData['height']?.toString(), // For images/videos
            };

            return UploadResult.success(mediaUrl, metadata: metadata);
          } else {
            return UploadResult.failure('No media URL in response');
          }
        } catch (e) {
          return UploadResult.failure('Error parsing response: $e');
        }
      } else {
        debugPrint(
          '❌ Upload failed: ${response.statusCode} - ${response.body}',
        );
        return UploadResult.failure(
          'Upload failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error uploading media: $e');
      return UploadResult.failure('Upload error: $e');
    }
  }

  /// Complete workflow: Pick and upload media
  static Future<UploadResult> pickAndUpload({
    required MediaType type,
    ImageSource? source,
    MediaPickerConfig? pickerConfig,
    UploadConfig? uploadConfig,
    Function(double)? onProgress,
  }) async {
    try {
      // Pick media
      final mediaFile = await pickMedia(
        type: type,
        source: source,
        config: pickerConfig,
      );

      if (mediaFile == null) {
        return UploadResult.failure('No file selected or permission denied');
      }

      // Upload media
      return await uploadMedia(
        mediaFile: mediaFile,
        config: uploadConfig,
        onProgress: onProgress,
      );
    } catch (e) {
      return UploadResult.failure('Pick and upload error: $e');
    }
  }

  // Private helper methods

  static Future<MediaFile?> _pickImage(
    ImageSource source,
    MediaPickerConfig config,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: config.imageQuality,
      maxWidth: config.maxWidth,
      maxHeight: config.maxHeight,
    );

    return image != null ? MediaFile.fromXFile(image, MediaType.image) : null;
  }

  static Future<MediaFile?> _pickVideo(
    ImageSource source,
    MediaPickerConfig config,
  ) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: source,
      maxDuration: config.maxVideoDuration,
    );

    return video != null ? MediaFile.fromXFile(video, MediaType.video) : null;
  }

  static Future<MediaFile?> _pickAudio(MediaPickerConfig config) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: config.allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      return MediaFile.fromPlatformFile(result.files.first, MediaType.audio);
    }
    return null;
  }

  static Future<MediaFile?> _pickDocument(MediaPickerConfig config) async {
    final result = await FilePicker.platform.pickFiles(
      type: config.allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: config.allowedExtensions,
      allowMultiple: config.allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      return MediaFile.fromPlatformFile(result.files.first, MediaType.document);
    }
    return null;
  }

  static MediaPickerConfig _getDefaultConfigForType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return MediaPickerConfig.imageConfig;
      case MediaType.video:
        return MediaPickerConfig.videoConfig;
      case MediaType.audio:
        return MediaPickerConfig.audioConfig;
      case MediaType.document:
        return MediaPickerConfig.documentConfig;
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Utility methods for easy access

  /// Upload image from camera
  static Future<UploadResult> uploadImageFromCamera({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.image,
      source: ImageSource.camera,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }

  /// Upload image from gallery
  static Future<UploadResult> uploadImageFromGallery({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.image,
      source: ImageSource.gallery,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }

  /// Upload video from camera
  static Future<UploadResult> uploadVideoFromCamera({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.video,
      source: ImageSource.camera,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }

  /// Upload video from gallery
  static Future<UploadResult> uploadVideoFromGallery({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.video,
      source: ImageSource.gallery,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }

  /// Upload audio file
  static Future<UploadResult> uploadAudio({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.audio,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }

  /// Upload document
  static Future<UploadResult> uploadDocument({
    MediaPickerConfig? config,
    UploadConfig? uploadConfig,
  }) {
    return pickAndUpload(
      type: MediaType.document,
      pickerConfig: config,
      uploadConfig: uploadConfig,
    );
  }
}
