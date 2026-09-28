import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/swap_models.dart';
import '../../mascots/mascot.dart';
import '../../mascots/mascot_image.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';
import 'swap_modes.dart';

/// The mascot "saying" the prompt in a speech bubble.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.mascot, required this.child});
  final Mascot mascot;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        MascotImage(mascot, size: 62, sticker: true, idle: true),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12 + 12),
            decoration: const ShapeDecoration(color: Colors.white, shape: BubbleBorder(tailAt: 10)),
            child: child,
          ),
        ),
      ]);
}

// ================================================================ Plain or Band 8? (swipe)

class SpeedView extends StatefulWidget {
  const SpeedView(this.q, {super.key});
  final SpeedQ q;
  @override
  State<SpeedView> createState() => _SpeedViewState();
}

class _SpeedViewState extends State<SpeedView> with TickerProviderStateMixin {
  static const _seconds = 6;
  late final _timer = AnimationController(vsync: this, duration: const Duration(seconds: _seconds))..addStatusListener(_onTimeout);
  int _i = 0;
  double _dx = 0;
  bool? _flash; // true = right, false = wrong (brief overlay)
  final _misses = <(SpeedCard, bool)>[]; // card, timedOut
  bool _busy = false;

  List<SpeedCard> get cards => widget.q.cards;

  @override
  void initState() {
    super.initState();
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _onTimeout(AnimationStatus s) {
    if (s == AnimationStatus.completed) _decide(null);
  }

  /// [saidFormal] null = ran out of time.
  Future<void> _decide(bool? saidFormal) async {
    if (_busy || _i >= cards.length) return;
    _busy = true;
    _timer.stop();
    final card = cards[_i];
    final ok = saidFormal == card.formal;
    HapticFeedback.selectionClick();
    setState(() {
      _flash = ok;
      _dx = saidFormal == null ? 0 : (saidFormal ? 500 : -500);
    });
    if (!ok) _misses.add((card, saidFormal == null));
    await sessionOf(context).record(card.swap.id, correct: ok, core: false, isSwap: true);
    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    if (_i >= cards.length - 1) {
      setState(() => _i++);
      final missed = _misses.length;
      sessionOf(context).answer(AnswerFeedback(
        missed == 0 ? Verdict.right : Verdict.wrong,
        missed == 0 ? 'Sharp instincts!' : 'Round done — $missed to look at again',
        body: missed == 0
            ? 'You sorted every card. That’s the habit forming.'
            : [
                for (final (c, slow) in _misses.take(4))
                  c.formal ? '“${c.swap.best}” is Band 8${slow ? ' (too slow)' : ''}' : '“${c.swap.plain}” is plain → ${c.swap.best}',
              ].join('\n'),
      ));
    } else {
      setState(() {
        _i++;
        _dx = 0;
        _flash = null;
      });
      _timer.forward(from: 0);
    }
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final done = _i >= cards.length;
    return SessionFrame(
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Is it Band 8 or plain?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Swipe right for Band 8, left for plain. Go with your gut.', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(AppIcons.timer, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _timer,
                builder: (_, _) => LinearProgressIndicator(
                  value: 1 - _timer.value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: .6),
                  color: _timer.value > .7 ? AppColors.rust : AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${math.min(_i + 1, cards.length)} / ${cards.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ]),
      body: Column(children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: done
              ? const SizedBox()
              : Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  // The next two cards peek out behind.
                  for (var k = math.min(2, cards.length - _i - 1); k >= 1; k--)
                    Transform.translate(
                      offset: Offset(0, 14.0 * k),
                      child: Transform.scale(scale: 1 - .05 * k, child: _card(cards[_i + k], ghost: true)),
                    ),
                  GestureDetector(
                    onPanUpdate: (d) => setState(() => _dx += d.delta.dx),
                    onPanEnd: (_) {
                      if (_dx > 90) {
                        _decide(true);
                      } else if (_dx < -90) {
                        _decide(false);
                      } else {
                        setState(() => _dx = 0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: _dx.abs() >= 500 ? 300 : 0),
                      transform: Matrix4.translationValues(_dx, 0, 0)..rotateZ(_dx / 900),
                      transformAlignment: Alignment.bottomCenter,
                      child: _card(cards[_i], flash: _flash),
                    ),
                  ),
                ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _choice('Plain', AppIcons.back, const Color(0xFFFBEAE5), AppColors.rust, () => _decide(false))),
          const SizedBox(width: 12),
          Expanded(child: _choice('Band 8', AppIcons.next, const Color(0xFFE6EDCF), const Color(0xFF4F6414), () => _decide(true), iconAfter: true)),
        ]),
      ]),
    );
  }

  Widget _choice(String label, IconData icon, Color bg, Color fg, VoidCallback onTap, {bool iconAfter = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(27), border: Border.all(color: fg.withValues(alpha: .4), width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!iconAfter) Icon(icon, color: fg, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            if (iconAfter) Icon(icon, color: fg, size: 18),
          ]),
        ),
      );

  Widget _card(SpeedCard c, {bool ghost = false, bool? flash}) {
    final lean = ghost ? 0.0 : (_dx / 120).clamp(-1.0, 1.0);
    final bg = flash == null ? Colors.white : (flash ? const Color(0xFFF1F5E4) : const Color(0xFFFBEAE5));
    final (before, after) = c.formal ? c.swap.formalParts : c.swap.plainParts;
    return Container(
      width: double.infinity,
      height: 270,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: ShapeDecoration(
        color: ghost ? Colors.white.withValues(alpha: .7) : bg,
        shape: const TicketBorder(radius: 26, notch: 13, notchAt: .56),
        shadows: ghost ? null : const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -6)],
      ),
      child: ghost
          ? null
          : Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Spacer(),
                Center(
                  child: Text(c.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15)),
                ),
                const Spacer(),
                const SizedBox(height: 22),
                Text.rich(
                  TextSpan(style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.inkSoft), children: [
                    TextSpan(text: before),
                    TextSpan(text: c.text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    TextSpan(text: after),
                  ]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
              // Stamps that appear as you drag.
              if (lean > .15)
                Positioned(left: 0, top: 0, child: Opacity(opacity: lean, child: _stamp('BAND 8', const Color(0xFF4F6414), -.2))),
              if (lean < -.15)
                Positioned(right: 0, top: 0, child: Opacity(opacity: -lean, child: _stamp('PLAIN', AppColors.rust, .2))),
            ]),
    );
  }

  Widget _stamp(String text, Color color, double angle) => Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: color, width: 2.5), borderRadius: BorderRadius.circular(8)),
          child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.5)),
        ),
      );
}

