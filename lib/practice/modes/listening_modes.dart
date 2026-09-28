import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/listening_models.dart';
import '../../services/speech.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';

/// A "hear it" pill that speaks [text] aloud (or just shows it, if TTS is off).
class HearIt extends StatelessWidget {
  const HearIt(this.text, {super.key, this.slow = false});
  final String text;
  final bool slow;

  @override
  Widget build(BuildContext context) => TagChip(
        '🔊 Hear it',
        color: AppColors.card,
        onTap: () => Speech.instance.speak(text, slow: slow),
      );
}

// ------------------------------------------------------------ Shared map canvas

/// Draws a [ListeningMap] (paths, areas, buildings and spots are all stored
/// as 0..1 fractions of the canvas, so this scales to any box).
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.map,
    this.highlightSpot,
    this.correctSpot,
    this.wrongSpot,
    this.routePath,
    this.routeProgress = 1,
    this.onTapSpot,
    this.height = 290,
  });

  final ListeningMap map;
  final String? highlightSpot;
  final String? correctSpot;
  final String? wrongSpot;
  final List<Offset>? routePath;
  final double routeProgress;
  final ValueChanged<String>? onTapSpot;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: LayoutBuilder(builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          onTapUp: onTapSpot == null
              ? null
              : (d) {
                  for (final s in map.spots) {
                    final r = Rect.fromLTWH(s.rect.left * size.width, s.rect.top * size.height, s.rect.width * size.width, s.rect.height * size.height);
                    if (r.inflate(6).contains(d.localPosition)) {
                      onTapSpot!(s.letter);
                      return;
                    }
                  }
                },
          child: CustomPaint(
            size: size,
            painter: _MapPainter(map, highlightSpot: highlightSpot, correctSpot: correctSpot, wrongSpot: wrongSpot, routePath: routePath, routeProgress: routeProgress),
          ),
        );
      }),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.map, {this.highlightSpot, this.correctSpot, this.wrongSpot, this.routePath, this.routeProgress = 1});
  final ListeningMap map;
  final String? highlightSpot, correctSpot, wrongSpot;
  final List<Offset>? routePath;
  final double routeProgress;

  Offset _p(Offset frac, Size size) => Offset(frac.dx * size.width, frac.dy * size.height);
  Rect _r(Rect frac, Size size) => Rect.fromLTWH(frac.left * size.width, frac.top * size.height, frac.width * size.width, frac.height * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)), Paint()..color = const Color(0xFFEFF3E1));

    // Areas (woodland, water, etc.) as soft rounded shapes.
    for (final a in map.areas) {
      final rect = _r(a.rect, size);
      final color = switch (a.kind) {
        'water' || 'pond' || 'lake' => const Color(0xFFBFDCEB),
        'woodland' || 'trees' => const Color(0xFFC7D9A6),
        _ => const Color(0xFFE3DFD6),
      };
      final paint = Paint()..color = color;
      if (a.oval) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), paint);
      }
      if (a.label.isNotEmpty) {
        // Put the area name where it doesn't sit under an answer letter.
        final spots = [for (final sp in map.spots) _r(sp.rect, size).inflate(4)];
        final tp = _layout(a.label, const Color(0xFF4A5A2E), 10, maxWidth: rect.width - 6);
        final candidates = [
          Offset(rect.center.dx, rect.top + tp.height / 2 + 4),
          Offset(rect.center.dx, rect.bottom - tp.height / 2 - 4),
          rect.center,
          Offset(rect.right - tp.width / 2 - 6, rect.center.dy),
          Offset(rect.left + tp.width / 2 + 6, rect.center.dy),
        ];
        final at = candidates.firstWhere(
          (c) => !spots.any((sp) => sp.overlaps(Rect.fromCenter(center: c, width: tp.width, height: tp.height))),
          orElse: () => candidates.first,
        );
        tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Paths.
    for (final p in map.paths) {
      if (p.points.length < 2) continue;
      final path = Path()..moveTo(_p(p.points.first, size).dx, _p(p.points.first, size).dy);
      for (final pt in p.points.skip(1)) {
        final o = _p(pt, size);
        path.lineTo(o.dx, o.dy);
      }
      final paint = Paint()
        ..color = const Color(0xFFD2C6B8)
        ..strokeWidth = p.kind == 'road' ? 8 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }

    // Buildings.
    for (final b in map.buildings) {
      final rect = _r(b.rect, size);
      // Grow the building to fit its name (two lines at most), so labels are
      // never clipped white-on-cream.
      final tp = _layout(b.label, Colors.white, 9, maxWidth: (rect.width * 1.5).clamp(48.0, 84.0));
      var box = Rect.fromCenter(center: rect.center, width: (tp.width + 10).clamp(rect.width, 96.0), height: (tp.height + 6).clamp(rect.height, 40.0));
      box = box.shift(Offset(
        box.left < 2 ? 2 - box.left : (box.right > size.width - 2 ? size.width - 2 - box.right : 0),
        box.top < 2 ? 2 - box.top : (box.bottom > size.height - 2 ? size.height - 2 - box.bottom : 0),
      ));
      canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(7)), Paint()..color = const Color(0xFF73443A));
      tp.paint(canvas, box.center - Offset(tp.width / 2, tp.height / 2));
    }

    // Spots (lettered answer targets).
    for (final s in map.spots) {
      final rect = _r(s.rect, size);
      final isHi = s.letter == highlightSpot;
      final isRight = s.letter == correctSpot;
      final isWrong = s.letter == wrongSpot;
      final fill = isRight
          ? AppColors.olive
          : isWrong
              ? AppColors.rust
              : (isHi ? AppColors.sunflower : Colors.white);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF1D1D1D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      _label(canvas, s.letter, rect.center, isRight || isWrong ? Colors.white : const Color(0xFF1D1D1D), 13, bold: true);
    }

    // Start marker.
    final start = _p(map.start, size);
    canvas.drawCircle(start, 6, Paint()..color = const Color(0xFF1D1D1D));
    final st = _layout(map.startLabel, const Color(0xFF1D1D1D), 9, bold: true);
    st.paint(canvas, Offset((start.dx + 10).clamp(0, size.width - st.width), start.dy - st.height / 2));

    // Route (drawn progressively as routeProgress goes 0 → 1).
    final r = routePath;
    if (r != null && r.length >= 2) {
      final pts = [for (final o in r) _p(o, size)];
      var remaining = routeProgress * _pathLength(pts);
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length && remaining > 0; i++) {
        final seg = (pts[i] - pts[i - 1]).distance;
        if (seg <= remaining) {
          path.lineTo(pts[i].dx, pts[i].dy);
          remaining -= seg;
        } else {
          final t = seg == 0 ? 0.0 : remaining / seg;
          path.lineTo(pts[i - 1].dx + (pts[i].dx - pts[i - 1].dx) * t, pts[i - 1].dy + (pts[i].dy - pts[i - 1].dy) * t);
          remaining = 0;
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.rust
          ..strokeWidth = 3.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  double _pathLength(List<Offset> pts) {
    var d = 0.0;
    for (var i = 1; i < pts.length; i++) {
      d += (pts[i] - pts[i - 1]).distance;
    }
    return d;
  }

  TextPainter _layout(String text, Color color, double size, {bool bold = false, double maxWidth = 90}) => TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, height: 1.1, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontFamily: 'Outfit')),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: maxWidth < 20 ? 20 : maxWidth);

  void _label(Canvas canvas, String text, Offset center, Color color, double size, {bool bold = false}) {
    final tp = _layout(text, color, size, bold: bold);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.map != map || old.highlightSpot != highlightSpot || old.correctSpot != correctSpot || old.wrongSpot != wrongSpot || old.routeProgress != routeProgress;
}

