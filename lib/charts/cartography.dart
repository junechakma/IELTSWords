import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// One illustrated map style shared by the Task 1 maps, the listening map and
/// the small direction pictures: warm land, white roads with a soft casing,
/// 2.5D buildings, clustered tree canopies, rippled water and white label
/// pills. Everything is plain Canvas drawing, so it scales and highlights
/// like the other charts.
abstract final class Carto {
  // ---- palette ----
  static const land = Color(0xFFF2EEE1);
  static const landEdge = Color(0xFFE4DECB);
  static const grass = Color(0xFFDDE8BF);
  static const roadFill = Colors.white;
  static const roadCasing = Color(0xFFD8CFBD);
  static const roadDash = Color(0xFFE6D9AE);
  static const pathFill = Color(0xFFEBDFC6);
  static const pathDash = Color(0xFFC4AD84);
  static const buildingTop = Color(0xFFE6D8C4);
  static const buildingSide = Color(0xFFC6B097);
  static const shopTop = Color(0xFFF5DCAE);
  static const shopSide = Color(0xFFD9B57A);
  static const awning = Color(0xFFE0934A);
  static const houseRoof = Color(0xFFE9B9A2);
  static const houseSide = Color(0xFFC99079);
  static const lot = Color(0xFFDEDAD2);
  static const canopy = Color(0xFF9DBB63);
  static const canopyShade = Color(0xFF7F9E48);
  static const canopyLight = Color(0xFFB9D184);
  static const waterFill = Color(0xFFA9D2EA);
  static const waterEdge = Color(0xFF8CC0DE);
  static const ripple = Color(0xFFCBE5F4);
  static const fieldFill = Color(0xFFEFE4B6);
  static const furrow = Color(0xFFE2D398);
  static const timber = Color(0xFF9C7B58);
  static const pin = AppColors.sunflower;