// ================================================================ Match pairs

class MatchView extends StatefulWidget {
  const MatchView(this.q, {super.key});
  final MatchQ q;
  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final List<Swap> _left = widget.q.swaps;
  late final List<Swap> _right = [...widget.q.swaps]..shuffle();
  String? _selL, _selR;
  final _matched = <String>{};
  final _missed = <String>{};
  (String, String)? _wrong;

  Future<void> _tap({String? left, String? right}) async {
    if (left != null && _matched.contains(left)) return;
    if (right != null && _matched.contains(right)) return;
    setState(() {
      if (left != null) _selL = left;
      if (right != null) _selR = right;
    });
    if (_selL == null || _selR == null) return;
    final l = _selL!, r = _selR!;
    final c = sessionOf(context);
    if (l == r) {
      HapticFeedback.lightImpact();
      setState(() {
        _matched.add(l);
        _selL = _selR = null;
      });
      if (!_missed.contains(l)) await c.record(l, correct: true, core: false, isSwap: true);
      if (_matched.length == _left.length && mounted) {
        c.answer(AnswerFeedback(
          _missed.isEmpty ? Verdict.right : Verdict.wrong,
          _missed.isEmpty ? 'All matched first time!' : 'All matched',
          body: _missed.isEmpty ? null : '${_missed.length} took a second try.',
        ));
      }
    } else {
      HapticFeedback.heavyImpact();
      if (_missed.add(l)) await c.record(l, correct: false, core: false, isSwap: true);
      setState(() => _wrong = (l, r));
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _wrong = null;
          _selL = null;
          _selR = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionFrame(
      header: const MascotSays(
        mascot: Mascot.playful,
        child: Text('Match each plain phrase with its Band 8 swap.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.3)),
      ),
      body: Column(children: [
        const SizedBox(height: 6),
        const Row(children: [
          Expanded(child: Center(child: Text('YOU’D WRITE', style: TextStyle(fontSize: 11.5, letterSpacing: .8, fontWeight: FontWeight.w600, color: AppColors.inkSoft)))),
          Expanded(child: Center(child: Text('BAND 8', style: TextStyle(fontSize: 11.5, letterSpacing: .8, fontWeight: FontWeight.w600, color: AppColors.inkSoft)))),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < _left.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: _pebble(_left[i].plain, _left[i].id, left: true, seed: i, strike: true)),
              const SizedBox(width: 10),
              Expanded(child: _pebble(_right[i].best, _right[i].id, left: false, seed: i + 7)),
            ]),
          ),
      ]),
    );
  }

