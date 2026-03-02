import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class TouchRippleFeedback extends StatelessWidget {
  const TouchRippleFeedback({
    super.key,
    required this.child,
    this.onLongPress,
    this.borderRadius,
  });

  final Widget child;
  final FutureOr<void> Function()? onLongPress;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = borderRadius == null
        ? child
        : ClipRRect(
            borderRadius: borderRadius!,
            child: child,
          );

    return ZoomTapAnimation(
      begin: 1.0,
      end: 0.95,
      beginDuration: const Duration(milliseconds: 20),
      endDuration: const Duration(milliseconds: 120),
      enableLongTapRepeatEvent: false,
      onTap: () {},
      onLongTap: () {
        final callback = onLongPress;
        if (callback == null) return;
        unawaited(Future<void>.sync(callback));
      },
      child: content,
    );
  }
}
