import 'dart:math' as math;

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
    Widget img = Image.asset(mascot.asset, width: size, height: size, fit: fit, filterQuality: FilterQuality.medium);

    if (sticker) {
      final r = (size * 0.035).clamp(2.0, 6.0);
      final outline = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.asset(mascot.asset, width: size, height: size, fit: fit),
      );
      img = Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 12; i++)
            Transform.translate(
              offset: Offset(math.cos(i * math.pi / 6) * r, math.sin(i * math.pi / 6) * r),
              child: outline,
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
