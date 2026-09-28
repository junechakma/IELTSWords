import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app_scope.dart';
import '../../state/providers.dart';
import '../../data/swap_models.dart';
import '../../mascots/mascot.dart';
import '../../mascots/mascot_image.dart';
import '../../services/speech.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';

/// Sentence with one phrase highlighted (plain word in a soft rust box, or struck through).
class HighlightSentence extends StatelessWidget {
  const HighlightSentence({super.key, required this.before, required this.phrase, required this.after, this.strike = false, this.size = 19, this.color});
  final String before, phrase, after;
  final bool strike;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: size, height: 1.45, color: AppColors.ink);
    return Text.rich(TextSpan(style: base, children: [
      TextSpan(text: before),
      TextSpan(
        text: strike ? phrase : ' $phrase ',
        style: strike
            ? const TextStyle(color: AppColors.rust, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust)
            : TextStyle(backgroundColor: color ?? const Color(0xFFF8DAD3)),
      ),
      TextSpan(text: after),
    ]));
  }
}

AnswerFeedback swapFeedback(Swap s, {required Verdict verdict, String? why}) => switch (verdict) {
      Verdict.right => AnswerFeedback(Verdict.right, 'Nice!', body: '${s.note == null ? '' : '${s.note}\n'}“${s.formalSentence}”'),
      Verdict.tooPlain => AnswerFeedback(Verdict.tooPlain, 'Right idea, too plain', answer: s.best, body: why),
      Verdict.wrong => AnswerFeedback(Verdict.wrong, 'Not quite', answer: s.best, body: why),
    };

void maybeSpeak(BuildContext context, String text) {
  if (context.readProvider(settingsProvider).readAloud) Speech.instance.speak(text);
}

// ------------------------------------------------------------ Swap it · choose

class SwapChoiceView extends StatefulWidget {
  const SwapChoiceView(this.q, {super.key});
  final SwapChoiceQ q;
  @override
  State<SwapChoiceView> createState() => _SwapChoiceViewState();
}

