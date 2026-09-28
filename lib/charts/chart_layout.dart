import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../data/chart_models.dart';
import '../theme/app_theme.dart';

/// Colours for chart series, in order.
const seriesColors = [AppColors.rust, AppColors.olive, AppColors.cocoa, Color(0xFFE0921A), AppColors.stone, Color(0xFF7B68C8)];

const _hl = AppColors.rust;

String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(v.abs() < 10 ? 1 : 1).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

/// Geometry for one chart at one size: paints it, finds each part's anchor
/// and which part is under a tap.
abstract class ChartLayout {
  ChartLayout(this.size);

  final Size size;

  factory ChartLayout.of(ChartData chart, Size size) => switch (chart) {
        LineChartData c => _LineLayout(c, size),
        BarChartData c => _BarLayout(c, size),
        PieChartData c => _PieLayout(c, size),
        TableChartData c => _TableLayout(c, size),
        MapChartData c => _MapLayout(c, size),
        ProcessChartData c => _ProcessLayout(c, size),
        MixedChartData c => _MixedLayout(c, size),
      };

  /// Height that suits [chart] at [width].
  static double heightFor(ChartData chart, double width) => switch (chart) {
        LineChartData() => math.min(230, width * .62),
        BarChartData() => math.min(230, width * .62),
        PieChartData() => math.min(210, width * .56),
        TableChartData c => 34.0 + c.rows.length * 30,
        MapChartData() => width * .56 + 22,
        ProcessChartData c => ((c.stages.length + 2) ~/ 3) * 96.0 + 8,
        MixedChartData c => c.charts.fold(0.0, (h, s) => h + heightFor(s, width) + 30),
      };

  void paint(Canvas canvas, {String? highlight, bool dimOthers = false});

  Offset? anchor(String partId);

  /// Part ids this layout knows.
  Iterable<String> get partIds;

  String? hitTest(Offset p) {
    String? best;
    var bestD = 34.0;
    for (final id in partIds) {
      final a = anchor(id);
      if (a == null) continue;
      final d = (a - p).distance;
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    return best;
  }

  // ---- helpers ----
  static void text(Canvas c, String s, Offset at,
      {double size = 10.5, Color color = AppColors.inkSoft, FontWeight weight = FontWeight.w400, TextAlign align = TextAlign.left, double? maxWidth, Alignment anchor = Alignment.topLeft}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: GoogleFonts.outfit(fontSize: size, color: color, fontWeight: weight, height: 1.15)),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final dx = at.dx - tp.width * (anchor.x + 1) / 2;
    final dy = at.dy - tp.height * (anchor.y + 1) / 2;
    tp.paint(c, Offset(dx, dy));
  }

  static double niceMax(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
      if (m * mag >= v) return m * mag;
    }
    return 10 * mag;
  }
}

// ---------------------------------------------------------------- line

class _LineLayout extends ChartLayout {
  _LineLayout(this.c, super.size) {
    final maxV = c.series.expand((s) => s.values).fold<double>(0, math.max);
    top = ChartLayout.niceMax(maxV * 1.05);
    final legend = c.series.length > 1 ? 18.0 : 4.0;
    plot = Rect.fromLTRB(32, legend + 6, size.width - 10, size.height - 20);
  }

  final LineChartData c;
  late final double top;
  late final Rect plot;

