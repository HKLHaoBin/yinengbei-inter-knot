import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class AdaptiveSmoothScroll extends StatelessWidget {
  final ScrollController controller;
  final Widget Function(BuildContext context, ScrollPhysics physics) builder;
  final double scrollSpeed;

  const AdaptiveSmoothScroll({
    super.key,
    required this.controller,
    required this.builder,
    this.scrollSpeed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (GetPlatform.isDesktop) {
      return SmoothScroll(
        controller: controller,
        scrollSpeed: scrollSpeed,
        child: builder(context, const NeverScrollableScrollPhysics()),
      );
    }
    return builder(context, const AlwaysScrollableScrollPhysics());
  }
}

class SmoothScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final ScrollPhysics? physics;
  final int durationMs;
  final double scrollSpeed;

  const SmoothScroll({
    super.key,
    required this.child,
    required this.controller,
    this.physics,
    this.durationMs = 200,
    this.scrollSpeed = 1.0,
  });

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll>
    with SingleTickerProviderStateMixin {
  double _targetPosition = 0;
  late Ticker _ticker;
  // Use a physics-like simulation: position += (target - position) * friction
  // A value around 0.1-0.2 provides a nice browser-like "ease-out" feel.
  // Higher = snappier, Lower = floatier.
  static const double _friction = 0.3;
  // Threshold to stop the animation
  static const double _threshold = 0.5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients) {
        _targetPosition = widget.controller.offset;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (!widget.controller.hasClients) {
      _ticker.stop();
      return;
    }

    final double currentPos = widget.controller.offset;
    final double diff = _targetPosition - currentPos;

    // If close enough, snap and stop
    if (diff.abs() < _threshold) {
      widget.controller.jumpTo(_targetPosition);
      _ticker.stop();
      return;
    }

    // Move towards target
    // We can use a simple proportional step for exponential smoothing
    final double move = diff * _friction;

    // Ensure we move at least a tiny bit if friction is small but diff is large enough
    // (though the logic above handles it)

    double newPos = currentPos + move;

    // Safety clamp (though target is already clamped, intermediate steps should be fine)
    // But jumpTo might complain if out of bounds? Usually ScrollController handles overscroll if physics allows,
    // but here we are driving it manually.
    final double maxPos = widget.controller.position.maxScrollExtent;
    final double minPos = widget.controller.position.minScrollExtent;

    if (newPos < minPos) newPos = minPos;
    if (newPos > maxPos) newPos = maxPos;

    widget.controller.jumpTo(newPos);
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy == 0) return;
      if (!widget.controller.hasClients) return;

      final double currentPos = widget.controller.offset;

      // If we are currently stopped, or if the user dragged the scrollbar elsewhere,
      // reset target to current to avoid jumping back.
      // We check if the ticker is running. If not, sync.
      if (!_ticker.isActive) {
        _targetPosition = currentPos;
      } else {
        // If animation is active, but we are very far (e.g. user dragged scrollbar while animating),
        // sync target.
        if ((_targetPosition - currentPos).abs() > 2000) {
          // Large threshold
          _targetPosition = currentPos;
        }
      }

      final double maxPos = widget.controller.position.maxScrollExtent;
      final double minPos = widget.controller.position.minScrollExtent;

      // Accumulate delta
      // Windows standard scroll delta is ~100.
      final double delta = event.scrollDelta.dy * widget.scrollSpeed;

      _targetPosition += delta;

      // Clamp target immediately
      if (_targetPosition < minPos) _targetPosition = minPos;
      if (_targetPosition > maxPos) _targetPosition = maxPos;

      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handleScroll,
      child: widget.child,
    );
  }
}