class _SwapChoiceViewState extends State<SwapChoiceView> {
  int? _picked;

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final s = widget.q.swap;
    final o = widget.q.options[i];
    final c = sessionOf(context);
    await c.record(s.id, correct: o.correct, isSwap: true);
    if (!mounted) return;
    if (o.correct) maybeSpeak(context, s.formalSentence);
    c.answer(swapFeedback(s, verdict: o.correct ? Verdict.right : (o.tooPlain ? Verdict.tooPlain : Verdict.wrong), why: o.why == null ? null : '“${o.text}”: ${o.why}'));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.swap;
    final (before, after) = s.plainParts;
    return SessionFrame(
      header: PromptCard(child: HighlightSentence(before: before, phrase: s.plain, after: after)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(2, 8, 0, 10), child: Text('Say it the Band 8 way:', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5))),
          for (final (i, o) in widget.q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerCard(
                text: o.text,
                onTap: () => _pick(i),
                state: _picked == null
                    ? AnswerState.idle
                    : (o.correct ? AnswerState.right : (i == _picked ? AnswerState.wrong : AnswerState.idle)),
              ).animate(delay: (60 * i).ms).fadeIn(duration: 250.ms).moveY(begin: 8, end: 0),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Swap it · type

class SwapTypeView extends StatefulWidget {
  const SwapTypeView(this.q, {super.key});
  final SwapTypeQ q;
  @override
  State<SwapTypeView> createState() => _SwapTypeViewState();
}

class _SwapTypeViewState extends State<SwapTypeView> {
  final _ctl = TextEditingController();
  bool _done = false;
  bool _hint = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _check({bool giveUp = false}) async {
    if (_done) return;
    final s = widget.q.swap;
    final typed = _ctl.text;
    if (!giveUp && typed.trim().isEmpty) return;
    setState(() => _done = true);
    final ok = !giveUp && s.accepts(typed);
    final plain = typed.trim().toLowerCase() == s.plain.toLowerCase();
    final c = sessionOf(context);
    await c.record(s.id, correct: ok, typed: true, isSwap: true);
    if (!mounted) return;
    if (ok) maybeSpeak(context, s.formalSentence);
    c.answer(swapFeedback(
      s,
      verdict: ok ? Verdict.right : (plain ? Verdict.tooPlain : Verdict.wrong),
      why: ok ? null : (s.also.isEmpty ? s.note : 'Also right: ${s.also.join(' · ')}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.swap;
    final (before, after) = s.plainParts;
    final start = s.best.length <= 3 ? s.best.substring(0, 1) : s.best.substring(0, 2);
    return SessionFrame(
      header: Stack(
        clipBehavior: Clip.none,
        children: [
          PromptCard(child: HighlightSentence(before: before, phrase: s.plain, after: after, strike: true)),
          Positioned(right: 6, bottom: -52, child: MascotImage(Mascot.pick(const [Mascot.thinking, Mascot.focused], s.id.length), size: 58, sticker: true)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 12, 70, 10),
            child: Text('Type the Band 8 ${s.form ?? 'swap'}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
          ),
          TextField(
            controller: _ctl,
            autofocus: true,
            enabled: !_done,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onSubmitted: (_) => _check(),
            style: const TextStyle(fontSize: 21),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              hintText: _hint ? '$start…' : 'type it',
              hintStyle: const TextStyle(color: Color(0xFFBDB6AA)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.ink, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            TagChip(_hint ? '💡 starts with “$start”' : '💡 Show a hint', color: AppColors.sand, onTap: () => setState(() => _hint = true)),
            if (s.form != null) TagChip(s.form!, color: AppColors.sand),
            TagChip('I don’t know', color: AppColors.sand, onTap: () => _check(giveUp: true)),
          ]),
        ],
      ),
      bottom: ListenableBuilder(
        listenable: _ctl,
        builder: (_, _) => PillButton('Check', onTap: _ctl.text.trim().isEmpty || _done ? null : _check),
      ),
    );
  }
}

// ------------------------------------------------------------ Rewrite

class RewriteView extends StatefulWidget {
  const RewriteView(this.q, {super.key});
  final RewriteQ q;
  @override
  State<RewriteView> createState() => _RewriteViewState();
}

class _RewriteViewState extends State<RewriteView> {
  int? _sel;
  bool _checked = false;

  Future<void> _check() async {
    if (_sel == null || _checked) return;
    setState(() => _checked = true);
    final o = widget.q.options[_sel!];
    final c = sessionOf(context);
    await c.record(widget.q.item.id, correct: o.correct);
    if (!mounted) return;
    c.answer(o.correct
        ? const AnswerFeedback(Verdict.right, 'That’s the Band 8 version')
        : AnswerFeedback(o.tooPlain ? Verdict.tooPlain : Verdict.wrong, o.tooPlain ? 'Right idea, too plain' : 'Not quite', body: o.why, answer: widget.q.item.best));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.q.item;
    return SessionFrame(
      header: PromptCard(child: Text('“${item.plain}”', style: const TextStyle(fontSize: 18, height: 1.45, color: AppColors.inkSoft))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 10),
            child: Text('Which is the Band 8 ${item.slot.label.toLowerCase()} sentence?', style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
          ),
          for (final (i, o) in widget.q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerCard(
                text: o.text,
                fontSize: 15.5,
                selected: _sel == i,
                note: _checked && !o.correct ? o.why : null,
                onTap: _checked ? null : () => setState(() => _sel = i),
                state: !_checked ? AnswerState.idle : (o.correct ? AnswerState.right : (i == _sel ? AnswerState.wrong : AnswerState.idle)),
              ),
            ),
        ],
      ),
      bottom: PillButton('Check', dark: true, onTap: _sel == null ? null : _check),
    );
  }
}

// ------------------------------------------------------------ Spot the plain words

class SpotView extends StatefulWidget {
  const SpotView(this.q, {super.key});
  final SpotQ q;
  @override
  State<SpotView> createState() => _SpotViewState();
}

class _SpotViewState extends State<SpotView> {
  final _found = <String>{};
  String? _miss; // token key flashed as "that one is fine"
  bool _swapping = false;
  int _swapIndex = 0;
  int? _picked;
  late final _options = [for (final s in widget.q.swaps) swapOptions(s, Random())];
  final _results = <String, bool>{};

  List<Swap> get swaps => widget.q.swaps;

  void _tapWord(String key) {
    setState(() => _miss = key);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _miss == key) setState(() => _miss = null);
    });
  }