  Offset pt(int s, int i) {
    final n = c.xLabels.length;
    final x = plot.left + (n == 1 ? plot.width / 2 : plot.width * i / (n - 1));
    final y = plot.bottom - plot.height * (c.series[s].values[i] / top);
    return Offset(x, y);
  }

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    final s = p.series ?? 0;
    final a = pt(s, p.from!), b = pt(s, p.to!);
    return Offset.lerp(a, b, .5);
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = plot.bottom - plot.height * k / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      ChartLayout.text(canvas, fmtNum(top * k / 4), Offset(plot.left - 5, y), size: 9.5, anchor: Alignment.centerRight);
    }
    final n = c.xLabels.length;
    final step = n > 8 ? 2 : 1;
    for (var i = 0; i < n; i += step) {
      ChartLayout.text(canvas, c.xLabels[i], Offset(pt(0, i).dx, plot.bottom + 4), size: 9.5, anchor: Alignment.topCenter);
    }
    if (c.series.length > 1) {
      var x = plot.left;
      for (final (i, s) in c.series.indexed) {
        canvas.drawCircle(Offset(x + 4, 8), 4, Paint()..color = seriesColors[i % seriesColors.length]);
        final tp = TextPainter(text: TextSpan(text: s.name, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x + 11, 8 - tp.height / 2));
        x += tp.width + 24;
      }
    }
    final hp = highlight == null ? null : c.part(highlight);
    for (var s = 0; s < c.series.length; s++) {
      final color = seriesColors[s % seriesColors.length];
      final dim = dimOthers && hp != null;
      final path = Path()..moveTo(pt(s, 0).dx, pt(s, 0).dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(pt(s, i).dx, pt(s, i).dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = dim ? color.withValues(alpha: .35) : color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }
    if (hp != null) {
      final s = hp.series ?? 0;
      final path = Path()..moveTo(pt(s, hp.from!).dx, pt(s, hp.from!).dy);
      for (var i = hp.from! + 1; i <= hp.to!; i++) {
        path.lineTo(pt(s, i).dx, pt(s, i).dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.sunflower.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
      canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
      if (hp.from == hp.to) {
        canvas.drawCircle(pt(s, hp.from!), 6, Paint()..color = AppColors.ink);
      }
    }
  }
}

// ---------------------------------------------------------------- bar

class _BarLayout extends ChartLayout {
  _BarLayout(this.c, super.size) {
    final maxV = c.series.expand((s) => s.values).fold<double>(0, math.max);
    top = ChartLayout.niceMax(maxV * 1.05);
    final legend = c.series.length > 1 ? 18.0 : 4.0;
    plot = Rect.fromLTRB(32, legend + 6, size.width - 6, size.height - 20);
  }

  final BarChartData c;
  late final double top;
  late final Rect plot;

  Rect bar(int s, int i) {
    final groupW = plot.width / c.categories.length;
    final inner = groupW * .76;
    final bw = inner / c.series.length;
    final x = plot.left + groupW * i + (groupW - inner) / 2 + bw * s;
    final h = plot.height * (c.series[s].values[i] / top);
    return Rect.fromLTWH(x + 1, plot.bottom - h, bw - 2, h);
  }

  Rect group(int i) {
    Rect r = bar(0, i);
    for (var s = 1; s < c.series.length; s++) {
      r = r.expandToInclude(bar(s, i));
    }
    return r;
  }

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    final r = p.series == null ? group(p.index!) : bar(p.series!, p.index!);
    return Offset(r.center.dx, r.top + math.min(10, r.height / 2));
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final grid = Paint()..color = AppColors.line;
    for (var k = 0; k <= 4; k++) {
      final y = plot.bottom - plot.height * k / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      ChartLayout.text(canvas, fmtNum(top * k / 4), Offset(plot.left - 5, y), size: 9.5, anchor: Alignment.centerRight);
    }
    if (c.series.length > 1) {
      var x = plot.left;
      for (final (i, s) in c.series.indexed) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 4, 8, 8), const Radius.circular(2)), Paint()..color = seriesColors[i % seriesColors.length]);
        final tp = TextPainter(text: TextSpan(text: s.name, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x + 11, 8 - tp.height / 2));
        x += tp.width + 22;
      }
    }
    final hp = highlight == null ? null : c.part(highlight);
    for (var i = 0; i < c.categories.length; i++) {
      ChartLayout.text(canvas, c.categories[i], Offset(group(i).center.dx, plot.bottom + 4),
          size: 9.5, anchor: Alignment.topCenter, maxWidth: plot.width / c.categories.length, align: TextAlign.center);
      for (var s = 0; s < c.series.length; s++) {
        final on = hp != null && hp.index == i && (hp.series == null || hp.series == s);
        final color = seriesColors[s % seriesColors.length];
        final r = bar(s, i);
        canvas.drawRRect(RRect.fromRectAndCorners(r, topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
            Paint()..color = dimOthers && hp != null && !on ? color.withValues(alpha: .3) : color);
        if (on) {
          canvas.drawRRect(
              RRect.fromRectAndCorners(r.inflate(2.5), topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
              Paint()
                ..color = AppColors.ink
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5);
        }
      }
    }
  }
}

// ---------------------------------------------------------------- pie

class _PieLayout extends ChartLayout {
  _PieLayout(this.c, super.size) {
    r = math.min(size.height / 2 - 8, size.width * .26);
    center = Offset(r + 12, size.height / 2);
  }

  final PieChartData c;
  late final double r;
  late final Offset center;

  double get total => c.slices.fold(0.0, (t, s) => t + s.value);