  static final _shadow = Paint()
    ..color = const Color(0x22000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

  /// Stable pseudo-random numbers from a rect, so trees don't jump around
  /// between frames.
  static math.Random _rnd(Rect r) => math.Random((r.left * 7919 + r.top * 104729 + r.width * 31 + r.height * 17).round());

  // ---- ground ----

  static void ground(Canvas c, RRect box) {
    c.drawRRect(box, Paint()..color = land);
    // A faint dot texture reads as "terrain" without adding noise.
    c.save();
    c.clipRRect(box);
    final dot = Paint()..color = landEdge.withValues(alpha: .55);
    for (var y = box.top + 6; y < box.bottom; y += 11) {
      for (var x = box.left + ((y ~/ 11).isEven ? 4 : 9.5); x < box.right; x += 11) {
        c.drawCircle(Offset(x, y), .7, dot);
      }
    }
    c.restore();
  }

  // ---- roads & paths ----

  /// Road along [path] with a casing, white surface and a dashed centre line.
  static void road(Canvas c, Path path, double width) {
    c.drawPath(
        path,
        Paint()
          ..color = roadCasing
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 3
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round);
    c.drawPath(
        path,
        Paint()
          ..color = roadFill
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round);
    if (width >= 9) {
      _dashed(
          c,
          path,
          Paint()
            ..color = roadDash
            ..strokeWidth = math.max(1.2, width * .1)
            ..style = PaintingStyle.stroke,
          dash: width * .7,
          gap: width * .6);
    }
  }

  /// Footpath: a sandy strip with a dotted centre.
  static void footpath(Canvas c, Path path, double width) {
    c.drawPath(
        path,
        Paint()
          ..color = pathFill
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    _dashed(
        c,
        path,
        Paint()
          ..color = pathDash
          ..strokeWidth = math.max(1.2, width * .22)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dash: math.max(2, width * .35),
        gap: math.max(3, width * .55));
  }

  /// Centre line of a road stored as a rectangle (long side = direction).
  static (Path, double) bandOf(Rect r) {
    final horizontal = r.width >= r.height;
    final p = horizontal ? (Path()..moveTo(r.left, r.center.dy)..lineTo(r.right, r.center.dy)) : (Path()..moveTo(r.center.dx, r.top)..lineTo(r.center.dx, r.bottom));
    return (p, horizontal ? r.height : r.width);
  }

  static void _dashed(Canvas c, Path path, Paint paint, {required double dash, required double gap}) {
    for (final m in path.computeMetrics()) {
      for (var d = gap / 2; d < m.length; d += dash + gap) {
        c.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      }
    }
  }

  // ---- buildings ----

  /// A 2.5D block: a darker side strip under a lighter roof, with a soft shadow.
  static void building(Canvas c, Rect r, {Color top = buildingTop, Color side = buildingSide, double? depth, double radius = 4}) {
    final d = depth ?? (math.min(r.width, r.height) * .14).clamp(2.0, 6.0);
    final roof = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - d);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(1.5, 2)), Radius.circular(radius)), _shadow);
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..color = side);
    c.drawRRect(RRect.fromRectAndRadius(roof, Radius.circular(radius)), Paint()..color = top);
    // Roof ridge highlight.
    c.drawRRect(
        RRect.fromRectAndRadius(roof.deflate(math.min(3, roof.shortestSide * .12)), Radius.circular(math.max(1, radius - 1.5))),
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  /// Shop: warm block with a striped awning along its front.
  static void shops(Canvas c, Rect r) {
    building(c, r, top: shopTop, side: shopSide);
    final d = (math.min(r.width, r.height) * .14).clamp(2.0, 6.0);
    final h = math.min(7.0, r.height * .22);
    final strip = Rect.fromLTWH(r.left, r.bottom - d - h, r.width, h);
    c.save();
    c.clipRRect(RRect.fromRectAndCorners(strip, bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3)));
    final n = math.max(3, (r.width / 7).round());
    for (var i = 0; i < n; i++) {
      c.drawRect(Rect.fromLTWH(r.left + r.width * i / n, strip.top, r.width / n + .5, h), Paint()..color = i.isEven ? awning : Colors.white);
    }
    c.restore();
  }

  /// Housing: rows of little houses with a gap between them.
  static void housing(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = grass.withValues(alpha: .6));
    const cell = 15.0;
    final n = math.max(1, (r.width / cell).floor());
    final m = math.max(1, (r.height / cell).floor());
    final cw = r.width / n, ch = r.height / m;
    for (var k = 0; k < m; k++) {
      for (var i = 0; i < n; i++) {
        final h = Rect.fromLTWH(r.left + cw * i, r.top + ch * k, cw, ch).deflate(math.min(cw, ch) * .16);
        building(c, h, top: houseRoof, side: houseSide, radius: 2);
        // Ridge line down the middle of the pitched roof.
        c.drawLine(Offset(h.left + h.width * .2, h.top + (h.height - 2) / 2), Offset(h.right - h.width * .2, h.top + (h.height - 2) / 2),
            Paint()
              ..color = houseSide.withValues(alpha: .7)
              ..strokeWidth = 1);
      }
    }
  }

  // ---- open ground ----

  /// Clustered tree canopies filling [r].
  static void trees(Canvas c, Rect r, {bool oval = false}) {
    final rnd = _rnd(r);
    c.save();
    c.clipPath(oval ? (Path()..addOval(r.inflate(2))) : (Path()..addRRect(RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(10)))));
    final s = (math.min(r.width, r.height) / 2.4).clamp(5.0, 11.0);
    final pts = <Offset>[];
    for (var y = r.top + s * .9; y < r.bottom - s * .3; y += s * 1.25) {
      for (var x = r.left + s * .9 + ((pts.length.isEven) ? 0 : s * .5); x < r.right - s * .3; x += s * 1.35) {
        pts.add(Offset(x + (rnd.nextDouble() - .5) * s * .5, y + (rnd.nextDouble() - .5) * s * .5));
      }
    }
    if (pts.isEmpty) pts.add(r.center);
    for (final p in pts) {
      c.drawCircle(p + Offset(s * .25, s * .3), s, _shadow);
    }
    for (final p in pts) {
      final rr = s * (.85 + rnd.nextDouble() * .3);
      c.drawCircle(p, rr, Paint()..color = canopyShade);
      c.drawCircle(p - Offset(rr * .15, rr * .18), rr * .82, Paint()..color = canopy);
      c.drawCircle(p - Offset(rr * .35, rr * .38), rr * .32, Paint()..color = canopyLight);
    }
    c.restore();
  }

  /// A single tree (for small pictures).
  static void tree(Canvas c, Offset p, double s) {
    c.drawCircle(p + Offset(s * .25, s * .3), s, _shadow);
    c.drawCircle(p, s, Paint()..color = canopyShade);
    c.drawCircle(p - Offset(s * .15, s * .18), s * .82, Paint()..color = canopy);
    c.drawCircle(p - Offset(s * .35, s * .38), s * .32, Paint()..color = canopyLight);
  }

  /// Park: soft lawn with a few trees along the edge.
  static void park(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = grass);
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(7)),
        Paint()
          ..color = canopy.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final s = (math.min(r.width, r.height) * .09).clamp(3.5, 7.0);
    for (final f in const [Offset(.14, .18), Offset(.86, .2), Offset(.12, .82), Offset(.88, .84)]) {
      tree(c, Offset(r.left + r.width * f.dx, r.top + r.height * f.dy), s);
    }
  }

  /// Walled garden: lawn with a hedge border and flower beds.
  static void garden(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = grass);
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(5)),
        Paint()
          ..color = canopyShade
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final rnd = _rnd(r);
    const petals = [Color(0xFFE9A0A8), Color(0xFFF3C75B), Colors.white, Color(0xFFB9A7E8)];
    for (var i = 0; i < (r.width * r.height / 90).clamp(6, 40); i++) {
      final p = Offset(r.left + 7 + rnd.nextDouble() * (r.width - 14), r.top + 7 + rnd.nextDouble() * (r.height - 14));
      c.drawCircle(p, 1.8, Paint()..color = petals[i % petals.length]);
    }
  }

  /// Farmland: pale field with diagonal furrows.
  static void field(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    c.drawRRect(rr, Paint()..color = fieldFill);
    c.save();
    c.clipRRect(rr);
    final f = Paint()
      ..color = furrow
      ..strokeWidth = 2;
    for (var x = r.left - r.height; x < r.right; x += 8) {
      c.drawLine(Offset(x, r.bottom), Offset(x + r.height, r.top), f);
    }
    c.restore();
  }

  /// Lake, river or sea, with a darker shore and a few ripples.
  static void water(Canvas c, Rect r, {bool oval = false}) {
    final shape = oval ? (Path()..addOval(r)) : (Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(math.min(12, r.shortestSide / 2)))));
    c.drawPath(shape, Paint()..color = waterFill);
    c.drawPath(
        shape,
        Paint()
          ..color = waterEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    c.save();
    c.clipPath(shape);
    final rnd = _rnd(r);
    final w = Paint()
      ..color = ripple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < (r.width * r.height / 700).clamp(2, 10); i++) {
      final p = Offset(r.left + 8 + rnd.nextDouble() * (r.width - 16), r.top + 6 + rnd.nextDouble() * (r.height - 12));
      c.drawPath(Path()..moveTo(p.dx - 5, p.dy)..quadraticBezierTo(p.dx - 2.5, p.dy - 2.5, p.dx, p.dy)..quadraticBezierTo(p.dx + 2.5, p.dy + 2.5, p.dx + 5, p.dy), w);
    }
    c.restore();
  }

  /// Car park: grey lot, white bays and a "P" sign.
  static void carpark(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(5));
    c.drawRRect(rr, Paint()..color = lot);
    c.save();
    c.clipRRect(rr);
    final bay = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2;
    final rows = r.height > 34 ? 2 : 1;
    for (var k = 0; k < rows; k++) {
      final y0 = r.top + r.height * k / rows + 3, y1 = r.top + r.height * (k + 1) / rows - 3;
      for (var x = r.left + 6; x < r.right - 3; x += 7) {
        c.drawLine(Offset(x, k == 0 ? y0 : y0 + (y1 - y0) * .45), Offset(x, k == 0 ? y0 + (y1 - y0) * .55 : y1), bay);
      }
    }
    c.restore();
    final s = math.min(14.0, r.shortestSide * .5);
    final sign = Rect.fromLTWH(r.right - s - 3, r.top + 3, s, s);
    c.drawRRect(RRect.fromRectAndRadius(sign, Radius.circular(s * .25)), Paint()..color = const Color(0xFF4E7FC4));
    _text(c, 'P', sign.center, size: s * .72, color: Colors.white, weight: FontWeight.w700);
  }

  /// Bridge / jetty deck with planks.
  static void deck(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(1, 1.5)), const Radius.circular(2)), _shadow);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = timber);
    final plank = Paint()
      ..color = const Color(0xFFB9976F)
      ..strokeWidth = 1;
    final along = r.height > r.width;
    for (var t = 3.0; t < (along ? r.height : r.width); t += 3.5) {
      if (along) {
        c.drawLine(Offset(r.left + 1, r.top + t), Offset(r.right - 1, r.top + t), plank);
      } else {
        c.drawLine(Offset(r.left + t, r.top + 1), Offset(r.left + t, r.bottom - 1), plank);
      }
    }
  }

  // ---- markers ----

  /// Map pin (teardrop) whose tip sits on [tip].
  static void pinAt(Canvas c, Offset tip, double s, {Color color = pin, String? text}) {
    final head = tip - Offset(0, s * 1.35);
    final p = Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(head.dx - s * .9, head.dy + s * .75, head.dx - s, head.dy)
      ..arcToPoint(Offset(head.dx + s, head.dy), radius: Radius.circular(s))
      ..quadraticBezierTo(head.dx + s * .9, head.dy + s * .75, tip.dx, tip.dy)
      ..close();
    c.drawPath(p.shift(const Offset(1, 1.5)), _shadow);
    c.drawPath(p, Paint()..color = color);
    c.drawPath(
        p,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, s * .14));
    if (text != null) {
      _text(c, text, head, size: s * 1.05, color: AppColors.ink, weight: FontWeight.w700);
    } else {
      c.drawCircle(head, s * .36, Paint()..color = Colors.white);
    }
  }

  /// "You" marker: dark dot with a soft halo.
  static void you(Canvas c, Offset p, double s) {
    c.drawCircle(p, s * 1.9, Paint()..color = AppColors.ink.withValues(alpha: .12));
    c.drawCircle(p, s + 1.8, Paint()..color = Colors.white);
    c.drawCircle(p, s, Paint()..color = AppColors.ink);
  }

  /// Compass rose with "N".
  static void compass(Canvas c, Offset o, double r) {
    c.drawCircle(o, r + 3, Paint()..color = Colors.white.withValues(alpha: .85));
    final north = Path()
      ..moveTo(o.dx, o.dy - r)
      ..lineTo(o.dx + r * .38, o.dy)
      ..lineTo(o.dx - r * .38, o.dy)
      ..close();
    final south = Path()
      ..moveTo(o.dx, o.dy + r)
      ..lineTo(o.dx + r * .38, o.dy)
      ..lineTo(o.dx - r * .38, o.dy)
      ..close();
    c.drawPath(north, Paint()..color = AppColors.ink);
    c.drawPath(south, Paint()..color = AppColors.ink.withValues(alpha: .25));
    _text(c, 'N', o - Offset(0, r + 7.5), size: 8.5, color: AppColors.ink, weight: FontWeight.w700);
  }

  // ---- highlight & labels ----

  /// Yellow glow + ink outline around the selected feature.
  static void highlight(Canvas c, Rect r, {bool oval = false}) {
    final box = r.inflate(3.5);
    final shape = oval ? (Path()..addOval(box)) : (Path()..addRRect(RRect.fromRectAndRadius(box, const Radius.circular(7))));
    c.drawPath(
        shape,
        Paint()
          ..color = AppColors.sunflower.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7);
    c.drawPath(
        shape,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
  }

  /// Fades everything except [keep] (spotlight on the selected part).
  static void spotlight(Canvas c, Rect bounds, Rect keep, {Color veil = const Color(0x8CF7F4EC)}) {
    final p = Path.combine(
      PathOperation.difference,
      Path()..addRect(bounds),
      Path()..addRRect(RRect.fromRectAndRadius(keep.inflate(5), const Radius.circular(8))),
    );
    c.drawPath(p, Paint()..color = veil);
  }

  static final _labelCache = <String, TextPainter>{};

  static TextPainter _tp(String s, double size, Color color, FontWeight weight, double maxWidth) {
    final key = '$s|$size|${color.toARGB32()}|${weight.value}|${maxWidth.round()}';
    return _labelCache[key] ??= (TextPainter(
      text: TextSpan(text: s, style: GoogleFonts.outfit(fontSize: size, color: color, fontWeight: weight, height: 1.1)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth));
  }

  static void _text(Canvas c, String s, Offset center, {double size = 10, Color color = AppColors.ink, FontWeight weight = FontWeight.w500, double maxWidth = 200}) {
    final tp = _tp(s, size, color, weight, maxWidth);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// White label pill for [feature]. Sits on the feature when it fits,
  /// otherwise just below / above / beside it; skips spots already [taken]
  /// and stays inside [bounds]. Returns the pill rect.
  static Rect label(Canvas c, String s, Rect feature, Rect bounds, List<Rect> taken, {double size = 9.5, bool bold = false, bool onTop = false}) {
    final weight = bold ? FontWeight.w700 : FontWeight.w600;
    var tp = _tp(s, size, AppColors.ink, weight, math.min(96, bounds.width * .42));
    // A narrow but tall feature: wrap the name onto two lines inside it.
    if (!onTop && s.contains(' ') && tp.width + 14 > feature.width && feature.width > 44) {
      final wrapped = _tp(s, size, AppColors.ink, weight, feature.width - 14);
      if (wrapped.height + 9 <= feature.height) tp = wrapped;
    }
    final w = tp.width + 10, h = tp.height + 5;
    final inside = onTop || (feature.width >= w + 4 && feature.height >= h + 4);
    final candidates = [
      if (inside) feature.center,
      Offset(feature.center.dx, feature.bottom + h / 2 + 2),
      Offset(feature.center.dx, feature.top - h / 2 - 2),
      Offset(feature.right + w / 2 + 2, feature.center.dy),
      Offset(feature.left - w / 2 - 2, feature.center.dy),
      feature.center,
    ];
    Rect? pick;
    for (final cand in candidates) {
      var r = Rect.fromCenter(center: cand, width: w, height: h);
      r = r.shift(Offset(
        r.left < bounds.left + 2 ? bounds.left + 2 - r.left : (r.right > bounds.right - 2 ? bounds.right - 2 - r.right : 0),
        r.top < bounds.top + 2 ? bounds.top + 2 - r.top : (r.bottom > bounds.bottom - 2 ? bounds.bottom - 2 - r.bottom : 0),
      ));
      if (!taken.any((t) => t.overlaps(r))) {
        pick = r;
        break;
      }
    }
    pick ??= Rect.fromCenter(center: feature.center, width: w, height: h);
    taken.add(pick);
    c.drawRRect(RRect.fromRectAndRadius(pick.shift(const Offset(0, 1)), Radius.circular(h / 2)), _shadow);
    c.drawRRect(RRect.fromRectAndRadius(pick, Radius.circular(h / 2)), Paint()..color = Colors.white.withValues(alpha: .94));
    tp.paint(c, pick.center - Offset(tp.width / 2, tp.height / 2));
    return pick;
  }

  /// Draws one Task 1 / listening feature by its type name.
  static void feature(Canvas c, String type, Rect r, {bool oval = false}) {
    switch (type) {
      case 'building':
        building(c, r);
      case 'shops' || 'shop':
        shops(c, r);
      case 'housing' || 'houses':
        housing(c, r);
      case 'trees' || 'woodland' || 'forest':
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = grass.withValues(alpha: .7));
        trees(c, r, oval: oval);
      case 'park':
        park(c, r);
      case 'garden':
        garden(c, r);
      case 'field' || 'farmland':
        field(c, r);
      case 'water' || 'pond' || 'lake' || 'sea' || 'river':
        water(c, r, oval: oval);
      case 'carpark':
        carpark(c, r);
      case 'bridge' || 'jetty' || 'pier':
        deck(c, r);
      case 'road':
        final (p, w) = bandOf(r);
        road(c, p, w);
      case 'path':
        final (p, w) = bandOf(r);
        footpath(c, p, w);
      default:
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = landEdge);
    }
  }
}
