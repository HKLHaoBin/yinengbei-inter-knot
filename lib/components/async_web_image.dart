import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class AsyncWebImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool gaplessPlayback;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const AsyncWebImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.cacheWidth,
    this.cacheHeight,
    this.gaplessPlayback = false,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  @override
  State<AsyncWebImage> createState() => _AsyncWebImageState();
}

class _AsyncWebImageState extends State<AsyncWebImage> {
  bool _isLoaded = false;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Only pre-decode on Web. On other platforms, Image.network is fine/optimized differently.
    if (kIsWeb) {
      _preDecodeImage();
    } else {
      _isLoaded = true;
    }
  }

  @override
  void didUpdateWidget(covariant AsyncWebImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      if (kIsWeb) {
        setState(() {
          _isLoaded = false;
          _hasError = false;
          _error = null;
        });
        _preDecodeImage();
      }
    }
  }

  void _preDecodeImage() {
    final imageElement = html.ImageElement();
    imageElement.src = widget.url;

    // decode() is a browser API that decodes the image off the main thread (mostly)
    imageElement.decode().then((_) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }).catchError((e) {
      debugPrint("AsyncWebImage decode error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = e;
          // We set loaded to true to let Flutter try (and potentially fail/show error)
          // or we can just show error builder directly if we trust the browser error.
          // Let's rely on Image.network to handle the final display or error,
          // but if decode failed, Image.network might also fail.
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, just return Image.network directly (or wrapped in what we need)
    // But since we set _isLoaded = true in initState for non-web, we can share the structure.

    if (_hasError && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error ?? 'Decode error');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoaded
          ? Image.network(
              widget.url,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              alignment: widget.alignment,
              filterQuality: widget.filterQuality,
              cacheWidth: widget.cacheWidth,
              cacheHeight: widget.cacheHeight,
              gaplessPlayback: widget.gaplessPlayback,
              errorBuilder: widget.errorBuilder != null
                  ? (context, error, stackTrace) =>
                      widget.errorBuilder!(context, error)
                  : null,
            )
          : SizedBox(
              width: widget.width,
              height: widget.height,
              child: widget.placeholderBuilder?.call(context) ??
                  Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
            ),
    );
  }
}