  Widget _pebble(String text, String id, {required bool left, required int seed, bool strike = false}) {
    final matched = _matched.contains(id);
    final selected = left ? _selL == id : _selR == id;
    final wrong = _wrong != null && (left ? _wrong!.$1 == id : _wrong!.$2 == id);
    final color = matched
        ? const Color(0xFFE6EDCF)
        : wrong
            ? const Color(0xFFFBEAE5)
            : (left ? const Color(0xFFFFF1D6) : const Color(0xFFF1EDFF));
    return GestureDetector(
      onTap: matched ? null : () => _tap(left: left ? id : null, right: left ? null : id),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: matched ? .55 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: selected ? 1.05 : (matched ? .95 : 1),
          child: Container(
            height: 66,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: color,
              shape: PebbleBorder(seed: seed, side: BorderSide(color: selected ? AppColors.ink : (matched ? AppColors.olive : Colors.transparent), width: 2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (matched) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(AppIcons.check, size: 14, color: Color(0xFF4F6414))),
              Flexible(
                child: Text(text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, height: 1.2, fontWeight: left ? FontWeight.w500 : FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ).animate(target: wrong ? 1 : 0).shakeX(hz: 5, amount: 4, duration: 350.ms),
    );
  }
}

// ================================================================ Build the sentence

class SentenceView extends StatefulWidget {
  const SentenceView(this.q, {super.key});
  final SentenceQ q;
  @override
  State<SentenceView> createState() => _SentenceViewState();
}

class _SentenceViewState extends State<SentenceView> {
  final _placed = <int>[]; // indexes into q.chips
  bool _checked = false;
  bool _ok = false;

  List<String> get chips => widget.q.chips;

  Future<void> _check() async {
    if (_checked) return;
    final built = [for (final i in _placed) chips[i]].join(' ');
    final target = SentenceQ.chipsOf(widget.q.swap).join(' ');
    setState(() {
      _checked = true;
      _ok = built == target;
    });
    final c = sessionOf(context);
    await c.record(widget.q.swap.id, correct: _ok, isSwap: true);
    if (!mounted) return;
    if (_ok) maybeSpeak(context, widget.q.swap.formalSentence);
    c.answer(_ok
        ? const AnswerFeedback(Verdict.right, 'Perfect order')
        : AnswerFeedback(Verdict.wrong, 'Close — here’s the order', body: widget.q.swap.formalSentence, answer: widget.q.swap.best));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.swap;
    final (before, after) = s.plainParts;
    final remaining = [for (var i = 0; i < chips.length; i++) if (!_placed.contains(i)) i];
    return SessionFrame(
      header: MascotSays(
        mascot: Mascot.focused,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Build the Band 8 version of:', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          HighlightSentence(before: before, phrase: s.plain, after: after, strike: true, size: 16),
        ]),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 6),
        // Where the sentence is built (a ticket with a tear line).
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: _checked ? (_ok ? const Color(0xFFF1F5E4) : const Color(0xFFFBEAE5)) : Colors.white,
            shape: const TicketBorder(radius: 22, notch: 11, notchAt: .5),
          ),
          child: _placed.isEmpty
              ? const Padding(padding: EdgeInsets.all(8), child: Text('Tap the words below in order…', style: TextStyle(color: AppColors.inkSoft)))
              : Wrap(spacing: 6, runSpacing: 8, children: [
                  for (final i in _placed)
                    GestureDetector(
                      onTap: _checked ? null : () => setState(() => _placed.remove(i)),
                      child: _chip(chips[i], placed: true, band8: chips[i] == s.best),
                    ),
                ]),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 10, children: [
          for (final (n, i) in remaining.indexed)
            GestureDetector(
              onTap: _checked ? null : () => setState(() => _placed.add(i)),
              child: Transform.rotate(angle: ((n % 3) - 1) * .025, child: _chip(chips[i], band8: chips[i] == s.best)),
            ),
        ]),
      ]),
      bottom: PillButton(
        remaining.isEmpty ? 'Check' : '${remaining.length} words left',
        dark: true,
        onTap: remaining.isEmpty && !_checked ? _check : null,
      ),
    );
  }

  Widget _chip(String text, {bool placed = false, bool band8 = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: ShapeDecoration(
          color: band8 ? const Color(0xFFFDE6B0) : (placed ? AppColors.cream : Colors.white),
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: placed ? Colors.transparent : AppColors.line, width: 1.5)),
        ),
        child: Text(text, style: TextStyle(fontSize: 15.5, fontWeight: band8 ? FontWeight.w700 : FontWeight.w500)),
      );
}