// ------------------------------------------------------------ Where is it?

class WhereView extends StatefulWidget {
  const WhereView(this.q, {super.key});
  final WhereQ q;
  @override
  State<WhereView> createState() => _WhereViewState();
}

class _WhereViewState extends State<WhereView> {
  String? _picked;
  bool _done = false;

  Future<void> _tap(String letter) async {
    if (_done) return;
    setState(() {
      _picked = letter;
      _done = true;
    });
    final ok = letter == widget.q.q.answer;
    final c = sessionOf(context);
    await c.record(widget.q.q.id, correct: ok);
    if (!mounted) return;
    final spot = widget.q.map.spot(widget.q.q.answer);
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Found it!', body: widget.q.q.explain)
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: '${spot.letter} · ${spot.name}', body: widget.q.q.explain));
  }

  @override
  Widget build(BuildContext context) {
    return SessionFrame(
      color: const Color(0xFF9CC7E4),
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PromptCard(
          child: Row(children: [
            Expanded(child: Text('“${widget.q.q.line}”', style: const TextStyle(fontSize: 16.5, height: 1.4))),
            const SizedBox(width: 8),
            HearIt(widget.q.q.line),
          ]),
        ),
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(2, 8, 0, 10), child: Text('Tap the spot on the map.', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5))),
          MapCanvas(
            map: widget.q.map,
            correctSpot: _done ? widget.q.q.answer : null,
            wrongSpot: _done && _picked != widget.q.q.answer ? _picked : null,
            onTapSpot: _tap,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Picture it

class PictureView extends StatefulWidget {
  const PictureView(this.q, {super.key});
  final PictureQ q;
  @override
  State<PictureView> createState() => _PictureViewState();
}

class _PictureViewState extends State<PictureView> {
  int? _picked;

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final o = widget.q.options[i];
    final ok = o.id == widget.q.item.id;
    final c = sessionOf(context);
    await c.record(widget.q.item.id, correct: ok);
    if (!mounted) return;
    c.answer(ok
        ? const AnswerFeedback(Verdict.right, 'That’s it')
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: widget.q.item.term, body: widget.q.item.explanation));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.q.item;
    return SessionFrame(
      color: AppColors.lilac,
      header: PromptCard(
        child: Row(children: [
          Expanded(child: Text('“${item.speakerLine}”', style: const TextStyle(fontSize: 16.5, height: 1.4))),
          const SizedBox(width: 8),
          HearIt(item.speakerLine),
        ]),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(2, 8, 0, 10), child: Text('Which picture matches?', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5))),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .95,
            children: [
              for (final (i, o) in widget.q.options.indexed)
                GestureDetector(
                  onTap: () => _pick(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _picked == null
                            ? Colors.transparent
                            : (o.id == item.id ? AppColors.olive : (i == _picked ? AppColors.rust : Colors.transparent)),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: CustomPaint(painter: _DiagramPainter(o.diagram))),
                        const SizedBox(height: 6),
                        Text(o.term, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small schematic icon for a direction/position diagram key (e.g.
/// "opposite", "t-junction", "compass-ne"). Falls back to a plain dot label
/// for any key this doesn't recognise by name, so new content never crashes.
class _DiagramPainter extends CustomPainter {
  _DiagramPainter(this.key_);
  final String key_;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = AppColors.rust;
    final r = size.shortestSide / 2 - 4;

    void marker(Offset o) => canvas.drawCircle(o, 4.5, dot);

    if (key_.startsWith('compass')) {
      canvas.drawCircle(c, r, ink);
      final dir = key_.split('-').skip(1).join('-');
      final angle = switch (dir) {
        'n' => -1.5708,
        'ne' => -0.7854,
        'e' => 0.0,
        'se' => 0.7854,
        's' => 1.5708,
        'sw' => 2.3562,
        'w' => 3.1416,
        'nw' => -2.3562,
        _ => -1.5708,
      };
      final tip = Offset(c.dx + r * 0.8 * math.cos(angle), c.dy + r * 0.8 * math.sin(angle));
      canvas.drawLine(c, tip, ink..strokeWidth = 3);
      marker(tip);
    } else if (key_ == 'opposite') {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ink);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx - r, c.dy), width: 10, height: 10), dot);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx + r, c.dy), width: 10, height: 10), Paint()..color = AppColors.olive);
    } else if (key_ == 'adjacent' || key_ == 'beside' || key_ == 'next-to') {
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx - 10, c.dy), width: 14, height: 14), dot);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx + 10, c.dy), width: 14, height: 14), Paint()..color = AppColors.olive);
    } else if (key_ == 'between') {
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx - r, c.dy), width: 10, height: 10), Paint()..color = AppColors.stone);
      canvas.drawRect(Rect.fromCenter(center: Offset(c.dx + r, c.dy), width: 10, height: 10), Paint()..color = AppColors.stone);
      canvas.drawCircle(c, 6, dot);
    } else if (key_.contains('t-junction')) {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ink);
      canvas.drawLine(c, Offset(c.dx, c.dy - r), ink);
    } else if (key_.contains('crossroads')) {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ink);
      canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), ink);
    } else if (key_.contains('roundabout')) {
      canvas.drawCircle(c, r * 0.4, ink);
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx - r * 0.4, c.dy), ink);
      canvas.drawLine(Offset(c.dx + r * 0.4, c.dy), Offset(c.dx + r, c.dy), ink);
      canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy - r * 0.4), ink);
    } else if (key_.contains('fork')) {
      canvas.drawLine(Offset(c.dx, c.dy + r), c, ink);
      canvas.drawLine(c, Offset(c.dx - r * .7, c.dy - r), ink);
      canvas.drawLine(c, Offset(c.dx + r * .7, c.dy - r), ink);
    } else if (key_.contains('bend') || key_.contains('curve')) {
      final path = Path()
        ..moveTo(c.dx - r, c.dy + r * .6)
        ..quadraticBezierTo(c.dx - r * .2, c.dy - r * .6, c.dx + r, c.dy - r * .6);
      canvas.drawPath(path, ink);
    } else if (key_.contains('dead-end') || key_.contains('deadend')) {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r * .3, c.dy), ink);
      canvas.drawLine(Offset(c.dx + r * .3, c.dy - 8), Offset(c.dx + r * .3, c.dy + 8), ink..strokeWidth = 3);
    } else if (key_.contains('corner')) {
      canvas.drawLine(Offset(c.dx - r, c.dy + r), Offset(c.dx - r, c.dy - r), ink);
      canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy - r), ink);
      marker(Offset(c.dx - r, c.dy - r));
    } else if (key_.contains('far-end') || key_.contains('far end')) {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ink);
      marker(Offset(c.dx + r, c.dy));
    } else if (key_.contains('arrow')) {
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), ink..strokeWidth = 3);
      canvas.drawLine(Offset(c.dx + r, c.dy), Offset(c.dx + r - 8, c.dy - 7), ink);
      canvas.drawLine(Offset(c.dx + r, c.dy), Offset(c.dx + r - 8, c.dy + 7), ink);
    } else {
      // Generic fallback: a simple location pin.
      canvas.drawCircle(c.translate(0, -4), r * 0.55, dot);
      canvas.drawLine(c.translate(0, r * 0.1), c.translate(0, r * 0.9), ink);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter old) => old.key_ != key_;
}