  (double, double) angles(int i) {
    var start = -math.pi / 2;
    for (var k = 0; k < i; k++) {
      start += c.slices[k].value / total * 2 * math.pi;
    }
    return (start, c.slices[i].value / total * 2 * math.pi);
  }

  static const colors = [AppColors.rust, AppColors.sunflower, AppColors.olive, AppColors.cocoa, Color(0xFF9A8FD9), AppColors.stone, AppColors.peach, Color(0xFFB9CB7C)];

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    final (a, sweep) = angles(p.slice!);
    final mid = a + sweep / 2;
    return center + Offset(math.cos(mid), math.sin(mid)) * r * .62;
  }

  @override
  String? hitTest(Offset p) {
    final d = p - center;
    if (d.distance > r + 6) return super.hitTest(p);
    var ang = math.atan2(d.dy, d.dx);
    if (ang < -math.pi / 2) ang += 2 * math.pi;
    for (final part in c.parts) {
      final (a, sweep) = angles(part.slice!);
      if (ang >= a && ang <= a + sweep) return part.id;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final hp = highlight == null ? null : c.part(highlight);
    for (var i = 0; i < c.slices.length; i++) {
      final (a, sweep) = angles(i);
      final on = hp?.slice == i;
      final mid = a + sweep / 2;
      final off = on ? Offset(math.cos(mid), math.sin(mid)) * 7 : Offset.zero;
      final color = colors[i % colors.length];
      final rect = Rect.fromCircle(center: center + off, radius: r);
      canvas.drawArc(rect, a, sweep, true, Paint()..color = dimOthers && hp != null && !on ? color.withValues(alpha: .35) : color);
      canvas.drawArc(rect, a, sweep, true,
          Paint()
            ..color = on ? AppColors.ink : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = on ? 3 : 1.5);
      if (sweep > .32) {
        ChartLayout.text(canvas, '${fmtNum(c.slices[i].value)}${c.unit}', center + off + Offset(math.cos(mid), math.sin(mid)) * r * .66,
            size: 10, color: Colors.white, weight: FontWeight.w600, anchor: Alignment.center);
      }
    }
    // Legend on the right.
    final lx = center.dx + r + 18;
    final rowH = math.min(19.0, (size.height - 8) / c.slices.length);
    final y0 = size.height / 2 - rowH * c.slices.length / 2;
    for (var i = 0; i < c.slices.length; i++) {
      final y = y0 + rowH * i + rowH / 2;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx + 5, y), width: 10, height: 10), const Radius.circular(3)),
          Paint()..color = colors[i % colors.length]);
      ChartLayout.text(canvas, '${c.slices[i].label}  ${fmtNum(c.slices[i].value)}${c.unit}', Offset(lx + 15, y),
          size: 10.5, color: hp?.slice == i ? AppColors.ink : AppColors.inkSoft, weight: hp?.slice == i ? FontWeight.w600 : FontWeight.w400,
          anchor: Alignment.centerLeft, maxWidth: size.width - lx - 16);
    }
  }
}

// ---------------------------------------------------------------- table

class _TableLayout extends ChartLayout {
  _TableLayout(this.c, super.size);

  final TableChartData c;
  static const headH = 30.0, rowH = 30.0;

  double get firstW => math.min(size.width * .34, 118);
  double get colW => (size.width - firstW) / (c.columns.length - 1);

  Rect cell(int row, int col) => Rect.fromLTWH(firstW + colW * col, headH + rowH * row, colW, rowH);
  Rect rowRect(int row) => Rect.fromLTWH(0, headH + rowH * row, size.width, rowH);
  Rect colRect(int col) => Rect.fromLTWH(firstW + colW * col, 0, colW, headH + rowH * c.rows.length);

