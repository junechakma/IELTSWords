import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tiny hand-drawn chart icon for a topic id (line, bar, pie, table, map,
/// process, mixed), as on the prototype's Library cards. Other topics
/// (essays, letters) fall back to [fallback].
class ChartGlyph extends StatelessWidget {
  const ChartGlyph(this.id, {super.key, this.width = 46, this.height = 28, this.color = AppColors.ink, this.fallback = Icons.edit_note_rounded});
  final String id;
  final double width, height;
  final Color color;
  final IconData fallback;

  static const drawn = {'line', 'bar', 'pie', 'table', 'map', 'process', 'mixed'};

  @override
  Widget build(BuildContext context) {
    if (!drawn.contains(id)) return Icon(fallback, size: height, color: color);
    return CustomPaint(size: Size(width, height), painter: _GlyphPainter(id, color));
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.id, this.color);
  final String id;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final sx = s.width / 46, sy = s.height / 26;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (id) {
      case 'line':
        canvas.drawPath(Path()..moveTo(p(2, 22).dx, p(2, 22).dy)..lineTo(p(12, 16).dx, p(12, 16).dy)..lineTo(p(20, 19).dx, p(20, 19).dy)..lineTo(p(30, 8).dx, p(30, 8).dy)..lineTo(p(44, 3).dx, p(44, 3).dy), stroke..strokeWidth = 2.6 * sx);
      case 'bar':
        for (final (x, y) in [(3.0, 12.0), (14.0, 4.0), (25.0, 9.0), (36.0, 16.0)]) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(x, y), p(x + 7, 25)), Radius.circular(2 * sx)), fill);
        }
      case 'pie':
        final c = p(13, 13), r = 11 * sy;
        canvas.drawCircle(c, r, Paint()..color = Colors.white);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, math.pi * 0.62, true, fill);
        canvas.drawCircle(c, r, stroke..strokeWidth = 1.4 * sx);
      case 'table':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(2, 2), p(32, 24)), Radius.circular(3 * sx)), stroke);
        canvas.drawLine(p(2, 9), p(32, 9), stroke);
        canvas.drawLine(p(2, 16), p(32, 16), stroke);
        canvas.drawLine(p(13, 2), p(13, 24), stroke);
      case 'map':
        canvas.drawPath(
            Path()
              ..moveTo(p(2, 5).dx, p(2, 5).dy)
              ..lineTo(p(14, 2).dx, p(14, 2).dy)
              ..lineTo(p(26, 5).dx, p(26, 5).dy)
              ..lineTo(p(38, 2).dx, p(38, 2).dy)
              ..lineTo(p(38, 21).dx, p(38, 21).dy)
              ..lineTo(p(26, 24).dx, p(26, 24).dy)
              ..lineTo(p(14, 21).dx, p(14, 21).dy)
              ..lineTo(p(2, 24).dx, p(2, 24).dy)
              ..close(),
            stroke);
        canvas.drawLine(p(14, 2), p(14, 21), stroke);
        canvas.drawLine(p(26, 5), p(26, 24), stroke);
      case 'process':
        for (final x in [6.0, 23.0, 40.0]) {
          canvas.drawCircle(p(x, 13), 4 * sx, stroke);
        }
        canvas.drawLine(p(11, 13), p(17, 13), stroke);
        canvas.drawLine(p(28, 13), p(34, 13), stroke);
      case 'mixed':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(2, 2), p(20, 24)), Radius.circular(3 * sx)), stroke);
        for (final (x, y) in [(5.0, 14.0), (10.0, 8.0), (15.0, 17.0)]) {
          canvas.drawRect(Rect.fromPoints(p(x, y), p(x + 3, 21)), fill);
        }
        canvas.drawCircle(p(35, 13), 9 * sy, stroke);
        canvas.drawArc(Rect.fromCircle(center: p(35, 13), radius: 9 * sy), -math.pi / 2, math.pi * .7, true, fill);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.id != id || old.color != color;
}