// ================================================================ Letter tiles

class TilesView extends StatefulWidget {
  const TilesView(this.q, {super.key});
  final TilesQ q;
  @override
  State<TilesView> createState() => _TilesViewState();
}

class _TilesViewState extends State<TilesView> {
  final _used = <int>[]; // tile indexes, in the order placed
  bool _done = false;
  bool _hinted = false;

  String get target => widget.q.swap.best.toLowerCase();
  List<String> get letters => widget.q.letters;

  Future<void> _place(int i) async {
    if (_done || _used.contains(i) || _used.length >= target.length) return;
    HapticFeedback.selectionClick();
    setState(() => _used.add(i));
    if (_used.length == target.length) await _check();
  }

  void _hint() {
    if (_hinted || _used.isNotEmpty) return;
    final i = letters.indexOf(target[0]);
    if (i >= 0) {
      setState(() => _hinted = true);
      _place(i);
    }
  }

  Future<void> _check() async {
    final word = [for (final i in _used) letters[i]].join();
    final ok = word == target;
    setState(() => _done = true);
    final c = sessionOf(context);
    // Spelling it yourself counts as producing the word (towards Natural).
    await c.record(widget.q.swap.id, correct: ok, typed: !_hinted, isSwap: true);
    if (!mounted) return;
    if (ok) maybeSpeak(context, widget.q.swap.formalSentence);
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Spelt it!', body: '“${widget.q.swap.formalSentence}”')
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: widget.q.swap.best, body: 'You spelt “$word”.'));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.swap;
    final (before, after) = s.plainParts;
    final word = [for (final i in _used) letters[i]];
    return SessionFrame(
      header: MascotSays(
        mascot: Mascot.cheerful,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HighlightSentence(before: before, phrase: s.plain, after: after, strike: true, size: 16),
          const SizedBox(height: 6),
          Text('Spell the Band 8 word · ${target.length} letters', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
        ]),
      ),
      body: Column(children: [
        const SizedBox(height: 8),
        // Answer slots.
        Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
          for (var k = 0; k < target.length; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k < word.length ? (_done ? (word.join() == target ? const Color(0xFFE6EDCF) : const Color(0xFFFBEAE5)) : Colors.white) : Colors.white.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(10),
                border: Border(bottom: BorderSide(color: k == word.length && !_done ? AppColors.ink : AppColors.line, width: 3)),
              ),
              child: Text(k < word.length ? word[k].toUpperCase() : '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 28),
        // Tiles.
        Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 12, children: [
          for (var i = 0; i < letters.length; i++)
            GestureDetector(
              onTap: () => _place(i),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _used.contains(i) ? .15 : 1,
                child: Transform.rotate(
                  angle: ((i * 37) % 7 - 3) * .02,
                  child: Container(
                    width: 50,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: AppColors.sunflowerSoft,
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      shadows: const [BoxShadow(color: Color(0xFFC88200), offset: Offset(0, 4))],
                    ),
                    child: Text(letters[i].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TagChip('💡 First letter', color: AppColors.sand, onTap: _hinted || _used.isNotEmpty ? null : _hint),
          const SizedBox(width: 8),
          TagChip('⌫ Undo', color: AppColors.sand, onTap: _done || _used.isEmpty ? null : () => setState(() => _used.removeLast())),
        ]),
      ]),
    );
  }
}
