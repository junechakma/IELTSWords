import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/vocab_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';
import 'swap_modes.dart';

// ------------------------------------------------------------ Flashcards

class FlashView extends StatefulWidget {
  const FlashView(this.q, {super.key});
  final FlashQ q;
  @override
  State<FlashView> createState() => _FlashViewState();
}

class _FlashViewState extends State<FlashView> {
  bool _flipped = false;
  bool _done = false;

  Future<void> _grade(bool knewIt) async {
    if (_done) return;
    setState(() => _done = true);
    final s = widget.q.swap;
    final c = sessionOf(context);
    await c.record(s.id, correct: knewIt, isSwap: true);
    if (!mounted) return;
    c.answer(AnswerFeedback(
      knewIt ? Verdict.right : Verdict.wrong,
      knewIt ? 'Good' : 'Look again',
      body: '“${s.formalSentence}”',
      answer: knewIt ? null : s.best,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.q.swap;
    final (before, after) = s.plainParts;
    return SessionFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flip the card. Do you remember?', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 150),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: _flipped
                    ? Column(
                        key: const ValueKey('back'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.best, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                          if (s.also.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('also: ${s.also.join(' · ')}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5))),
                          const SizedBox(height: 12),
                          Text(s.formalSentence, style: const TextStyle(fontSize: 16, height: 1.4)),
                        ],
                      )
                    : Column(
                        key: const ValueKey('front'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HighlightSentence(before: before, phrase: s.plain, after: after, strike: true, size: 18),
                          const SizedBox(height: 10),
                          const Text('tap to flip', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: const SizedBox.shrink(),
      bottom: !_flipped
          ? null
          : Row(children: [
              Expanded(child: PillButton('Again', outline: true, onTap: _done ? null : () => _grade(false))),
              const SizedBox(width: 10),
              Expanded(child: PillButton('I know it ✓', onTap: _done ? null : () => _grade(true))),
            ]),
    );
  }
}

// ------------------------------------------------------------ Meaning match

class MeaningView extends StatefulWidget {
  const MeaningView(this.q, {super.key});
  final MeaningQ q;
  @override
  State<MeaningView> createState() => _MeaningViewState();
}

class _MeaningViewState extends State<MeaningView> {
  int? _picked;

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final o = widget.q.options[i];
    final c = sessionOf(context);
    await c.record(widget.q.entry.id, correct: o.correct);
    if (!mounted) return;
    c.answer(o.correct
        ? const AnswerFeedback(Verdict.right, 'Nice!')
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: widget.q.entry.meaning));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.q.entry;
    return SessionFrame(
      header: PromptCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(e.term, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
          if (e.pos != null) Padding(padding: const EdgeInsets.only(top: 4), child: TagChip(e.pos!, color: AppColors.cream)),
        ]),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(2, 8, 0, 10), child: Text('Which meaning is right?', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5))),
          for (final (i, o) in widget.q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerCard(
                text: o.text,
                onTap: () => _pick(i),
                state: _picked == null ? AnswerState.idle : (o.correct ? AnswerState.right : (i == _picked ? AnswerState.wrong : AnswerState.idle)),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Linker sort

class LinkerSortView extends StatefulWidget {
  const LinkerSortView(this.q, {super.key});
  final LinkerSortQ q;
  @override
  State<LinkerSortView> createState() => _LinkerSortViewState();
}

class _LinkerSortViewState extends State<LinkerSortView> {
  int _i = 0;
  String? _wrongBucket;
  int _mistakes = 0;
  final _placed = <String, String>{}; // linker id → bucket

  List<VocabEntry> get linkers => widget.q.linkers;

  Future<void> _drop(String bucket) async {
    if (_i >= linkers.length) return;
    final l = linkers[_i];
    final right = (l.purpose ?? '') == bucket;
    final c = sessionOf(context);
    if (!right) {
      _mistakes++;
      setState(() => _wrongBucket = bucket);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _wrongBucket = null);
      return;
    }
    await c.record(l.id, correct: true);
    setState(() {
      _placed[l.id] = bucket;
      _i++;
    });
    if (_i >= linkers.length) {
      c.answer(AnswerFeedback(
        _mistakes == 0 ? Verdict.right : Verdict.wrong,
        _mistakes == 0 ? 'Sorted every one' : 'All sorted',
        body: _mistakes == 0 ? null : '$_mistakes needed a second try.',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _i >= linkers.length;
    final current = done ? null : linkers[_i];
    return SessionFrame(
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(done ? 'All sorted!' : 'Which purpose does this linker have?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 21)),
        if (current != null) ...[
          const SizedBox(height: 12),
          PromptCard(child: Text(current.term, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600))),
        ],
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in widget.q.buckets)
                GestureDetector(
                  onTap: () => _drop(b),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: b == _wrongBucket ? const Color(0xFFFBEAE5) : AppColors.card,
                      border: Border.all(color: b == _wrongBucket ? AppColors.rust : AppColors.line, width: 1.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(b, style: const TextStyle(fontSize: 15.5)),
                  ).animate(target: b == _wrongBucket ? 1 : 0).shakeX(hz: 4, amount: 4, duration: 300.ms),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_placed.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final l in linkers)
                  if (_placed[l.id] != null) TagChip('${l.term} → ${_placed[l.id]}', color: AppColors.cream),
              ],
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Letter register

class RegisterView extends StatefulWidget {
  const RegisterView(this.q, {super.key});
  final RegisterQ q;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  int? _picked;

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final ok = widget.q.options[i] == widget.q.register;
    final c = sessionOf(context);
    await c.record('${widget.q.phrase.hashCode}', correct: ok);
    if (!mounted) return;
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Right register', body: widget.q.why)
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: widget.q.register, body: widget.q.why));
  }

  @override
  Widget build(BuildContext context) {
    return SessionFrame(
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Formal, semi-formal, or informal?', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
        const SizedBox(height: 10),
        PromptCard(child: Text('“${widget.q.phrase}”', style: const TextStyle(fontSize: 20, height: 1.4))),
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, o) in widget.q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerCard(
                text: o,
                onTap: () => _pick(i),
                state: _picked == null ? AnswerState.idle : (o == widget.q.register ? AnswerState.right : (i == _picked ? AnswerState.wrong : AnswerState.idle)),
              ),
            ),
        ],
      ),
    );
  }
}