  Rect? partRect(ChartPart p) {
    if (p.row != null && p.col != null) return cell(p.row!, p.col!);
    if (p.row != null) return rowRect(p.row!);
    if (p.col != null) return colRect(p.col!);
    return null;
  }

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    final r = partRect(p);
    if (r == null) return null;
    if (p.row != null && p.col == null) return Offset(firstW / 2, r.center.dy);
    return r.center;
  }

  @override
  String? hitTest(Offset p) {
    // Prefer the smallest rect under the finger (cell over row over column).
    String? best;
    var area = double.infinity;
    for (final part in c.parts) {
      final r = partRect(part);
      if (r != null && r.contains(p) && r.width * r.height < area) {
        area = r.width * r.height;
        best = part.id;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final hp = highlight == null ? null : c.part(highlight);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, headH), topLeft: const Radius.circular(10), topRight: const Radius.circular(10)),
        Paint()..color = AppColors.sand);
    if (hp != null) {
      final r = partRect(hp);
      if (r != null) {
        canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(6)), Paint()..color = AppColors.sunflower.withValues(alpha: .55));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(6)),
            Paint()
              ..color = AppColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
    for (var k = 0; k < c.columns.length; k++) {
      final x = k == 0 ? 8.0 : firstW + colW * (k - 1) + colW / 2;
      ChartLayout.text(canvas, c.columns[k], Offset(x, headH / 2),
          size: 10.5, color: AppColors.ink, weight: FontWeight.w600, anchor: k == 0 ? Alignment.centerLeft : Alignment.center, maxWidth: k == 0 ? firstW - 10 : colW - 4, align: TextAlign.center);
    }
    for (var r = 0; r < c.rows.length; r++) {
      final y = headH + rowH * r;
      canvas.drawLine(Offset(0, y + rowH), Offset(size.width, y + rowH), Paint()..color = AppColors.line);
      ChartLayout.text(canvas, c.rows[r].label, Offset(8, y + rowH / 2), size: 11, color: AppColors.ink, anchor: Alignment.centerLeft, maxWidth: firstW - 10);
      for (var k = 0; k < c.rows[r].values.length; k++) {
        ChartLayout.text(canvas, fmtNum(c.rows[r].values[k]), cell(r, k).center, size: 11, color: AppColors.ink, anchor: Alignment.center);
      }
    }
  }
}

// ---------------------------------------------------------------- map

const mapFeatureColors = {
  'building': Color(0xFF73443A),
  'housing': Color(0xFFD15435),
  'shops': Color(0xFFE0921A),
  'trees': Color(0xFF88A338),
  'park': Color(0xFFB9CB7C),
  'field': Color(0xFFE6E0B8),
  'water': Color(0xFF9CC7E4),
  'road': Color(0xFFBDB6AA),
  'path': Color(0xFFD9D2C5),
  'carpark': Color(0xFFA7A29A),
  'bridge': Color(0xFF7A7463),
};

class _MapLayout extends ChartLayout {
  _MapLayout(this.c, super.size) {
    final w = (size.width - 10) / 2;
    left = Rect.fromLTWH(0, 18, w, size.height - 18);
    right = Rect.fromLTWH(w + 10, 18, w, size.height - 18);
  }

  final MapChartData c;
  late final Rect left, right;

  Rect feat(MapFeature f, Rect box) => Rect.fromLTWH(box.left + f.x * box.width, box.top + f.y * box.height, f.w * box.width, f.h * box.height);

