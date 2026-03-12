import 'dart:async';

import 'package:flutter/material.dart';

enum ZzzDesktopActionButtonTone {
  primary,
  danger,
}

class ZzzDesktopActionButton extends StatefulWidget {
  const ZzzDesktopActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.width,
    required this.onTap,
    this.iconOnly = false,
    this.enableClickFlash = false,
    this.enabled = true,
    this.isLoading = false,
    this.tone = ZzzDesktopActionButtonTone.primary,
  });

  final IconData icon;
  final String label;
  final double width;
  final FutureOr<void> Function()? onTap;
  final bool iconOnly;
  final bool enableClickFlash;
  final bool enabled;
  final bool isLoading;
  final ZzzDesktopActionButtonTone tone;

  @override
  State<ZzzDesktopActionButton> createState() => _ZzzDesktopActionButtonState();
}

class _ZzzDesktopActionButtonState extends State<ZzzDesktopActionButton>
    with SingleTickerProviderStateMixin {
  static const _primaryHoverColor = Color(0xffD9FA00);
  static const _outerFill = Color(0xff313131);
  static const _specialSauceCurve = Cubic(0.25, 0.1, 0.75, 1);
  static const _buttonHeight = 48.0;
  static const _buttonBorderWidth = 2.0;
  static const _buttonPadding = 4.0;
  static const _contentInset = _buttonBorderWidth + _buttonPadding;
  static const _iconOuterSize = 44.0;
  static const _iconCombinedInset = 8.0;

  bool _isHovering = false;
  bool _isFlashing = false;
  bool _isFlashOff = false;
  int _flashToken = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseSpreadAnimation;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 670),
    );

    _pulseSpreadAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -2.0, end: 2.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.0, end: 7.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 7.0, end: 1.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: -2.0),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: _specialSauceCurve,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ZzzDesktopActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInteractive && (_isHovering || _isFlashing || _isFlashOff)) {
      _isHovering = false;
      _isFlashing = false;
      _isFlashOff = false;
    }
    _syncPulseState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setHovering(bool value) {
    if (!_isInteractive) {
      if (_isHovering) {
        setState(() => _isHovering = false);
      }
      return;
    }
    if (_isHovering == value) return;
    setState(() => _isHovering = value);
    _syncPulseState();
  }

  void _syncPulseState() {
    final shouldPulse = _isInteractive && (_isHovering || _isFlashing);
    if (shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController
          ..reset()
          ..repeat();
      }
      return;
    }

    _pulseController
      ..stop()
      ..reset();
  }

  Future<void> _playClickFlash() async {
    if (!widget.enableClickFlash || !_isInteractive) return;

    final token = ++_flashToken;
    setState(() {
      _isFlashing = true;
      _isFlashOff = true;
    });
    _syncPulseState();

    Future<void> step(int delayMs, VoidCallback cb) async {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (!mounted || token != _flashToken) return;
      setState(cb);
      _syncPulseState();
    }

    await step(50, () {
      _isFlashOff = false;
    });
    await step(50, () {
      _isFlashOff = true;
    });
    await step(50, () {
      _isFlashOff = false;
    });
    await step(50, () {
      _isFlashing = false;
      _isFlashOff = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(999));

    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final showPulse = _isInteractive && (_isHovering || _isFlashing);
          final showActive = showPulse && !_isFlashOff;
          final pulseSpread = showPulse ? _pulseSpreadAnimation.value : 0.0;
          final borderColor = !_isInteractive
              ? const Color(0xff1A1A1A)
              : showActive
                  ? _primaryHoverColor
                  : Colors.black;
          final outerFillColor = !_isInteractive
              ? const Color(0xff262626)
              : showActive
                  ? _primaryHoverColor
                  : _outerFill;
          final contentFillColor = !_isInteractive
              ? const Color(0xff101010)
              : showActive
                  ? _primaryHoverColor
                  : Colors.black;
          final labelColor = !_isInteractive
              ? const Color(0xff727272)
              : showActive
                  ? Colors.black
                  : const Color(0xffefefef);
          final baseAccentColor =
              widget.tone == ZzzDesktopActionButtonTone.danger
                  ? const Color(0xffFF5A5A)
                  : _primaryHoverColor;
          final accentBackgroundColor = widget.isLoading
              ? Colors.transparent
              : !_isInteractive
                  ? const Color(0xff4A4A4A)
                  : showActive
                      ? Colors.black
                      : baseAccentColor;
          final accentForeground = widget.isLoading
              ? baseAccentColor
              : !_isInteractive
                  ? const Color(0xff1A1A1A)
                  : showActive
                      ? _primaryHoverColor
                      : Colors.black;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (showPulse)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryHoverColor,
                            blurRadius: 0,
                            spreadRadius: pulseSpread,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  borderRadius: borderRadius,
                  onTap: _isInteractive
                      ? () async {
                          await _playClickFlash();
                          await Future.sync(() => widget.onTap?.call());
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    curve: Curves.easeOut,
                    width: widget.width,
                    height: _buttonHeight,
                    decoration: BoxDecoration(
                      color: outerFillColor,
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: borderColor,
                        width: _buttonBorderWidth,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.all(
                              widget.iconOnly ? _buttonPadding : _contentInset,
                            ),
                            child: ClipRRect(
                              borderRadius: borderRadius,
                              child: widget.iconOnly
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ColoredBox(color: contentFillColor),
                                        if (!showActive && _isInteractive)
                                          const CustomPaint(
                                            painter: _ZzzButtonPatternPainter(),
                                          ),
                                        Center(
                                          child: widget.isLoading
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: labelColor,
                                                  ),
                                                )
                                              : Icon(
                                                  widget.icon,
                                                  color: labelColor,
                                                  size: 22,
                                                ),
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ColoredBox(color: contentFillColor),
                                        if (!showActive && _isInteractive)
                                          const CustomPaint(
                                            painter: _ZzzButtonPatternPainter(),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 40,
                                            right: 16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              widget.label,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: labelColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                fontStyle: FontStyle.italic,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        if (!widget.iconOnly)
                          Positioned(
                            left: _buttonBorderWidth,
                            top: _buttonBorderWidth,
                            child: AnimatedContainer(
                              duration: Duration.zero,
                              curve: Curves.easeOut,
                              width: _iconOuterSize,
                              height: _iconOuterSize,
                              padding: const EdgeInsets.all(_iconCombinedInset),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(_iconOuterSize / 2),
                                border: Border.all(
                                  color: !_isInteractive
                                      ? const Color(0xff262626)
                                      : showActive
                                          ? _primaryHoverColor
                                          : _outerFill,
                                  width: 4,
                                ),
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentBackgroundColor,
                                ),
                                child: Center(
                                  child: widget.isLoading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: accentForeground,
                                          ),
                                        )
                                      : Icon(
                                          widget.icon,
                                          color: accentForeground,
                                          size: 20,
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
            ],
          );
        },
      ),
    );
  }
}

class _ZzzButtonPatternPainter extends CustomPainter {
  const _ZzzButtonPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const blockSize = 4.0;
    final blackPaint = Paint()..color = Colors.black;
    final darkPaint = Paint()..color = const Color(0xff121212);

    for (double y = 0; y < size.height; y += blockSize) {
      for (double x = 0; x < size.width; x += blockSize) {
        final isDark =
            ((x / blockSize).floor() + (y / blockSize).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, blockSize, blockSize),
          isDark ? darkPaint : blackPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
