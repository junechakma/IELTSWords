
import 'package:flutter/material.dart';

import '../../charts/cartography.dart';

import '../../data/listening_models.dart';
import '../../library/map_set_screen.dart';
import '../../services/speech.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/diagram.dart';
import '../../widgets/shapes.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';

// ------------------------------------------------------------ Real map gaps

/// A real exam map (zoomable) and one sentence about it with the key word
/// gapped; tap the word that fits.
class MapGapView extends StatefulWidget {
  const MapGapView(this.q, {super.key});
  final MapGapQ q;
  @override
  State<MapGapView> createState() => _MapGapViewState();
}

class _MapGapViewState extends State<MapGapView> {
  String? _picked;

  Future<void> _pick(String o) async {
    if (_picked != null) return;
    setState(() => _picked = o);
    final s = widget.q.sentence;
    final ok = o == s.term;
    final c = sessionOf(context);
    await c.record(s.id, correct: ok);
    if (!mounted) return;
    if (ok) Speech.instance.speak(s.text);
    final w = widget.q.set.word(s.term);
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Yes — “${s.term}”', body: w?.meaning)
        : AnswerFeedback(Verdict.wrong, 'Look at the map again', answer: s.term, body: w?.meaning));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.sentence;
    final (before, term, after) = s.parts;
    return SessionFrame(
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExamMap(image: widget.q.set.image, height: 220),
        const SizedBox(height: 4),
        Text(widget.q.set.place, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14 + 12),
          decoration: const ShapeDecoration(color: Colors.white, shape: BubbleBorder(tailAt: 30)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text.rich(TextSpan(style: const TextStyle(fontSize: 18, height: 1.45, color: AppColors.ink), children: [
                TextSpan(text: before),
                TextSpan(
                  text: _picked == null ? ' ________ ' : term,
                  style: TextStyle(fontWeight: FontWeight.w700, backgroundColor: _picked == null ? null : const Color(0xFFFDE6B0)),
                ),
                TextSpan(text: after),
              ])),
            ),
            HearIt(_picked == null ? '$before … $after' : s.text),
          ]),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 12, children: [
          for (final (i, o) in widget.q.options.indexed)
            GestureDetector(
              onTap: () => _pick(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: ShapeDecoration(
                  color: _picked == null
                      ? AppColors.card
                      : (o == s.term ? const Color(0xFFE6EDCF) : (o == _picked ? const Color(0xFFFBEAE5) : AppColors.card)),
                  shape: PebbleBorder(seed: i + 3, side: BorderSide(color: o == _picked ? AppColors.ink : Colors.transparent, width: 2)),
                ),
                child: Text(o, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ]),
    );
  }
}

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
    final bounds = Offset.zero & size;
    final frame = RRect.fromRectAndRadius(bounds, const Radius.circular(18));
    canvas.save();
    canvas.clipRRect(frame);
    Carto.ground(canvas, frame);

    // Ground: woodland, water, car parks, gardens.
    for (final a in map.areas) {
      Carto.feature(canvas, a.kind, _r(a.rect, size), oval: a.oval);
    }

    // Paths and roads.
    for (final p in map.paths) {
      if (p.points.length < 2) continue;
      final path = Path()..moveTo(_p(p.points.first, size).dx, _p(p.points.first, size).dy);
      for (final pt in p.points.skip(1)) {
        final o = _p(pt, size);
        path.lineTo(o.dx, o.dy);
      }
      if (p.kind == 'road') {
        Carto.road(canvas, path, 12);
      } else {
        Carto.footpath(canvas, path, 7);
      }
    }

    // Buildings (named) and spots (the lettered answers) stand on the paths.
    for (final b in map.buildings) {
      Carto.building(canvas, _r(b.rect, size));
    }
    final spotRects = <Rect>[];
    for (final s in map.spots) {
      final rect = _r(s.rect, size);
      spotRects.add(rect.inflate(1));
      final isRight = s.letter == correctSpot, isWrong = s.letter == wrongSpot, isHi = s.letter == highlightSpot;
      final (top, side) = isRight
          ? (AppColors.olive, const Color(0xFF6B8229))
          : isWrong
              ? (AppColors.rust, const Color(0xFFA8432A))
              : isHi
                  ? (AppColors.sunflower, const Color(0xFFD99A12))
                  : (Colors.white, const Color(0xFFCFC6B6));
      Carto.building(canvas, rect, top: top, side: side);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      _label(canvas, s.letter, rect.center - const Offset(0, 1.5), isRight || isWrong ? Colors.white : AppColors.ink, 14, bold: true);
    }

    // Route (drawn progressively as routeProgress goes 0 → 1), under labels.
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
      Paint pen(Color c, double w) => Paint()
        ..color = c
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, pen(Colors.white, 7));
      canvas.drawPath(path, pen(AppColors.ink, 3.4));
    }

    // Start marker.
    final start = _p(map.start, size);
    Carto.you(canvas, start, 5);

    // Labels last, kept off the answer letters and each other.
    final taken = [...spotRects, Rect.fromCircle(center: Offset(size.width - 18, 22), radius: 16), Rect.fromCircle(center: start, radius: 9)];
    // Building names sit on the building itself so it's clear which is which.
    for (final b in map.buildings) {
      Carto.label(canvas, b.label, _r(b.rect, size), bounds, taken, onTop: true);
    }
    for (final a in map.areas) {
      if (a.label.isNotEmpty) Carto.label(canvas, a.label, _r(a.rect, size), bounds, taken);
    }
    if (map.startLabel.isNotEmpty) {
      Carto.label(canvas, map.startLabel, Rect.fromCenter(center: start, width: 12, height: 12), bounds, taken, bold: true);
    }
    Carto.compass(canvas, Offset(size.width - 18, 24), 8);
    canvas.restore();
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
                        Expanded(child: LayoutBuilder(builder: (context, c) => DiagramIcon(o.diagram, size: c.biggest.shortestSide))),
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