/// Public wrapper so other screens (e.g. listening flashcards) can show the
/// same schematic diagram as "Picture it".
class DiagramIcon extends StatelessWidget {
  const DiagramIcon(this.diagram, {super.key, this.size = 90});
  final String diagram;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _DiagramPainter(diagram)));
}

// ------------------------------------------------------------ Follow the route

class RouteView extends StatefulWidget {
  const RouteView(this.q, {super.key});
  final RouteQ q;
  @override
  State<RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<RouteView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  bool _walked = false;
  String? _picked;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _walk() {
    if (_walked) return;
    setState(() => _walked = true);
    _ctl.forward(from: 0);
  }

  Future<void> _tap(String letter) async {
    if (!_walked || _done) return;
    setState(() {
      _picked = letter;
      _done = true;
    });
    final ok = letter == widget.q.q.answer;
    final c = sessionOf(context);
    await c.record(widget.q.q.id, correct: ok);
    if (!mounted) return;
    final spot = widget.q.map.spot(widget.q.q.answer);
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'You followed it!', body: widget.q.q.explain)
        : AnswerFeedback(Verdict.wrong, 'Not quite where you end up', answer: '${spot.letter} · ${spot.name}', body: widget.q.q.explain));
  }

  @override
  Widget build(BuildContext context) {
    return SessionFrame(
      color: const Color(0xFFB9CB7C),
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PromptCard(
          child: Row(children: [
            Expanded(child: Text('“${widget.q.q.line}”', style: const TextStyle(fontSize: 15.5, height: 1.4))),
            const SizedBox(width: 8),
            HearIt(widget.q.q.line),
          ]),
        ),
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 10),
            child: Text(_walked ? 'Where do you end up?' : 'Walk the route, then tap where you end up.', style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
          ),
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) => MapCanvas(
              map: widget.q.map,
              routePath: widget.q.q.path,
              routeProgress: _walked ? _ctl.value : 0,
              correctSpot: _done ? widget.q.q.answer : null,
              wrongSpot: _done && _picked != widget.q.q.answer ? _picked : null,
              onTapSpot: _walked ? _tap : null,
            ),
          ),
        ],
      ),
      bottom: _walked ? null : PillButton('Walk the route', onTap: _walk),
    );
  }
}

