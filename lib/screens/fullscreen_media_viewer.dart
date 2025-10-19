import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/theme_provider.dart';

enum FullscreenMediaType { image, video }

class FullscreenMediaViewer extends StatefulWidget {
  final String mediaUrl;
  final FullscreenMediaType mediaType;
  final String? heroTag;

  const FullscreenMediaViewer({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.heroTag,
  });

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  TapDownDetails? _doubleTapDetails;
  
  // Video player related
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    if (widget.mediaType == FullscreenMediaType.video) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _videoController?.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      
      // Auto-play video
      _videoController!.play();
      _isPlaying = true;

      // Listen to video completion
      _videoController!.addListener(_videoListener);
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        setState(() {
          _isPlaying = false;
        });
      }
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (widget.mediaType == FullscreenMediaType.image) {
      if (_transformationController.value != Matrix4.identity()) {
        // If zoomed in, zoom out
        _transformationController.value = Matrix4.identity();
      } else {
        // If not zoomed, zoom in at the tap location
        final position = _doubleTapDetails!.localPosition;
        const scale = 2.0;
        final x = -position.dx * (scale - 1);
        final y = -position.dy * (scale - 1);
        final zoomed = Matrix4.identity()
          ..translate(x, y)
          ..scale(scale);
        _transformationController.value = zoomed;
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildMediaWidget(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final iconColor = themeProvider.isDarkMode
        ? Colors.white
        : theme.colorScheme.onSurface;

    if (widget.mediaType == FullscreenMediaType.image) {
      final Widget imageWidget = Image.network(
        widget.mediaUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 64,
                  color: iconColor.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: iconColor.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      );

      return InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 5.0,
        onInteractionEnd: (details) {
          // Reset zoom if scaled below 1.0
          if (_transformationController.value.getMaxScaleOnAxis() < 1.0) {
            _resetZoom();
          }
        },
        child: widget.heroTag != null
            ? Hero(tag: widget.heroTag!, child: imageWidget)
            : imageWidget,
      );
    } else {
      // Video widget
      if (!_isVideoInitialized || _videoController == null) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        );
      }

      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              
              // Play/Pause button overlay
              if (!_isPlaying || _showControls)
                GestureDetector(
                  onTap: _toggleVideoPlayback,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

              // Video progress and controls
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF25D366),
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_videoController!.value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(_videoController!.value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
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
    final overlayColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.6)
        : theme.colorScheme.surface.withOpacity(0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: widget.mediaType == FullscreenMediaType.video 
            ? _toggleControls 
            : () => Navigator.of(context).pop(),
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          children: [
            // Media viewer
            Center(child: _buildMediaWidget(context)),

            // Top controls
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [overlayColor, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement save to gallery
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Save to gallery coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.download, color: iconColor, size: 24),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share functionality coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.share, color: iconColor, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom hint text
            if (_showControls && widget.mediaType == FullscreenMediaType.image)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [overlayColor, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      'Tap to close • Double tap to zoom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: iconColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}