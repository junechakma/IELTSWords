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
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr).round();
    final plain = Image.asset(
      mascot.asset,
      width: size,
      height: size,
      fit: fit,
      cacheWidth: px,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );

    Widget img = sticker && px > 0 ? _Sticker(asset: mascot.asset, size: size, dpr: dpr, fit: fit, fallback: plain) : plain;

    if (idle) {
      img = img
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -size * 0.04, duration: 1600.ms, curve: Curves.easeInOut)
          .scaleXY(begin: 1, end: 1.02, duration: 1600.ms, curve: Curves.easeInOut);
    }
    // Own layer: the idle bob and page swipes don't repaint the card around it.
    return RepaintBoundary(child: img);
  }
}

/// Mascot + white outline, drawn once into a bitmap and reused. Running the
/// dilate filter live costs an offscreen layer on every frame, which made
/// card swipes stutter; a cached bitmap is just a texture draw.
class _Sticker extends StatelessWidget {
  const _Sticker({required this.asset, required this.size, required this.dpr, required this.fit, required this.fallback});
  final String asset;
  final double size, dpr;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final r = (size * 0.035).clamp(2.0, 6.0);
    final future = StickerCache.get(asset, (size * dpr).round(), (r * dpr).round());
    return FutureBuilder<ui.Image>(
      future: future,
      initialData: StickerCache.ready(asset, (size * dpr).round(), (r * dpr).round()),
      builder: (context, snap) {
        final image = snap.data;
        if (image == null) return fallback;
        // The bitmap has the outline margin baked in, so it spills past [size]
        // by r on each side — same as the old live filter did.
        return SizedBox.square(
          dimension: size,
          child: OverflowBox(
            maxWidth: size + 2 * r,
            maxHeight: size + 2 * r,
            child: RawImage(image: image, width: size + 2 * r, height: size + 2 * r, fit: fit, filterQuality: FilterQuality.medium),
          ),
        );
      },
    );
  }
}

/// Pre-rendered sticker bitmaps, keyed by asset + pixel size.
abstract final class StickerCache {
  static final _futures = <String, Future<ui.Image>>{};
  static final _ready = <String, ui.Image>{};

  static String _key(String asset, int px, int pad) => '$asset@$px+$pad';

  static ui.Image? ready(String asset, int px, int pad) => _ready[_key(asset, px, pad)];

  /// Most bitmaps kept at once (each is a few MB at card size).
  static const _max = 24;

  static Future<ui.Image> get(String asset, int px, int pad) {
    final key = _key(asset, px, pad);
    return _futures[key] ??= _render(asset, px, pad).then((img) {
      // Drop the oldest; widgets still showing it keep their own reference.
      if (_futures.length > _max) {
        final old = _futures.keys.first;
        _futures.remove(old);
        _ready.remove(old);
      }
      return _ready[key] = img;
    });
  }

  static Future<ui.Image> _render(String asset, int px, int pad) async {
    // Decode so the longer side is [px].
    final buffer = await ui.ImmutableBuffer.fromAsset(asset);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final wide = descriptor.width >= descriptor.height;
    final codec = await descriptor.instantiateCodec(targetWidth: wide ? px : null, targetHeight: wide ? null : px);
    final src = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();

    // Square canvas like BoxFit.contain in a [px] box, plus the outline margin.
    final side = px + 2 * pad;
    final at = Offset(pad + (px - src.width) / 2, pad + (px - src.height) / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.saveLayer(
      null,
      Paint()
        ..imageFilter = ui.ImageFilter.dilate(radiusX: pad.toDouble(), radiusY: pad.toDouble())
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
    canvas.drawImage(src, at, Paint());
    canvas.restore();
    canvas.drawImage(src, at, Paint()..filterQuality = FilterQuality.medium);
    final out = await recorder.endRecording().toImage(side, side);
    src.dispose();
    return out;
  }
}
