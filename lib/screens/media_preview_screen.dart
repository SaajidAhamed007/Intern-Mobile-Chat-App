import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../providers/theme_provider.dart';

enum MediaType { image, video }

class MediaPreviewScreen extends StatefulWidget {
  final File mediaFile;
  final MediaType mediaType;
  final Function(String caption) onSend;

  const MediaPreviewScreen({
    super.key,
    required this.mediaFile,
    required this.mediaType,
    required this.onSend,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();
  bool _isSending = false;

  // Video player related
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == MediaType.video) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.mediaFile);
    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _handleSend() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Pause video if playing
      if (widget.mediaType == MediaType.video && _videoController != null) {
        _videoController!.pause();
      }

      // Call the onSend callback with the caption
      await widget.onSend(_captionController.text.trim());

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful send
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send ${widget.mediaType.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMediaWidget(BuildContext context) {
    if (widget.mediaType == MediaType.image) {
      return InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(widget.mediaFile, fit: BoxFit.contain),
      );
    } else {
      // Video widget
      if (!_isVideoInitialized || _videoController == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          GestureDetector(
            onTap: _toggleVideoPlayback,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          // Video progress indicator
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF25D366),
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      );
    }
  }

  String _getMediaDuration() {
    if (widget.mediaType == MediaType.video &&
        _videoController != null &&
        _isVideoInitialized) {
      final duration = _videoController!.value.duration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.isDarkMode
        ? Colors.black
        : theme.colorScheme.surface;
    final iconColor = themeProvider.isDarkMode
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: iconColor),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: widget.mediaType == MediaType.video
            ? Text(
                _getMediaDuration(),
                style: TextStyle(color: iconColor, fontSize: 16),
              )
            : null,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Media display area
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: _buildMediaWidget(context),
            ),
          ),

          // Caption and send area
          Container(
            color: backgroundColor.withValues(alpha:0.9),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  // Caption input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _captionController,
                        focusNode: _captionFocusNode,
                        style: TextStyle(color: iconColor),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(
                            color: iconColor.withValues(alpha:0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1), // WhatsApp green
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _handleSend,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
