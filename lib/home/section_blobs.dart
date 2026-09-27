import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/vocab_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

/// Mockup-4 style tile board: pill-shaped cells joined into L-shapes and circles,
/// on a 4 x 3 grid. Each tile opens a section.
class SectionBlobs extends StatelessWidget {
  const SectionBlobs({super.key, required this.sections, required this.totalSections, required this.onOpen});

  final Map<String, VocabSection> sections;
  final int totalSections;
  final void Function(String? code) onOpen;

  static const gap = 6.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cell = (c.maxWidth - gap * 3) / 4;
      double x(int col) => col * (cell + gap);
      double y(int row) => row * (cell + gap);
      Rect r(int col, int row, [int w = 1, int h = 1]) =>
          Rect.fromLTWH(x(col), y(row), cell * w + gap * (w - 1), cell * h + gap * (h - 1));

      final tiles = [
        _Tile('A2', AppColors.peach, const Color(0xFFF3CDAA), [r(0, 0, 2), r(1, 0, 1, 2)], labelCell: r(1, 0), mascotCell: r(0, 0), countCell: r(1, 1)),
        _Tile('A3', AppColors.sunflower, null, [r(0, 1)], mascotCell: r(0, 1)),
        _Tile('B1', AppColors.lilac, const Color(0xFFE9E4FD), [r(2, 0, 2), r(3, 0, 1, 2)], labelCell: r(3, 0), mascotCell: r(2, 0), countCell: r(3, 1)),
        _Tile('B2', AppColors.blush, null, [r(2, 1)], mascotCell: r(2, 1)),
        _Tile('C', const Color(0xFFB9CB7C), null, [r(0, 2, 2)], labelCell: r(1, 2), mascotCell: r(0, 2)),
      ];
      final all = r(2, 2, 2);

      return SizedBox(
        width: c.maxWidth,
        height: y(3) - gap,
        child: Stack(
          children: [
            for (final (i, t) in tiles.indexed) ..._tileWidgets(context, t, i),
            Positioned.fromRect(
              rect: all,
              child: Pressable(
                onTap: () => onOpen(null),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(cell)),
                  alignment: Alignment.center,
                  child: Text('All $totalSections  →', style: const TextStyle(color: AppColors.sunflower, fontSize: 17, fontWeight: FontWeight.w500)),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 350.ms).scaleXY(begin: .9, end: 1, curve: Curves.easeOutBack),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _tileWidgets(BuildContext context, _Tile t, int index) {
    final s = sections[t.code]!;
    final bounds = t.pills.reduce((a, b) => a.expandToInclude(b));
    Rect local(Rect rr) => rr.shift(-bounds.topLeft);
    final radius = t.mascotCell.shortestSide / 2;

    return [
      Positioned.fromRect(
        rect: bounds,
        child: Pressable(
          onTap: () => onOpen(t.code),
          child: CustomPaint(
            painter: _PillPainter([for (final p in t.pills) local(p)], radius, t.color, t.band),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: local(t.mascotCell).deflate(t.pills.length == 1 && t.labelCell == null ? 8 : 6),
                  child: MascotImage(Mascot.forSection(t.code), size: t.mascotCell.width),
                ),
                if (t.labelCell != null)
                  Positioned.fromRect(
                    rect: local(t.labelCell!).deflate(6),
                    child: Align(
                      alignment: t.countCell == null ? Alignment.centerLeft : Alignment.bottomLeft,
                      child: Text(
                        _short(s),
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.1, color: AppColors.ink),
                      ),
                    ),
                  ),
                if (t.countCell != null)
                  Positioned.fromRect(
                    rect: local(t.countCell!),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${s.wordCount}',
                            style: TextStyle(fontSize: t.countCell!.width * .56, fontWeight: FontWeight.w300, height: .95, color: AppColors.ink.withValues(alpha: .78))),
                        Text('words', style: TextStyle(fontSize: 11.5, color: AppColors.ink.withValues(alpha: .65))),
                        SizedBox(height: t.countCell!.width * .2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ).animate(delay: (index * 70).ms).fadeIn(duration: 350.ms).scaleXY(begin: .9, end: 1, curve: Curves.easeOutBack),
      ),
    ];
  }

  static String _short(VocabSection s) => switch (s.code) {
        'A2' => 'Going\nup',
        'A3' => 'Going down',
        'B1' => 'Academic\nwords',
        'B2' => 'Cause &\neffect',
        'C' => 'Linking\nwords',
        _ => s.title,
      };
}

class _Tile {
  _Tile(this.code, this.color, this.band, this.pills, {required this.mascotCell, this.labelCell, this.countCell});
  final String code;
  final Color color;
  final Color? band;
  final List<Rect> pills;
  final Rect mascotCell;
  final Rect? labelCell;
  final Rect? countCell;
}

class _PillPainter extends CustomPainter {
  _PillPainter(this.pills, this.radius, this.color, this.band);
  final List<Rect> pills;
  final double radius;
  final Color color;
  final Color? band;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    for (final p in pills) {
      path = Path.combine(PathOperation.union, path, Path()..addRRect(RRect.fromRectAndRadius(p, Radius.circular(radius))));
    }
    canvas.drawPath(path, Paint()..color = color);
    if (band != null) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, radius * .5), Paint()..color = band!);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.color != color || old.pills != pills;
}