  Future<void> _pickSwap(int i) async {
    if (_picked != null) return;
    final s = swaps[_swapIndex];
    final o = _options[_swapIndex][i];
    setState(() => _picked = i);
    _results[s.id] = o.correct;
    await sessionOf(context).record(s.id, correct: o.correct, isSwap: true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_swapIndex < swaps.length - 1) {
      setState(() {
        _swapIndex++;
        _picked = null;
      });
    } else {
      final wrong = _results.values.where((v) => !v).length;
      sessionOf(context).answer(AnswerFeedback(
        wrong == 0 ? Verdict.right : Verdict.wrong,
        wrong == 0 ? 'All swapped!' : '$wrong still plain',
        body: swaps.map((s) => s.formalSentence).join(' '),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SessionFrame(
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(_swapping ? 'Now swap each one for Band 8' : 'Tap every phrase a Band 8 writer would change',
                style: t.titleLarge?.copyWith(fontSize: 22, height: 1.25)),
          ),
          const SizedBox(width: 8),
          const MascotImage(Mascot.spotThePlain, size: 64, sticker: true),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
            child: Wrap(
              runSpacing: 6,
              children: [
                for (final (si, s) in swaps.indexed) ..._sentence(si, s),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_swapping)
            Row(
              children: [
                Text.rich(TextSpan(style: const TextStyle(fontSize: 16), children: [
                  const TextSpan(text: 'Found '),
                  TextSpan(text: '${_found.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' of ${swaps.length}'),
                ])),
                const Spacer(),
                if (_found.length < swaps.length) TagChip('Show me', color: AppColors.sand, onTap: () => setState(() => _found.addAll(swaps.map((s) => s.id)))),
              ],
            )
          else ...[
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Swap  ', style: TextStyle(color: AppColors.inkSoft)),
              TextSpan(text: '“${swaps[_swapIndex].plain}”', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: '   ${_swapIndex + 1} / ${swaps.length}', style: const TextStyle(color: AppColors.inkSoft)),
            ]), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            for (final (i, o) in _options[_swapIndex].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: AnswerCard(
                  text: o.text,
                  fontSize: 16,
                  note: _picked == i && !o.correct ? o.why : null,
                  onTap: () => _pickSwap(i),
                  state: _picked == null ? AnswerState.idle : (o.correct ? AnswerState.right : (i == _picked ? AnswerState.wrong : AnswerState.idle)),
                ),
              ),
          ],
        ],
      ),
      bottom: _swapping
          ? null
          : PillButton(_found.length == swaps.length ? 'Done spotting · swap them' : 'Done spotting', onTap: _found.length == swaps.length ? () => setState(() => _swapping = true) : null),
    );
  }

  List<Widget> _sentence(int si, Swap s) {
    final (before, after) = s.plainParts;
    final out = <Widget>[];
    void words(String text, String part) {
      for (final (wi, w) in text.split(' ').indexed) {
        if (w.isEmpty) continue;
        final key = '$si-$part-$wi';
        out.add(GestureDetector(
          onTap: _swapping ? null : () => _tapWord(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(color: _miss == key ? const Color(0xFFEDE7DC) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
            child: Text('$w ', style: const TextStyle(fontSize: 17, height: 1.5)),
          ),
        ));
      }
    }

    words(before, 'b');
    final found = _found.contains(s.id);
    final swapped = _results.containsKey(s.id);
    out.add(GestureDetector(
      onTap: _swapping ? null : () => setState(() => _found.add(s.id)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: swapped ? (_results[s.id]! ? const Color(0xFFF1F5E4) : const Color(0xFFFBEAE5)) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: found ? (swapped && _results[s.id]! ? AppColors.olive : AppColors.rust) : Colors.transparent, width: 1.6),
        ),
        child: Text(swapped ? s.best : s.plain, style: TextStyle(fontSize: 17, height: 1.45, fontWeight: swapped ? FontWeight.w600 : FontWeight.w400)),
      ),
    ));
    words(after, 'a');
    return out;
  }
}
