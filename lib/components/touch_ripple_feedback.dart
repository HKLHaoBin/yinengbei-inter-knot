import 'dart:math' as math;

import 'package:flutter/material.dart';

class TouchRippleFeedback extends StatefulWidget {
  const TouchRippleFeedback({
    super.key,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.color = const Color(0x40FFFFFF),
  });

  final Widget child;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color color;

  @override
  State<TouchRippleFeedback> createState() => _TouchRippleFeedbackState();
}

class _TouchRippleFeedbackState extends State<TouchRippleFeedback>
    with TickerProviderStateMixin {
  late final AnimationController _expandController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );

  Offset _origin = Offset.zero;
  double _maxRadius = 0;
  bool _visible = false;

  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  double _computeMaxRadius(Size size, Offset origin) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    var maxDistance = 0.0;
    for (final corner in corners) {
      final distance = (corner - origin).distance;
      maxDistance = math.max(maxDistance, distance);
    }
    return maxDistance;
  }

  void _startRipple(Offset localPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final size = renderObject.size;
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    setState(() {
      _visible = true;
      _origin = localPosition;
      _maxRadius = _computeMaxRadius(size, localPosition);
    });
    _fadeController.value = 1;
    _expandController.forward(from: 0);
  }

  void _endRipple() {
    if (!_visible) return;
    _fadeController.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _startRipple(details.localPosition),
      onTapUp: (_) => _endRipple(),
      onTapCancel: _endRipple,
      onLongPressStart: (details) {
        _startRipple(details.localPosition);
        widget.onLongPress?.call();
      },
      onLongPressEnd: (_) => _endRipple(),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  [_expandController, _fadeController],
                ),
                builder: (context, _) {
                  if (!_visible) return const SizedBox.shrink();

                  final t = Curves.easeOutCubic.transform(_expandController.value);
                  final radius = _maxRadius * t;
                  final opacity =
                      (1 - 0.25 * _expandController.value) * _fadeController.value;
                  final baseAlpha = widget.color.a;

                  return CustomPaint(
                    painter: _RipplePainter(
                      center: _origin,
                      radius: radius,
                      color: widget.color.withValues(
                        alpha: (baseAlpha * opacity).clamp(0.0, 1.0),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!radius.isFinite || radius <= 0) return;
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}
