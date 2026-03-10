import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inter_knot/components/click_region.dart';

class CloseSvgButton extends StatelessWidget {
  const CloseSvgButton({
    super.key,
    required this.onTap,
    this.width = 46,
    this.height = 30,
  });

  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClickRegion(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(
          'assets/images/close-btn.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
