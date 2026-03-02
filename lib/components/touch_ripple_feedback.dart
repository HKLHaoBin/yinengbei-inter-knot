import 'dart:async';

import 'package:flutter/material.dart';

class TouchRippleFeedback extends StatelessWidget {
  const TouchRippleFeedback({
    super.key,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.color = const Color(0x30FFFFFF),
  });

  final Widget child;
  final FutureOr<void> Function()? onLongPress;
  final BorderRadius? borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    return Material(
      type: MaterialType.transparency,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: InkResponse(
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        splashFactory: InkSplash.splashFactory,
        splashColor: color,
        highlightColor: Colors.transparent,
        onTap: () {},
        onLongPress: () {
          final callback = onLongPress;
          if (callback != null) {
            unawaited(Future<void>.sync(callback));
          }
        },
        child: child,
      ),
    );
  }
}
