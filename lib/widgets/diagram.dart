import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// A small picture for a map / direction word, in one consistent style:
/// grey landmark boxes, a yellow target, beige roads, and your route as a
/// rust line with an arrow. Places and exam traps use Phosphor icons.
/// Unknown keys fall back to a neutral pin, so new content never breaks.
class DiagramIcon extends StatelessWidget {
  const DiagramIcon(this.diagram, {super.key, this.size = 90});
  final String diagram;
  final double size;

  static const _icons = <String, IconData>{
    'place-car': PhosphorIconsRegular.car,
    'place-desk': PhosphorIconsRegular.desk,
    'place-door': PhosphorIconsRegular.door,
    'place-entrance': PhosphorIconsRegular.doorOpen,
    'place-info': PhosphorIconsRegular.info,
    'place-lift': PhosphorIconsRegular.elevator,
    'place-picnic': PhosphorIconsRegular.picnicTable,
    'place-pier': PhosphorIconsRegular.anchor,
    'place-room': PhosphorIconsRegular.door,
    'place-lobby': PhosphorIconsRegular.couch,
    'place-cloakroom': PhosphorIconsRegular.coatHanger,
    'place-storage': PhosphorIconsRegular.package,
    'place-staffroom': PhosphorIconsRegular.coffee,
    'place-reception': PhosphorIconsRegular.bellSimple,
    'place-stairs': PhosphorIconsRegular.stairs,
    'place-ticket': PhosphorIconsRegular.ticket,
    'place-toilet': PhosphorIconsRegular.toilet,
    'place-trees': PhosphorIconsRegular.tree,
    'place-water': PhosphorIconsRegular.waves,
    'trap-correction': PhosphorIconsRegular.arrowUUpLeft,
    'trap-left-right': PhosphorIconsRegular.arrowsLeftRight,
    'trap-distance': PhosphorIconsRegular.ruler,
    'trap-before-vs-past': PhosphorIconsRegular.arrowsHorizontal,
    'trap-not-first': PhosphorIconsRegular.numberCircleTwo,
    'trap-opposite-vs-next': PhosphorIconsRegular.swap,
    'trap-north-of-vs-side': PhosphorIconsRegular.compass,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[diagram];
    if (icon != null) {
      final trap = diagram.startsWith('trap-');
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: trap ? const Color(0xFFFBEAE5) : const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(size * .28)),
        child: Icon(icon, size: size * .52, color: trap ? AppColors.rust : AppColors.ink),
      );
    }
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _ScenePainter(diagram)));
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.k);
  final String k;

  static const _road = Color(0xFFE3DAC9);
  static const _block = Color(0xFFD9D2C6);
  static const _target = AppColors.sunflower;
  static const _route = AppColors.rust;
  static const _ink = AppColors.ink;

  late Canvas c;
  late double u; // 1 unit = 1% of the tile

  Offset p(double x, double y) => Offset(x * u, y * u);

  // ---- primitives ----
  void bg() => c.drawRRect(RRect.fromRectAndRadius(Offset.zero & Size(100 * u, 100 * u), Radius.circular(24 * u)), Paint()..color = const Color(0xFFF7F3EC));

  void road(Offset a, Offset b, {double w = 14}) => c.drawLine(
      a,
      b,
      Paint()
        ..color = _road
        ..strokeWidth = w * u
        ..strokeCap = StrokeCap.butt);

  void block(double l, double t, double r, double b, {Color color = _block, bool front = false}) {
    final rect = Rect.fromLTRB(l * u, t * u, r * u, b * u);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4 * u)), Paint()..color = color);
    c.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4 * u)),
        Paint()
          ..color = _ink.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * u);
  }

  void target(Offset o, {double r = 7}) {
    c.drawCircle(o, r * u, Paint()..color = _target);
    c.drawCircle(
        o,
        r * u,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * u);
  }

  void walker(Offset o) {
    c.drawCircle(o, 5 * u, Paint()..color = _ink);
    c.drawCircle(
        o,
        8.5 * u,
        Paint()
          ..color = _ink.withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * u);
  }

  void room(double l, double t, double r, double b) => c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(l * u, t * u, r * u, b * u), Radius.circular(6 * u)),
      Paint()
        ..color = _ink.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * u);

  /// Route through [pts] with an arrowhead at the end.
  void route(List<Offset> pts, {bool dashed = false, Color color = _route}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.4 * u
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    if (dashed) {
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9 * u) {
          c.drawPath(m.extractPath(d, math.min(d + 5 * u, m.length)), paint);
        }
      }
    } else {
      c.drawPath(path, paint);
    }
    arrowHead(pts[pts.length - 2], pts.last, color);
  }

  void arrowHead(Offset from, Offset to, [Color color = _route]) {
    final a = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final s = 8 * u;
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - s * math.cos(a - .5), to.dy - s * math.sin(a - .5))
      ..lineTo(to.dx - s * math.cos(a + .5), to.dy - s * math.sin(a + .5))
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  void curveRoute(Offset a, Offset ctrl, Offset b, {Color color = _route}) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
    c.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3.4 * u
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    arrowHead(Offset.lerp(ctrl, b, .8)!, b, color);
  }

  void northArrow() {
    final o = p(88, 16);
    c.drawLine(o + Offset(0, 6 * u), o - Offset(0, 6 * u), Paint()..color = _ink..strokeWidth = 1.4 * u);
    arrowHead(o, o - Offset(0, 7 * u), _ink);
    final tp = TextPainter(text: TextSpan(text: 'N', style: TextStyle(fontSize: 8 * u, fontWeight: FontWeight.w700, color: _ink)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, o + Offset(-tp.width / 2, 7 * u));
  }

  void compass(String dir) {
    final o = p(50, 50);
    final r = 34 * u;
    c.drawCircle(o, r, Paint()..color = Colors.white);
    c.drawCircle(o, r, Paint()..color = _ink.withValues(alpha: .35)..style = PaintingStyle.stroke..strokeWidth = 1.5 * u);
    for (final (l, a) in [('N', -math.pi / 2), ('E', 0.0), ('S', math.pi / 2), ('W', math.pi)]) {
      final tp = TextPainter(text: TextSpan(text: l, style: TextStyle(fontSize: 8 * u, color: _ink.withValues(alpha: .5), fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
      final q = o + Offset(math.cos(a), math.sin(a)) * (r - 7 * u);
      tp.paint(c, q - Offset(tp.width / 2, tp.height / 2));
    }
    final angle = switch (dir) {
      'n' => -math.pi / 2,
      'ne' => -math.pi / 4,
      'e' => 0.0,
      'se' => math.pi / 4,
      's' => math.pi / 2,
      'sw' => 3 * math.pi / 4,
      'w' => math.pi,
      'nw' => -3 * math.pi / 4,
      _ => -math.pi / 2,
    };
    final tip = o + Offset(math.cos(angle), math.sin(angle)) * (r - 14 * u);
    c.drawLine(o, tip, Paint()..color = _route..strokeWidth = 3.4 * u..strokeCap = StrokeCap.round);
    arrowHead(o, tip);
    c.drawCircle(o, 3 * u, Paint()..color = _ink);
  }

  void fence(double y, {double gapFrom = -1, double gapTo = -1}) {
    final pen = Paint()..color = const Color(0xFF8B6B4A)..strokeWidth = 2 * u;
    for (var x = 10.0; x <= 90; x += 10) {
      if (x > gapFrom && x < gapTo) continue;
      c.drawLine(p(x, y - 8), p(x, y + 8), pen);
    }
    if (gapFrom < 0) {
      c.drawLine(p(10, y - 3), p(90, y - 3), pen);
      c.drawLine(p(10, y + 3), p(90, y + 3), pen);
    } else {
      for (final (a, b) in [(10.0, gapFrom), (gapTo, 90.0)]) {
        c.drawLine(p(a, y - 3), p(b, y - 3), pen);
        c.drawLine(p(a, y + 3), p(b, y + 3), pen);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    u = size.shortestSide / 100;
    bg();
    switch (k) {
      // ---------------- position
      case 'in-front-of':
        block(30, 16, 70, 46);
        c.drawLine(p(30, 46), p(70, 46), Paint()..color = _ink..strokeWidth = 3 * u); // the front
        target(p(50, 70));
      case 'behind':
        target(p(50, 20));
        block(28, 32, 72, 64);
        walker(p(50, 86));
      case 'facing':
        block(10, 34, 36, 66);
        c.drawLine(p(36, 34), p(36, 66), Paint()..color = _ink..strokeWidth = 3 * u);
        block(64, 34, 90, 66, color: _target);
        c.drawLine(p(64, 34), p(64, 66), Paint()..color = _ink..strokeWidth = 3 * u);
        route([p(40, 50), p(49, 50)]);
        route([p(60, 50), p(51, 50)]);
      case 'next-to' || 'beside':
        block(16, 34, 48, 66);
        block(52, 34, 84, 66, color: _target);
      case 'between':
        block(8, 34, 30, 66);
        block(70, 34, 92, 66);
        target(p(50, 50));
      case 'opposite' || 'across-the-road':
        road(p(0, 50), p(100, 50), w: 18);
        block(34, 12, 66, 36);
        block(34, 64, 66, 88, color: _target);
      case 'diagonally-opposite':
        road(p(0, 50), p(100, 50), w: 16);
        road(p(50, 0), p(50, 100), w: 16);
        block(10, 10, 36, 36);
        block(64, 64, 90, 90, color: _target);
      case 'same-side':
        road(p(0, 72), p(100, 72), w: 16);
        block(12, 26, 40, 56);
        block(60, 26, 88, 56, color: _target);
      case 'in-corner' || 'nw-corner' || 'corner':
        room(12, 12, 88, 88);
        target(p(25, 25));
      case 'far-end':
        room(36, 8, 64, 92);
        walker(p(50, 80));
        route([p(50, 70), p(50, 32)], dashed: true);
        target(p(50, 18));
      case 'in-middle' || 'in-the-middle-of':
        room(12, 12, 88, 88);
        target(p(50, 50), r: 9);
      case 'corridor':
        room(36, 6, 64, 94);
        for (final y in [22.0, 46.0, 70.0]) {
          block(18, y - 7, 34, y + 7);
          block(66, y - 7, 82, y + 7);
        }
        walker(p(50, 84));
      case 'inside':
        room(18, 18, 82, 82);
        c.drawLine(p(42, 82), p(58, 82), Paint()..color = const Color(0xFFF7F3EC)..strokeWidth = 4 * u);
        target(p(50, 48));
      case 'surrounded-by':
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          c.drawCircle(p(50 + 30 * math.cos(a), 50 + 30 * math.sin(a)), 6 * u, Paint()..color = _block);
        }
        target(p(50, 50));
      case 'alongside':
        road(p(26, 0), p(26, 100), w: 14);
        block(42, 10, 60, 90);
        route([p(74, 88), p(74, 14)], dashed: true);
      case 'adjoining':
        block(14, 36, 38, 66);
        block(38, 36, 62, 66, color: _target);
        block(62, 36, 86, 66);
      case 'near':
        block(36, 36, 64, 64);
        c.drawCircle(p(50, 50), 30 * u, Paint()..color = _target.withValues(alpha: .18));
        target(p(76, 38), r: 6);
      case 'on-left' || 'left-hand-side':
        road(p(50, 100), p(50, 0), w: 18);
        walker(p(50, 82));
        route([p(50, 70), p(50, 22)]);
        target(p(20, 44));
      case 'on-right' || 'right-hand-side' || 'to-your-right':
        road(p(50, 100), p(50, 0), w: 18);
        walker(p(50, 82));
        route([p(50, 70), p(50, 22)]);
        target(p(80, 44));
      case 'just-before':
        road(p(0, 66), p(100, 66), w: 14);
        block(58, 26, 80, 48);
        target(p(42, 40));
        route([p(8, 66), p(92, 66)], dashed: true);
      case 'just-past' || 'beyond':
        road(p(0, 66), p(100, 66), w: 14);
        block(30, 26, 52, 48);
        target(p(k == 'beyond' ? 84 : 66, 40));
        route([p(8, 66), p(92, 66)], dashed: true);
      case 'go-past':
        block(40, 24, 62, 46);
        route([p(10, 64), p(90, 64)]);
      case 'north-of':
        block(36, 44, 64, 72);
        target(p(50, 22));
        northArrow();
      case 'south-of':
        block(36, 26, 64, 54);
        target(p(50, 78));
        northArrow();
      case 'east-of':
        block(22, 36, 50, 64);
        target(p(76, 50));
        northArrow();
      case 'northern-part':
        room(12, 12, 88, 88);
        c.drawRect(Rect.fromLTRB(14 * u, 14 * u, 86 * u, 38 * u), Paint()..color = _target.withValues(alpha: .6));
        northArrow();
      case 'west-side':
        room(12, 12, 88, 88);
        c.drawRect(Rect.fromLTRB(14 * u, 14 * u, 38 * u, 86 * u), Paint()..color = _target.withValues(alpha: .6));
        northArrow();

      // ---------------- compass
      case String s when s.startsWith('compass-'):
        compass(s.substring(8));
      case 'heading-north':
        compass('n');
      case 'just-southeast-of':
        compass('se');
      case 'to-the-northwest-of':
        compass('nw');
      case 'slightly-east-of':
        compass('e');

      // ---------------- movement
      case 'turn-right':
        road(p(50, 100), p(50, 44), w: 16);
        road(p(42, 50), p(100, 50), w: 16);
        walker(p(50, 86));
        route([p(50, 74), p(50, 50), p(88, 50)]);
      case 'turn-left':
        road(p(50, 100), p(50, 44), w: 16);
        road(p(0, 50), p(58, 50), w: 16);
        walker(p(50, 86));
        route([p(50, 74), p(50, 50), p(12, 50)]);
      case 'straight-on' || 'continue-along' || 'go-straight' || 'carry-straight-on' || 'straight-ahead' || 'along':
        road(p(50, 100), p(50, 0), w: 18);
        walker(p(50, 86));
        route([p(50, 74), p(50, 14)]);
      case 'head-towards':
        walker(p(20, 80));
        route([p(28, 72), p(70, 32)], dashed: true);
        target(p(78, 24));
      case 'cross-over':
        road(p(0, 50), p(100, 50), w: 22);
        for (var x = 38.0; x <= 62; x += 8) {
          c.drawRect(Rect.fromLTRB(x * u, 40 * u, (x + 4) * u, 60 * u), Paint()..color = Colors.white);
        }
        walker(p(50, 86));
        route([p(50, 76), p(50, 16)]);
      case 'follow-round':
        block(36, 36, 64, 64);
        final path = Path()..addArc(Rect.fromCircle(center: p(50, 50), radius: 30 * u), math.pi * .8, math.pi * 1.4);
        c.drawPath(path, Paint()..color = _route..strokeWidth = 3.4 * u..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        final end = p(50 + 30 * math.cos(math.pi * 2.2), 50 + 30 * math.sin(math.pi * 2.2));
        arrowHead(p(50 + 30 * math.cos(math.pi * 2.1), 50 + 30 * math.sin(math.pi * 2.1)), end);
      case 'through-gate' || 'pass-through':
        fence(50, gapFrom: 40, gapTo: 60);
        walker(p(50, 86));
        route([p(50, 76), p(50, 16)]);
      case 'as-far-as':
        road(p(50, 100), p(50, 10), w: 16);
        c.drawLine(p(30, 28), p(70, 28), Paint()..color = _ink..strokeWidth = 3 * u);
        walker(p(50, 86));
        route([p(50, 74), p(50, 34)]);
        target(p(76, 28), r: 6);
      case 'double-back':
        final path = Path()
          ..moveTo(35 * u, 88 * u)
          ..lineTo(35 * u, 34 * u)
          ..arcToPoint(p(65, 34), radius: Radius.circular(15 * u))
          ..lineTo(65 * u, 76 * u);
        c.drawPath(path, Paint()..color = _route..strokeWidth = 3.4 * u..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        arrowHead(p(65, 66), p(65, 80));
      case 'go-up' || 'go-down' || 'steps':
        final st = Path()..moveTo(12 * u, 84 * u);
        for (var i = 0; i < 4; i++) {
          st
            ..lineTo((12 + i * 18) * u, (84 - (i + 1) * 16) * u)
            ..lineTo((12 + (i + 1) * 18) * u, (84 - (i + 1) * 16) * u);
        }
        st
          ..lineTo(84 * u, 84 * u)
          ..close();
        c.drawPath(st, Paint()..color = _block);
        if (k == 'go-up') route([p(18, 64), p(74, 16)]);
        if (k == 'go-down') route([p(74, 16), p(18, 64)]);
      case 'first-right':
        road(p(40, 100), p(40, 0), w: 14);
        road(p(40, 70), p(100, 70), w: 12);
        road(p(40, 34), p(100, 34), w: 12);
        route([p(40, 94), p(40, 70), p(86, 70)]);
      case 'second-left' || 'second-turning':
        road(p(60, 100), p(60, 0), w: 14);
        road(p(0, 70), p(60, 70), w: 12);
        road(p(0, 34), p(60, 34), w: 12);
        route([p(60, 94), p(60, 34), p(14, 34)]);
      case 'clockwise' || 'anticlockwise':
        final cw = k == 'clockwise';
        final start = cw ? -math.pi * .5 : -math.pi * .5;
        final sweep = cw ? math.pi * 1.6 : -math.pi * 1.6;
        c.drawArc(Rect.fromCircle(center: p(50, 50), radius: 28 * u), start, sweep, false,
            Paint()..color = _route..strokeWidth = 3.4 * u..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        final a2 = start + sweep, a1 = start + sweep * .9;
        arrowHead(p(50 + 28 * math.cos(a1), 50 + 28 * math.sin(a1)), p(50 + 28 * math.cos(a2), 50 + 28 * math.sin(a2)));
      case 'leads-off':
        road(p(0, 72), p(100, 72), w: 16);
        road(p(50, 72), p(50, 20), w: 12);
        c.drawLine(p(40, 20), p(60, 20), Paint()..color = _ink..strokeWidth = 3 * u);
        target(p(50, 30), r: 6);

      // ---------------- roads & paths
      case 'crossroads':
        road(p(0, 50), p(100, 50), w: 18);
        road(p(50, 0), p(50, 100), w: 18);
      case 't-junction' || 'junction' || 'at-junction':
        road(p(0, 34), p(100, 34), w: 18);
        road(p(50, 34), p(50, 100), w: 18);
        if (k == 'at-junction') target(p(70, 60), r: 6);
      case 'roundabout':
        road(p(0, 50), p(100, 50), w: 14);
        road(p(50, 0), p(50, 100), w: 14);
        c.drawCircle(p(50, 50), 22 * u, Paint()..color = _road);
        c.drawCircle(p(50, 50), 11 * u, Paint()..color = const Color(0xFFB9CB7C));
      case 'fork':
        road(p(50, 100), p(50, 56), w: 16);
        road(p(50, 60), p(18, 8), w: 14);
        road(p(50, 60), p(82, 8), w: 14);
      case 'bend':
        final b = Path()
          ..moveTo(20 * u, 100 * u)
          ..quadraticBezierTo(20 * u, 30 * u, 100 * u, 26 * u);
        c.drawPath(b, Paint()..color = _road..strokeWidth = 18 * u..style = PaintingStyle.stroke);
      case 'dead-end':
        road(p(50, 100), p(50, 26), w: 18);
        c.drawLine(p(36, 24), p(64, 24), Paint()..color = AppColors.rust..strokeWidth = 4 * u);
      case 'crossing':
        road(p(0, 50), p(100, 50), w: 30);
        for (var x = 20.0; x <= 76; x += 10) {
          c.drawRect(Rect.fromLTRB(x * u, 38 * u, (x + 5) * u, 62 * u), Paint()..color = Colors.white);
        }
      case 'footbridge':
        road(p(0, 60), p(100, 60), w: 22);
        c.drawArc(Rect.fromLTRB(22 * u, 22 * u, 78 * u, 98 * u), math.pi, math.pi, false,
            Paint()..color = const Color(0xFF8B6B4A)..strokeWidth = 5 * u..style = PaintingStyle.stroke);
      case 'footpath' || 'track':
        final fp = Path()
          ..moveTo(10 * u, 90 * u)
          ..cubicTo(40 * u, 70 * u, 20 * u, 40 * u, 60 * u, 30 * u)
          ..quadraticBezierTo(80 * u, 24 * u, 90 * u, 10 * u);
        final pen = Paint()..color = const Color(0xFFB59A74)..strokeWidth = (k == 'track' ? 6 : 4) * u..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        for (final m in fp.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 10 * u) {
            c.drawPath(m.extractPath(d, math.min(d + (k == 'track' ? 3 : 6) * u, m.length)), pen);
          }
        }
      case 'lane':
        road(p(50, 100), p(50, 0), w: 12);
        final dash = Paint()..color = Colors.white..strokeWidth = 1.5 * u;
        for (var y = 6.0; y < 100; y += 12) {
          c.drawLine(p(50, y), p(50, y + 6), dash);
        }
      case 'slope':
        c.drawPath(Path()..moveTo(10 * u, 84 * u)..lineTo(90 * u, 84 * u)..lineTo(90 * u, 30 * u)..close(), Paint()..color = _block);
        route([p(22, 74), p(80, 40)]);
      case 'fence':
        fence(50);
      case 'gate':
        fence(50, gapFrom: 40, gapTo: 60);
        c.drawLine(p(40, 50), p(52, 36), Paint()..color = const Color(0xFF8B6B4A)..strokeWidth = 3 * u);
      case 'hedge':
        for (var x = 14.0; x <= 86; x += 12) {
          c.drawCircle(p(x, 52), 9 * u, Paint()..color = const Color(0xFF88A338));
        }

      default:
        // Neutral pin for anything not drawn yet.
        target(p(50, 44), r: 13);
        c.drawLine(p(50, 57), p(50, 80), Paint()..color = _ink..strokeWidth = 2.4 * u);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.k != k;
}
