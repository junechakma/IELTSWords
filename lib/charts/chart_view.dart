import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/chart_models.dart';
import '../theme/app_theme.dart';
import 'chart_layout.dart';

/// Draws any sample chart. Optionally highlights one part, puts word labels on
/// parts (the annotated Learn chart) and reports taps on parts.
class ChartView extends StatelessWidget {
  const ChartView({
    super.key,
    required this.chart,
    this.highlight,
    this.labels = const {},
    this.selected,
    this.onTapPart,
    this.dimOthers = false,
    this.showTitle = true,
    this.labelHeadroom = 0,
    this.focusMap = false,
  });

  final ChartData chart;
  final String? highlight;

  /// part id → label text drawn on the chart.
  final Map<String, String> labels;

  /// Label drawn as selected (dark chip).
  final String? selected;
  final ValueChanged<String>? onTapPart;
  final bool dimOthers;
  final bool showTitle;

  /// Extra space around the chart so labels can sit outside the plot.
  final double labelHeadroom;

  /// For a before / after map with a [highlight], show only the half that
  /// holds it, so the chart fits above a practice question.
  final bool focusMap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final pad = labels.isEmpty ? 0.0 : labelHeadroom;
      final w = c.maxWidth;
      final part = highlight ?? selected;
      final side = focusMap && chart is MapChartData && part != null ? chart.part(part)?.map : null;
      final h = ChartLayout.heightFor(chart, w, mapSide: side);
      final layout = ChartLayout.of(chart, Size(w, h), mapSide: side);
      final placed = _placeLabels(layout, Size(w, h + pad * 2), pad);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle && chart.title.isNotEmpty && chart is! MixedChartData)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(chart.title, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
            ),
          SizedBox(
            width: w,
            height: h + pad * 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: onTapPart == null
                  ? null
                  : (d) {
                      final id = layout.hitTest(d.localPosition - Offset(0, pad));
                      if (id != null) onTapPart!(id);
                    },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: pad,
                    width: w,
                    height: h,
                    child: CustomPaint(painter: _ChartPainter(layout, highlight ?? selected, dimOthers)),
                  ),
                  if (placed.isNotEmpty)
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _LeaderPainter(placed)))),
                  for (final p in placed)
                    Positioned(
                      left: p.rect.left,
                      top: p.rect.top,
                      child: GestureDetector(
                        onTap: onTapPart == null ? null : () => onTapPart!(p.id),
                        child: Container(
                          width: p.rect.width,
                          height: p.rect.height,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.id == selected ? AppColors.ink : Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: p.id == selected ? AppColors.ink : AppColors.line),
                            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
                          ),
                          child: Text(p.text, maxLines: 1, style: _labelStyle.copyWith(color: p.id == selected ? Colors.white : AppColors.ink)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  static final _labelStyle = GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.1);

  List<_Placed> _placeLabels(ChartLayout layout, Size box, double pad) {
    if (labels.isEmpty) return const [];
    final out = <_Placed>[];
    final taken = <Rect>[];
    for (final e in labels.entries) {
      final a = layout.anchor(e.key);
      if (a == null) continue;
      final anchor = a + Offset(0, pad);
      final tp = TextPainter(text: TextSpan(text: e.value, style: _labelStyle), textDirection: TextDirection.ltr, maxLines: 1)..layout();
      final w = tp.width + 14, h = tp.height + 8;
      final candidates = [
        Offset(-w / 2, -h - 14),
        Offset(-w / 2, 14),
        Offset(12, -h / 2),
        Offset(-w - 12, -h / 2),
        Offset(8, -h - 12),
        Offset(-w - 8, -h - 12),
        Offset(8, 12),
        Offset(-w - 8, 12),
        Offset(-w / 2, -h - 36),
        Offset(-w / 2, 36),
        Offset(-w / 2, -h / 2),
      ];
      Rect? pick;
      for (final c in candidates) {
        var r = (anchor + c) & Size(w, h);
        r = r.shift(Offset(
          r.left < 0 ? -r.left : (r.right > box.width ? box.width - r.right : 0),
          r.top < 0 ? -r.top : (r.bottom > box.height ? box.height - r.bottom : 0),
        ));
        if (!taken.any((t) => t.inflate(2).overlaps(r))) {
          pick = r;
          break;
        }
      }
      pick ??= ((anchor + candidates.first) & Size(w, h)).shift(Offset(0, math.max(0, -(anchor.dy - h - 14))));
      taken.add(pick);
      out.add(_Placed(e.key, e.value, pick, anchor));
    }
    return out;
  }
}

class _Placed {
  const _Placed(this.id, this.text, this.rect, this.anchor);
  final String id, text;
  final Rect rect;
  final Offset anchor;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.layout, this.highlight, this.dim);
  final ChartLayout layout;
  final String? highlight;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) => layout.paint(canvas, highlight: highlight, dimOthers: dim);

  @override
  bool shouldRepaint(_ChartPainter old) => old.highlight != highlight || old.layout.size != layout.size || old.layout != layout;
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.placed);
  final List<_Placed> placed;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.ink.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (final p in placed) {
      final r = p.rect;
      final target = Offset(p.anchor.dx.clamp(r.left, r.right), p.anchor.dy.clamp(r.top, r.bottom));
      if ((target - p.anchor).distance > 3) canvas.drawLine(target, p.anchor, line);
      canvas.drawCircle(p.anchor, 3, Paint()..color = AppColors.ink);
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => true;
}