  (MapFeature, Rect)? locate(ChartPart p) {
    final side = p.map == 'before' ? c.before : c.after;
    final box = p.map == 'before' ? left : right;
    for (final f in side.features) {
      if (f.id == p.feature) return (f, feat(f, box));
    }
    return null;
  }

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    return locate(p)?.$2.center;
  }

  @override
  String? hitTest(Offset p) {
    String? best;
    var area = double.infinity;
    for (final part in c.parts) {
      final r = locate(part)?.$2;
      if (r != null && r.inflate(4).contains(p) && r.width * r.height < area) {
        area = r.width * r.height;
        best = part.id;
      }
    }
    return best ?? super.hitTest(p);
  }

  void _side(Canvas canvas, MapSide side, Rect box, ChartPart? hp, String map) {
    ChartLayout.text(canvas, side.label, Offset(box.left + 2, 2), size: 11, color: AppColors.ink, weight: FontWeight.w600);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(10)), Paint()..color = const Color(0xFFEFF3E2));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(box, const Radius.circular(10)));
    // Roads / paths / water / fields first, buildings on top.
    const order = ['field', 'park', 'water', 'road', 'path', 'bridge', 'carpark', 'trees', 'housing', 'shops', 'building'];
    final feats = [...side.features]..sort((a, b) => order.indexOf(a.type).compareTo(order.indexOf(b.type)));
    for (final f in feats) {
      final r = feat(f, box);
      final color = mapFeatureColors[f.type] ?? AppColors.stone;
      final on = hp != null && hp.map == map && hp.feature == f.id;
      switch (f.type) {
        case 'trees':
          final n = math.max(1, (r.width / 14).floor());
          final m = math.max(1, (r.height / 14).floor());
          for (var i = 0; i < n; i++) {
            for (var k = 0; k < m; k++) {
              canvas.drawCircle(Offset(r.left + r.width * (i + .5) / n, r.top + r.height * (k + .5) / m), math.min(r.width / n, r.height / m) * .42, Paint()..color = color);
            }
          }
        case 'water':
          canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(math.min(r.width, r.height) / 2)), Paint()..color = color);
        case 'housing':
          final n = math.max(1, (r.width / 13).floor());
          final m = math.max(1, (r.height / 13).floor());
          for (var i = 0; i < n; i++) {
            for (var k = 0; k < m; k++) {
              final cw = r.width / n, ch = r.height / m;
              canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + cw * i + 1.5, r.top + ch * k + 1.5, cw - 3, ch - 3), const Radius.circular(2)), Paint()..color = color);
            }
          }
        default:
          canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(f.type == 'road' || f.type == 'path' ? 2 : 4)), Paint()..color = color);
      }
      if (on) {
        canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(6)), Paint()..color = AppColors.sunflower.withValues(alpha: .35));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(6)),
            Paint()
              ..color = AppColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4);
      }
    }
    for (final f in feats) {
      if (f.label.isEmpty) continue;
      final r = feat(f, box);
      final dark = const {'building', 'housing', 'carpark', 'bridge'}.contains(f.type);
      final big = r.width > 40 && r.height > 16;
      if (big) {
        ChartLayout.text(canvas, f.label, r.center, size: 8.5, color: dark ? Colors.white : AppColors.ink, anchor: Alignment.center, maxWidth: r.width - 2, align: TextAlign.center);
      } else {
        ChartLayout.text(canvas, f.label, Offset(r.center.dx, r.bottom + 1), size: 8, color: AppColors.ink, anchor: Alignment.topCenter, maxWidth: 70, align: TextAlign.center);
      }
    }
    canvas.restore();
    // North arrow
    final n = Offset(box.right - 10, box.top + 14);
    canvas.drawPath(Path()..moveTo(n.dx, n.dy - 8)..lineTo(n.dx - 4, n.dy + 3)..lineTo(n.dx + 4, n.dy + 3)..close(), Paint()..color = AppColors.ink);
    ChartLayout.text(canvas, 'N', n + const Offset(0, 5), size: 8, color: AppColors.ink, anchor: Alignment.topCenter, weight: FontWeight.w600);
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final hp = highlight == null ? null : c.part(highlight);
    _side(canvas, c.before, left, hp, 'before');
    _side(canvas, c.after, right, hp, 'after');
  }
}

// ---------------------------------------------------------------- process

const processIcons = <String, IconData>{
  'eco': Icons.eco_rounded,
  'water': Icons.water_drop_rounded,
  'fire': Icons.local_fire_department_rounded,
  'factory': Icons.factory_rounded,
  'truck': Icons.local_shipping_rounded,
  'store': Icons.storefront_rounded,
  'recycle': Icons.recycling_rounded,
  'cut': Icons.content_cut_rounded,
  'mix': Icons.blender_rounded,
  'filter': Icons.filter_alt_rounded,
  'package': Icons.inventory_2_rounded,
  'sun': Icons.wb_sunny_rounded,
  'cool': Icons.ac_unit_rounded,
  'grind': Icons.settings_rounded,
  'dry': Icons.air_rounded,
  'sort': Icons.sort_rounded,
  'home': Icons.home_rounded,
};

class _ProcessLayout extends ChartLayout {
  _ProcessLayout(this.c, super.size);

  final ProcessChartData c;
  static const perRow = 3;

  Rect box(int i) {
    final row = i ~/ perRow;
    var col = i % perRow;
    if (row.isOdd) col = perRow - 1 - col; // snake so arrows stay short
    final w = (size.width - 16 * (perRow - 1)) / perRow;
    return Rect.fromLTWH(col * (w + 16), row * 96.0 + 4, w, 76);
  }

  @override
  Iterable<String> get partIds => c.parts.map((p) => p.id);

  @override
  Offset? anchor(String id) {
    final p = c.part(id);
    if (p == null) return null;
    return box(p.stage!).center;
  }

  @override
  String? hitTest(Offset p) {
    for (final part in c.parts) {
      if (box(part.stage!).contains(p)) return part.id;
    }
    return null;
  }

