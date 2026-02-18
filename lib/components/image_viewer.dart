import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inter_knot/helpers/download_helper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => ImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final List<PhotoViewController> _photoControllers;
  late final List<AnimationController> _zoomControllers;
  late final List<Animation<double>> _zoomAnimations;
  final Map<int, Size> _imageSizes = <int, Size>{};
  final List<ImageStream> _imageStreams = <ImageStream>[];
  final List<ImageStreamListener> _imageStreamListeners =
      <ImageStreamListener>[];
  late int _currentIndex;
  Offset _dragOffset = Offset.zero;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _photoControllers = List<PhotoViewController>.generate(
      widget.imageUrls.length,
      (_) => PhotoViewController(),
    );
    _zoomControllers = List<AnimationController>.generate(
      widget.imageUrls.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
      ),
    );
    _zoomAnimations = List<Animation<double>>.generate(
      widget.imageUrls.length,
      (_) => const AlwaysStoppedAnimation<double>(1),
    );
    _resolveImageSizes();
  }

  @override
  void dispose() {
    for (var i = 0; i < _imageStreams.length; i += 1) {
      _imageStreams[i].removeListener(_imageStreamListeners[i]);
    }
    for (final controller in _zoomControllers) {
      controller.dispose();
    }
    for (final controller in _photoControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _resolveImageSizes() {
    for (var i = 0; i < widget.imageUrls.length; i += 1) {
      final provider = _buildImageProvider(widget.imageUrls[i]);
      final stream = provider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener((info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _imageSizes[i] = size;
        });
      });
      stream.addListener(listener);
      _imageStreams.add(stream);
      _imageStreamListeners.add(listener);
    }
  }

  bool _isGifUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    final path = (uri?.path ?? trimmed).toLowerCase();
    return path.endsWith('.gif');
  }

  ImageProvider _buildImageProvider(String url) {
    if (_isGifUrl(url)) {
      return NetworkImage(url);
    }
    return CachedNetworkImageProvider(url);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.dy.abs() > 100) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _toggleChrome() {
    setState(() {
      _showChrome = !_showChrome;
    });
  }

  double _calculateContainedScale(Size viewport, Size imageSize) {
    return math.min(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
  }

  double _calculateCoveredScale(Size viewport, Size imageSize) {
    return math.max(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
  }

  ({double minScale, double maxScale})? _scaleBoundsForCurrent() {
    final imageSize = _imageSizes[_currentIndex];
    if (imageSize == null) {
      return null;
    }
    final viewport = MediaQuery.of(context).size;
    final minScale = _calculateContainedScale(viewport, imageSize);
    final maxScale = _calculateCoveredScale(viewport, imageSize) * 2;
    return (minScale: minScale, maxScale: maxScale);
  }

  void _animateScaleTo(double targetScale) {
    if (_photoControllers.isEmpty) {
      return;
    }
    final controller = _photoControllers[_currentIndex];
    final currentScale = controller.scale ?? targetScale;
    final zoomController = _zoomControllers[_currentIndex];
    zoomController.stop();
    zoomController.reset();
    _zoomAnimations[_currentIndex] = Tween<double>(
      begin: currentScale,
      end: targetScale,
    ).animate(
      CurvedAnimation(parent: zoomController, curve: Curves.easeOutCubic),
    )..addListener(() {
        controller.scale = _zoomAnimations[_currentIndex].value;
      });
    zoomController.forward();
  }

  void _zoomBy(double factor) {
    final bounds = _scaleBoundsForCurrent();
    if (bounds == null) {
      return;
    }
    final controller = _photoControllers[_currentIndex];
    final currentScale = (controller.scale ?? bounds.minScale)
        .clamp(bounds.minScale, bounds.maxScale);
    final nextScale =
        (currentScale * factor).clamp(bounds.minScale, bounds.maxScale);
    _animateScaleTo(nextScale);
  }

  void _resetScale() {
    final bounds = _scaleBoundsForCurrent();
    if (bounds == null) {
      return;
    }
    _photoControllers[_currentIndex].rotation = 0;
    _animateScaleTo(bounds.minScale);
  }

  void _rotateBy(double radians) {
    final controller = _photoControllers[_currentIndex];
    controller.rotation = controller.rotation + radians;
  }

  ButtonStyle _toolButtonStyle() {
    const highlightColor = Color(0xffD7FF00);
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused)) {
          return highlightColor;
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return highlightColor.withValues(alpha: 0.2);
        }
        if (states.contains(WidgetState.hovered)) {
          return highlightColor.withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: label,
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      visualDensity: VisualDensity.compact,
      style: _toolButtonStyle(),
    );
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final bounds = _scaleBoundsForCurrent();
    if (bounds == null || _photoControllers.isEmpty) {
      return;
    }
    final zoomIn = event.scrollDelta.dy < 0;
    final factor = zoomIn ? 1.1 : 0.9;
    _zoomBy(factor);
  }

  @override
  Widget build(BuildContext context) {
    final double dragDistance = _dragOffset.dy.abs();
    final double opacity = (1 - (dragDistance / 300)).clamp(0.0, 1.0);
    final double chromeOpacity = _showChrome ? opacity : 0.0;
    final isWide = MediaQuery.of(context).size.width > 640;
    final total = widget.imageUrls.length;

    void closeViewer() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                closeViewer();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: opacity * 0.2),
                    ),
                  ),
                ),
                Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _handlePointerScroll(event);
                    }
                  },
                  child: GestureDetector(
                    onTap: _toggleChrome,
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    child: Transform.translate(
                      offset: _dragOffset,
                      child: PhotoViewGallery.builder(
                        scrollPhysics: const BouncingScrollPhysics(),
                        builder: (BuildContext context, int index) {
                          final url = widget.imageUrls[index];
                          final heroTag = widget.heroTagPrefix != null
                              ? '${widget.heroTagPrefix}-$index'
                              : url;

                          return PhotoViewGalleryPageOptions(
                            imageProvider: _buildImageProvider(url),
                            initialScale: PhotoViewComputedScale.contained,
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                            filterQuality: FilterQuality.medium,
                            heroAttributes:
                                PhotoViewHeroAttributes(tag: heroTag),
                            controller: _photoControllers[index],
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white),
                              );
                            },
                          );
                        },
                        itemCount: widget.imageUrls.length,
                        loadingBuilder: (context, event) => Center(
                          child: SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              value: event == null
                                  ? 0
                                  : event.cumulativeBytesLoaded /
                                      (event.expectedTotalBytes ?? 1),
                            ),
                          ),
                        ),
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.transparent),
                        pageController: _pageController,
                        onPageChanged: _onPageChanged,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: chromeOpacity == 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: chromeOpacity,
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.black54,
                          child: Row(
                            children: [
                              const SizedBox(width: 48),
                              Expanded(
                                child: Text(
                                  '${_currentIndex + 1} / $total',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 24),
                                onPressed: closeViewer,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                    width: 48, height: 48),
                                visualDensity: VisualDensity.compact,
                                style: _toolButtonStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: chromeOpacity == 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: chromeOpacity,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.black54,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildToolButton(
                                icon: Icons.file_download,
                                label: '下载',
                                onPressed: () {
                                  DownloadHelper.downloadImage(
                                      widget.imageUrls[_currentIndex]);
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildToolButton(
                                icon: Icons.zoom_out,
                                label: '缩小',
                                onPressed: () => _zoomBy(0.9),
                              ),
                              const SizedBox(width: 10),
                              _buildToolButton(
                                icon: Icons.zoom_in,
                                label: '放大',
                                onPressed: () => _zoomBy(1.1),
                              ),
                              const SizedBox(width: 10),
                              _buildToolButton(
                                icon: Icons.refresh,
                                label: '复位',
                                onPressed: _resetScale,
                              ),
                              const SizedBox(width: 10),
                              _buildToolButton(
                                icon: Icons.rotate_right,
                                label: '反转',
                                onPressed: () => _rotateBy(math.pi / 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isWide && total > 1)
                  Positioned.fill(
                    left: 8,
                    child: IgnorePointer(
                      ignoring: chromeOpacity == 0.0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: chromeOpacity,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white),
                            onPressed: () {
                              final target =
                                  (_currentIndex - 1).clamp(0, total - 1);
                              _pageController.animateToPage(
                                target,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isWide && total > 1)
                  Positioned.fill(
                    right: 8,
                    child: IgnorePointer(
                      ignoring: chromeOpacity == 0.0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: chromeOpacity,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white),
                            onPressed: () {
                              final target =
                                  (_currentIndex + 1).clamp(0, total - 1);
                              _pageController.animateToPage(
                                target,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
