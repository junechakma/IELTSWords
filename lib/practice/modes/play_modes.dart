import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../mascots/mascot.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';
import 'game_modes.dart';

// ================================================================ Draw the trend

/// See a trend word, draw the line it describes with your finger. Checks
/// direction and steepness (or flatness / waves) and overlays the right
/// shape, so the word and the picture connect.
class DrawView extends StatefulWidget {
  const DrawView(this.q, {super.key});
  final DrawQ q;
  @override
  State<DrawView> createState() => _DrawViewState();
}

class _DrawViewState extends State<DrawView> {
  final _pts = <Offset>[]; // normalised 0–1
  bool _checked = false;

  double get _startY => switch (widget.q.shape) {
        TrendShape.up => .82,
        TrendShape.down => .18,
        _ => .5,
      };

  /// Expected change in value (0–1 of height) for a strength 1–5 word.
  (double, double) get _band => switch (widget.q.word.strength) {
        1 => (.03, .28),
        2 => (.12, .45),
        3 => (.12, .95),
        4 => (.35, 1),
        _ => (.5, 1),
      };

  void _add(Offset local, Size size) {
    if (_checked) return;
    final n = Offset((local.dx / size.width).clamp(0, 1), (local.dy / size.height).clamp(0, 1));
    if (_pts.isEmpty) {
      setState(() => _pts.addAll([Offset(.04, _startY), Offset(math.max(n.dx, .05), n.dy)]));
      return;
    }
    if (n.dx > _pts.last.dx + .005) setState(() => _pts.add(n));
  }