// ------------------------------------------------------------ Spell it

class SpellView extends StatefulWidget {
  const SpellView(this.q, {super.key});
  final SpellQ q;
  @override
  State<SpellView> createState() => _SpellViewState();
}

class _SpellViewState extends State<SpellView> {
  final _ctl = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_done || _ctl.text.trim().isEmpty) return;
    setState(() => _done = true);
    final item = widget.q.item;
    final ok = _norm(_ctl.text) == _norm(item.term);
    final c = sessionOf(context);
    await c.record(item.id, correct: ok, typed: true);
    if (!mounted) return;
    c.answer(ok ? const AnswerFeedback(Verdict.right, 'Spelt right!') : AnswerFeedback(Verdict.wrong, 'Not quite', answer: item.term));
  }

  String _norm(String s) => s.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Speech.instance.speak(widget.q.item.term));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.q.item;
    return SessionFrame(
      color: AppColors.peach,
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Listen, then spell the place word.', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
        const SizedBox(height: 10),
        PromptCard(
          child: Row(children: [
            Expanded(child: Text(item.explanation, style: const TextStyle(fontSize: 15.5, height: 1.4))),
            const SizedBox(width: 8),
            HearIt(item.term, slow: true),
          ]),
        ),
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctl,
            autofocus: true,
            enabled: !_done,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _check(),
            style: const TextStyle(fontSize: 21),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              hintText: 'type what you heard',
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
            ),
          ),
        ],
      ),
      bottom: ListenableBuilder(listenable: _ctl, builder: (_, _) => PillButton('Check', onTap: _ctl.text.trim().isEmpty || _done ? null : _check)),
    );
  }
}

