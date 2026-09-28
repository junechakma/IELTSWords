import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A ticket: rounded card with two half-circle notches cut from the sides
/// at [notchAt] (0–1 of the height) and an optional dashed tear line.
class TicketBorder extends ShapeBorder {
  const TicketBorder({this.radius = 24, this.notch = 12, this.notchAt = .62, this.side = BorderSide.none});
  final double radius, notch, notchAt;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect r) {
    final y = r.top + r.height * notchAt;
    final outer = Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(r.left, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(r.right, y), radius: notch));
    return Path.combine(ui.PathOperation.difference, outer, holes);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final y = rect.top + rect.height * notchAt;
    // Dashed tear line between the notches.
    final dash = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.4;
    for (var x = rect.left + notch + 6; x < rect.right - notch - 6; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4.5, rect.right - notch - 6), y), dash);
    }
    if (side != BorderSide.none) canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => TicketBorder(radius: radius * t, notch: notch * t, notchAt: notchAt, side: side.scale(t));
}

/// Speech bubble with a small tail at the bottom-left (points at a mascot).
class BubbleBorder extends ShapeBorder {
  const BubbleBorder({this.radius = 22, this.tail = 12, this.tailAt = 28});
  final double radius, tail, tailAt;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: tail);

  Path _path(Rect r) {
    final body = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - tail);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)))
      ..moveTo(body.left + tailAt, body.bottom - 2)
      ..quadraticBezierTo(body.left + tailAt - 4, body.bottom + tail * .7, body.left + tailAt - 14, r.bottom)
      ..quadraticBezierTo(body.left + tailAt + 8, body.bottom + tail * .6, body.left + tailAt + 16, body.bottom - 2)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => BubbleBorder(radius: radius * t, tail: tail * t, tailAt: tailAt * t);
}

/// Soft, slightly irregular "pebble" (squircle-ish blob). [seed] varies the
/// wobble so a grid of pebbles doesn't look machine-made.
class PebbleBorder extends ShapeBorder {
  const PebbleBorder({this.seed = 0, this.side = BorderSide.none});
  final int seed;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect r) {
    final rnd = math.Random(seed);
    double j() => (rnd.nextDouble() - .5) * .08;
    final w = r.width, h = r.height;
    Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
    return Path()
      ..moveTo(p(.5, 0 + j()).dx, p(.5, 0 + j()).dy)
      ..cubicTo(p(.86 + j(), 0).dx, p(.86, 0 + j()).dy, p(1, .14 + j()).dx, p(1, .14).dy, p(1 + j(), .5).dx, p(1, .5).dy)
      ..cubicTo(p(1, .86 + j()).dx, p(1, .86).dy, p(.86 + j(), 1).dx, p(.86, 1).dy, p(.5, 1 + j()).dx, p(.5, 1).dy)
      ..cubicTo(p(.14 + j(), 1).dx, p(.14, 1).dy, p(0, .86 + j()).dx, p(0, .86).dy, p(0 + j(), .5).dx, p(0, .5).dy)
      ..cubicTo(p(0, .14 + j()).dx, p(0, .14).dy, p(.14 + j(), 0).dx, p(.14, 0).dy, p(.5, 0).dx, p(.5, 0).dy)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side != BorderSide.none) canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => PebbleBorder(seed: seed, side: side.scale(t));
}

/// A mini line chart that goes from `from` to `to` (0–1 of the height),
/// used to picture how big a change a word describes.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.from, required this.to, this.color = const Color(0xFF1D1D1D), this.width = 64, this.height = 30, this.wobble = false});
  final double from, to;
  final Color color;
  final double width, height;
  final bool wobble;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, height), painter: _SparkPainter(from, to, color, wobble));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.from, this.to, this.color, this.wobble);
  final double from, to;
  final Color color;
  final bool wobble;

  @override
  void paint(Canvas canvas, Size s) {
    double y(double v) => s.height - 3 - v * (s.height - 6);
    final path = Path()..moveTo(2, y(from));
    const n = 12;
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      final base = from + (to - from) * Curves.easeInOut.transform(t);
      final v = wobble ? base + math.sin(t * math.pi * 4) * .18 : base;
      path.lineTo(2 + t * (s.width - 4), y(v.clamp(0, 1)));
    }
    final grid = Paint()
      ..color = color.withValues(alpha: .12)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, s.height - 1), Offset(s.width, s.height - 1), grid);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(s.width - 2, y(wobble ? to : to)), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.from != from || o.to != to || o.color != color;
}