  Future<void> _check() async {
    final v = [for (final p in _pts) 1 - p.dy];
    final delta = v.last - v.first;
    final range = v.reduce(math.max) - v.reduce(math.min);
    // Direction changes, on a coarse sample so finger jitter doesn't count.
    var reversals = 0, lastSign = 0;
    for (var i = 4; i < v.length; i += 4) {
      final d = v[i] - v[i - 4];
      if (d.abs() < .03) continue;
      final sign = d > 0 ? 1 : -1;
      if (lastSign != 0 && sign != lastSign) reversals++;
      lastSign = sign;
    }
    final (lo, hi) = _band;
    final w = widget.q.word.w;
    final (bool ok, String msg) = switch (widget.q.shape) {
      TrendShape.up when delta <= .05 => (false, 'It should go up.'),
      TrendShape.down when delta >= -.05 => (false, 'It should go down.'),
      TrendShape.up || TrendShape.down when delta.abs() < lo => (false, 'Too gentle — “$w” is a bigger change.'),
      TrendShape.up || TrendShape.down when delta.abs() > hi => (false, 'Too steep — “$w” is a smaller change.'),
      TrendShape.flat when range > .2 => (false, '“$w” means it hardly moves — keep it flat.'),
      TrendShape.wave when reversals < 2 || range < .1 => (false, '“$w” goes up and down several times.'),
      _ => (true, widget.q.word.note ?? 'That’s the shape.'),
    };
    setState(() => _checked = true);
    HapticFeedback.mediumImpact();
    final c = sessionOf(context);
    await c.record('draw-${widget.q.set.id}-$w', correct: ok);
    if (!mounted) return;
    c.answer(AnswerFeedback(ok ? Verdict.right : Verdict.wrong, ok ? 'That’s “$w”!' : 'Not quite', body: ok ? msg : '$msg\n${widget.q.word.note ?? ''}'));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.q.word;
    return SessionFrame(
      header: MascotSays(
        mascot: Mascot.excited,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Draw what this word looks like on a graph:', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text('Sales $w', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ]),
      ),
      body: Column(children: [
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.25,
          child: LayoutBuilder(builder: (context, box) {
            final size = box.biggest;
            return GestureDetector(
              onPanStart: (d) => _add(d.localPosition, size),
              onPanUpdate: (d) => _add(d.localPosition, size),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: CustomPaint(size: size, painter: _DrawPainter(_pts, _startY, _checked ? _model() : null)),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(_pts.isEmpty ? 'Start at the dot and drag to the right →' : (_checked ? 'Dashed line = the right shape' : 'Keep going to the right, then Check'),
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
      ]),
      bottom: Row(children: [
        Expanded(child: PillButton('Clear', outline: true, onTap: _checked || _pts.isEmpty ? null : () => setState(_pts.clear))),
        const SizedBox(width: 10),
        Expanded(child: PillButton('Check', dark: true, onTap: !_checked && _pts.isNotEmpty && _pts.last.dx > .7 ? _check : null)),
      ]),
    );
  }

  /// The expected shape, for the overlay after checking.
  List<Offset> _model() {
    final s = widget.q.word.strength;
    final mag = [.15, .3, .45, .62, .78][(s - 1).clamp(0, 4)];
    return [
      for (var i = 0; i <= 30; i++)
        () {
          final x = .04 + .92 * i / 30;
          final t = i / 30;
          final y = switch (widget.q.shape) {
            TrendShape.up => _startY - mag * Curves.easeInOut.transform(t),
            TrendShape.down => _startY + mag * Curves.easeInOut.transform(t),
            TrendShape.flat => _startY + math.sin(t * 20) * .01,
            TrendShape.wave => _startY + math.sin(t * math.pi * 5) * .18,
          };
          return Offset(x, y);
        }(),
    ];
  }
}

class _DrawPainter extends CustomPainter {
  _DrawPainter(this.pts, this.startY, this.model);
  final List<Offset> pts;
  final double startY;
  final List<Offset>? model;

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(Offset(16, s.height * i / 5), Offset(s.width - 16, s.height * i / 5), grid);
    }
    Path path(List<Offset> l) {
      final p = Path()..moveTo(l.first.dx * s.width, l.first.dy * s.height);
      for (final o in l.skip(1)) {
        p.lineTo(o.dx * s.width, o.dy * s.height);
      }
      return p;
    }

    if (model != null) {
      final pen = Paint()
        ..color = AppColors.olive
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final m in path(model!).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 14) {
          canvas.drawPath(m.extractPath(d, math.min(d + 8, m.length)), pen);
        }
      }
    }
    if (pts.length > 1) {
      canvas.drawPath(
        path(pts),
        Paint()
          ..color = AppColors.rust
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final start = Offset(.04 * s.width, startY * s.height);
    canvas.drawCircle(start, 9, Paint()..color = AppColors.sunflower);
    canvas.drawCircle(start, 9, Paint()..color = AppColors.ink..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_DrawPainter o) => true;
}

// ================================================================ How big?

/// A strength word on a ticket; tap its level on the staircase (1 tiny → 5
/// huge). Reveals the right step and the other words at that level.
class DialView extends StatefulWidget {
  const DialView(this.q, {super.key});
  final DialQ q;
  @override
  State<DialView> createState() => _DialViewState();
}

class _DialViewState extends State<DialView> {
  int? _picked;
  static const _names = ['tiny', 'small', 'neutral', 'big', 'huge'];

  Future<void> _pick(int level) async {
    if (_picked != null) return;
    setState(() => _picked = level);
    final w = widget.q.word;
    final ok = level == w.strength;
    HapticFeedback.selectionClick();
    final c = sessionOf(context);
    await c.record('dial-${widget.q.set.id}-${w.w}', correct: ok);
    if (!mounted) return;
    final same = [for (final x in widget.q.set.words) if (x.strength == w.strength && x.w != w.w) x.w];
    c.answer(AnswerFeedback(
      ok ? Verdict.right : Verdict.wrong,
      ok ? 'Level ${w.strength} · ${_names[w.strength - 1]}' : 'It’s level ${w.strength} · ${_names[w.strength - 1]}',
      body: [if (w.note != null) w.note!, if (same.isNotEmpty) 'Same level: ${same.join(', ')}'].join('\n'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.q.word;
    return SessionFrame(
      header: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        decoration: const ShapeDecoration(color: Colors.white, shape: TicketBorder(radius: 24, notch: 11, notchAt: .62)),
        child: Column(children: [
          Text('${widget.q.set.head}:', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(w.w, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const Text('How big a change is it?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
      body: Column(children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 1; i <= 5; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _pick(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (_picked != null && i == w.strength) const Text('✓', style: TextStyle(fontSize: 18, color: AppColors.olive, fontWeight: FontWeight.w800)),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 36.0 + 26 * i,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _picked == null
                              ? Color.lerp(const Color(0xFFF6E3C8), AppColors.rust, (i - 1) / 4)
                              : (i == w.strength ? AppColors.olive : (i == _picked ? AppColors.rust.withValues(alpha: .35) : AppColors.line)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(8)),
                          border: Border.all(color: i == _picked ? AppColors.ink : Colors.transparent, width: 2.5),
                        ),
                        child: Text('$i', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: i >= 4 || (_picked != null && i == w.strength) ? Colors.white : AppColors.ink)),
                      ),
                      const SizedBox(height: 6),
                      Text(_names[i - 1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ================================================================ Bubble pop

/// Phrases rise as bubbles; tap only the Band 8 ones before they float
/// away. Tapping a plain one wobbles it. Trains fast recognition.
class BubbleView extends StatefulWidget {
  const BubbleView(this.q, {super.key});
  final BubbleQ q;
  @override
  State<BubbleView> createState() => _BubbleViewState();
}

class _BubbleViewState extends State<BubbleView> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: 1100 * widget.q.items.length + 4000))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    })
    ..forward();
  final _popped = <int>{};
  final _wrong = <int>{};
  int? _shake;
  bool _done = false;

  static const _tints = [Color(0xFFFFF1D6), Color(0xFFF1EDFF), Color(0xFFE7F3FB), Color(0xFFFDE9E4), Color(0xFFEFF4DF)];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0 → just appeared at the bottom, 1 → gone off the top.
  double _life(int i) {
    final n = widget.q.items.length;
    final start = i / (n + 3);
    final span = 4 / (n + 3);
    return (_c.value - start) / span;
  }

  Future<void> _tap(int i) async {
    if (_done || _popped.contains(i)) return;
    final item = widget.q.items[i];
    final c = sessionOf(context);
    if (item.formal) {
      HapticFeedback.lightImpact();
      setState(() => _popped.add(i));
      await c.record(item.swap.id, correct: true, core: false, isSwap: true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong.add(i);
        _shake = i;
      });
      await c.record(item.swap.id, correct: false, core: false, isSwap: true);
    }
    if (_popped.length == widget.q.items.where((x) => x.formal).length) _finish();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _c.stop();
    final items = widget.q.items;
    final missed = [for (final (i, x) in items.indexed) if (x.formal && !_popped.contains(i)) x];
    final wrong = [for (final i in _wrong) items[i]];
    final perfect = missed.isEmpty && wrong.isEmpty;
    sessionOf(context).answer(AnswerFeedback(
      perfect ? Verdict.right : Verdict.wrong,
      perfect ? 'Every Band 8 bubble popped!' : 'Round over',
      body: perfect
          ? null
          : [
              if (wrong.isNotEmpty) 'Plain, not Band 8: ${wrong.map((x) => x.swap.plain).take(3).join(', ')}',
              if (missed.isNotEmpty) 'Floated away: ${missed.map((x) => x.swap.best).take(3).join(', ')}',
            ].join('\n'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.q.items;
    final toPop = items.where((x) => x.formal).length;
    return SessionFrame(
      header: Row(children: [
        const Expanded(
          child: Text('Pop the Band 8 phrases.\nLet the plain ones float away.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Text('${_popped.length} / $toPop', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ]),
      body: SizedBox(
        height: 470,
        child: LayoutBuilder(builder: (context, box) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(clipBehavior: Clip.hardEdge, children: [
              for (final (i, item) in items.indexed)
                if (_life(i) > 0 && _life(i) < 1)
                  () {
                    final life = _life(i);
                    const d = 112.0;
                    final lane = ((i * 37) % 70) / 100;
                    final sway = math.sin(life * math.pi * 2 + i) * 10;
                    final popped = _popped.contains(i);
                    return Positioned(
                      left: lane * (box.maxWidth - d) + sway + box.maxWidth * .15 * (i.isEven ? 0 : 1) * .5,
                      top: box.maxHeight - (box.maxHeight + d) * life,
                      child: GestureDetector(
                        onTap: () => _tap(i),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          scale: popped ? 1.35 : 1,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: popped ? 0 : 1,
                            child: Container(
                              width: d,
                              height: d,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-.35, -.4),
                                  colors: [Colors.white, _tints[i % _tints.length]],
                                ),
                                border: Border.all(color: _wrong.contains(i) ? AppColors.rust : Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))],
                              ),
                              child: Text(item.text,
                                  textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.15)),
                            ),
                          ),
                        ),
                      ).animate(target: _shake == i ? 1 : 0).shakeX(hz: 6, amount: 5, duration: 350.ms),
                    );
                  }(),
            ]),
          );
        }),
      ),
    );
  }
}