// ------------------------------------------------------------ Trap drill

class TrapView extends StatefulWidget {
  const TrapView(this.q, {super.key});
  final TrapQ q;
  @override
  State<TrapView> createState() => _TrapViewState();
}

class _TrapViewState extends State<TrapView> {
  int? _picked;

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final ok = i == widget.q.q.answer;
    final c = sessionOf(context);
    await c.record(widget.q.q.id, correct: ok);
    if (!mounted) return;
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'You caught the correction', body: widget.q.q.why)
        : AnswerFeedback(Verdict.wrong, 'Listen for the correction', answer: widget.q.q.options[widget.q.q.answer], body: widget.q.q.why));
  }

  @override
  Widget build(BuildContext context) {
    return SessionFrame(
      color: AppColors.blush,
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PromptCard(
          child: Row(children: [
            Expanded(child: Text('“${widget.q.q.line}”', style: const TextStyle(fontSize: 15.5, height: 1.4))),
            const SizedBox(width: 8),
            HearIt(widget.q.q.line),
          ]),
        ),
        const SizedBox(height: 12),
        Text(widget.q.q.question, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, o) in widget.q.q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerCard(
                text: o,
                onTap: () => _pick(i),
                state: _picked == null ? AnswerState.idle : (i == widget.q.q.answer ? AnswerState.right : (i == _picked ? AnswerState.wrong : AnswerState.idle)),
              ),
            ),
        ],
      ),
    );
  }
}