  void _arrow(Canvas canvas, Offset a, Offset b) {
    final paint = Paint()
      ..color = AppColors.stone
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
    final dir = (b - a) / (b - a).distance;
    final nrm = Offset(-dir.dy, dir.dx);
    canvas.drawPath(Path()..moveTo(b.dx, b.dy)..lineTo((b - dir * 7 + nrm * 4).dx, (b - dir * 7 + nrm * 4).dy)..lineTo((b - dir * 7 - nrm * 4).dx, (b - dir * 7 - nrm * 4).dy)..close(),
        Paint()..color = AppColors.stone);
  }

  Offset _edge(Rect r, Offset toward) {
    final d = toward - r.center;
    if (d.dx.abs() * r.height > d.dy.abs() * r.width) {
      return Offset(d.dx > 0 ? r.right + 2 : r.left - 2, r.center.dy);
    }
    return Offset(r.center.dx, d.dy > 0 ? r.bottom + 2 : r.top - 2);
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    final hp = highlight == null ? null : c.part(highlight);
    final n = c.stages.length;
    for (var i = 0; i < n - 1; i++) {
      final a = box(i), b = box(i + 1);
      _arrow(canvas, _edge(a, b.center), _edge(b, a.center));
    }
    if (c.cyclic && n > 2) {
      final a = box(n - 1), b = box(0);
      final p1 = Offset(a.left - 2, a.center.dy);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(-6, (a.center.dy + b.center.dy) / 2, b.left - 2, b.center.dy + 12);
      canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.stone
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
      if (a.center.dy == b.center.dy) {
        _arrow(canvas, Offset(a.center.dx, a.bottom + 2), Offset(a.center.dx, a.bottom + 2));
      }
    }
    for (var i = 0; i < n; i++) {
      final r = box(i);
      final on = hp?.stage == i;
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..color = on ? AppColors.sunflower : const Color(0xFFF3EEE4));
      if (on) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(14)),
            Paint()
              ..color = AppColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2);
      }
      canvas.drawCircle(r.topLeft + const Offset(12, 12), 9, Paint()..color = AppColors.ink);
      ChartLayout.text(canvas, '${i + 1}', r.topLeft + const Offset(12, 12), size: 10, color: Colors.white, weight: FontWeight.w600, anchor: Alignment.center);
      final icon = processIcons[c.stages[i].icon];
      if (icon != null) {
        final tp = TextPainter(
          text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: 20, fontFamily: icon.fontFamily, package: icon.fontPackage, color: AppColors.cocoa)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.top + 6));
      }
      ChartLayout.text(canvas, c.stages[i].label, Offset(r.center.dx, r.top + (icon != null ? 30 : 22)),
          size: 10, color: AppColors.ink, anchor: Alignment.topCenter, maxWidth: r.width - 8, align: TextAlign.center);
    }
  }
}

// ---------------------------------------------------------------- mixed

class _MixedLayout extends ChartLayout {
  _MixedLayout(this.c, super.size) {
    var y = 0.0;
    for (final sub in c.charts) {
      final h = ChartLayout.heightFor(sub, size.width);
      y += 16;
      offsets.add(Offset(0, y));
      subs.add(ChartLayout.of(sub, Size(size.width, h)));
      y += h + 14;
    }
  }

  final MixedChartData c;
  final subs = <ChartLayout>[];
  final offsets = <Offset>[];

  @override
  Iterable<String> get partIds => subs.expand((s) => s.partIds);

  @override
  Offset? anchor(String id) {
    for (var i = 0; i < subs.length; i++) {
      final a = subs[i].anchor(id);
      if (a != null) return a + offsets[i];
    }
    return null;
  }

  @override
  String? hitTest(Offset p) {
    for (var i = subs.length - 1; i >= 0; i--) {
      if (p.dy >= offsets[i].dy) return subs[i].hitTest(p - offsets[i]);
    }
    return null;
  }

  @override
  void paint(Canvas canvas, {String? highlight, bool dimOthers = false}) {
    for (var i = 0; i < subs.length; i++) {
      canvas.save();
      canvas.translate(offsets[i].dx, offsets[i].dy);
      subs[i].paint(canvas, highlight: highlight, dimOthers: dimOthers);
      canvas.restore();
      ChartLayout.text(canvas, c.charts[i].title, Offset(0, offsets[i].dy - 16), size: 11, color: AppColors.ink, weight: FontWeight.w600, maxWidth: size.width);
      if (i > 0) {
        canvas.drawLine(Offset(0, offsets[i].dy - 22), Offset(size.width, offsets[i].dy - 22), Paint()..color = AppColors.line);
      }
    }
  }
}
