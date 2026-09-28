import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'mascot.dart';

/// A mascot with an optional white die-cut outline (sticker look) and an idle bob.
class MascotImage extends StatelessWidget {
  const MascotImage(
    this.mascot, {
    super.key,
    this.size = 80,
    this.sticker = false,
    this.idle = false,
    this.fit = BoxFit.contain,
  });

  final Mascot mascot;
  final double size;
  final bool sticker;
  final bool idle;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // Decode at display size, not the source size, so a screen full of
    // mascots stays light on memory (matters on budget phones).
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Image image() => Image.asset(
          mascot.asset,
          width: size,
          height: size,
          fit: fit,
          cacheWidth: px,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );

    Widget img = image();

    if (sticker) {
      // One dilated white silhouette behind the mascot = die-cut outline.
      final r = (size * 0.035).clamp(2.0, 6.0);
      img = Stack(
        clipBehavior: Clip.none,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.dilate(radiusX: r, radiusY: r),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: image(),
            ),
          ),
          img,
        ],
      );
    }

    if (idle) {
      img = img
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -size * 0.04, duration: 1600.ms, curve: Curves.easeInOut)
          .scaleXY(begin: 1, end: 1.02, duration: 1600.ms, curve: Curves.easeInOut);
    }
    return img;
  }
}
