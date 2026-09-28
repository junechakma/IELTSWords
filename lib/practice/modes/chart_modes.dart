import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../charts/chart_view.dart';
import '../../data/swap_models.dart';
import '../../data/word_set_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../questions.dart';
import '../session_controller.dart';
import '../session_screen.dart';
import 'swap_modes.dart';
import '../../theme/app_icons.dart';

/// White card holding a chart.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
        child: child,
      );
}

/// Sentence with a "___" gap filled by [fill] (or an underline).
class GapSentence extends StatelessWidget {
  const GapSentence(this.sentence, {super.key, this.fill, this.size = 18, this.fillColor});
  final String sentence;
  final String? fill;
  final double size;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final i = sentence.indexOf('___');
    final before = i < 0 ? sentence : sentence.substring(0, i);
    final after = i < 0 ? '' : sentence.substring(i + 3);
    return Text.rich(TextSpan(style: TextStyle(fontSize: size, height: 1.45), children: [
      TextSpan(text: before),
      TextSpan(
        text: fill ?? '       ',
        style: TextStyle(
          fontWeight: fill == null ? FontWeight.w400 : FontWeight.w600,
          color: fillColor,
          decoration: fill == null ? TextDecoration.underline : null,
          decorationThickness: 2,
        ),
      ),
      TextSpan(text: after),
    ]));
  }
}

// ------------------------------------------------------------ Describe the chart

class DescribeView extends StatefulWidget {
  const DescribeView(this.q, {super.key});
  final DescribeQ q;
  @override
  State<DescribeView> createState() => _DescribeViewState();
}

class _DescribeViewState extends State<DescribeView> {
  late final _opts = [...widget.q.item.options]..shuffle();
  String? _picked;

  Future<void> _pick(String o) async {
    if (_picked != null) return;
    final d = widget.q.item;
    setState(() => _picked = o);
    final ok = o == d.answer;
    final c = sessionOf(context);
    await c.record(d.id, correct: ok);
    if (!mounted) return;
    if (ok) maybeSpeak(context, d.sentence.replaceFirst('___', d.answer));
    final plain = d.tooPlain.contains(o);
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Nice!', body: d.why)
        : AnswerFeedback(plain ? Verdict.tooPlain : Verdict.wrong, plain ? 'Right idea, too plain' : 'Not quite', answer: d.answer, body: d.why));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.q.item;
    final sample = widget.q.topic.learn!.sample;
    return SessionFrame(
      header: ChartCard(child: ChartView(chart: sample, highlight: d.part, dimOthers: true, focusMap: true)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          GapSentence(d.sentence, fill: _picked == null ? null : d.answer, fillColor: AppColors.olive),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 10) / 2;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final o in _opts)
                SizedBox(
                  width: w,
                  child: AnswerCard(
                    text: o,
                    fontSize: 16,
                    onTap: () => _pick(o),
                    state: _picked == null ? AnswerState.idle : (o == d.answer ? AnswerState.right : (o == _picked ? AnswerState.wrong : AnswerState.idle)),
                  ),
                ),
            ]);
          }),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Build the paragraph

class BuildView extends StatefulWidget {
  const BuildView(this.q, {super.key});
  final BuildQ q;
  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  int _step = 0;
  int? _wrongPick;
  bool _locked = false;
  int _mistakes = 0;
  late List<Option> _opts = _optionsFor(0);

  ReportParagraph get p => widget.q.paragraph;

  List<Option> _optionsFor(int i) {
    final s = p.steps[i];
    return [Option(s.best, correct: true), for (final o in s.others) Option(o.text, why: o.why, tooPlain: o.why.toLowerCase().contains('plain'))]..shuffle();
  }

  Future<void> _pick(int i) async {
    if (_locked) return;
    final o = _opts[i];
    final c = sessionOf(context);
    final id = '${widget.q.topic.id}-report-${p.slot.name}-$_step';
    if (!o.correct) {
      if (_wrongPick == null) {
        _mistakes++;
        await c.record(id, correct: false);
      }
      setState(() => _wrongPick = i);
      return;
    }
    _locked = true;
    if (_wrongPick == null) await c.record(id, correct: true);
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (_step < p.steps.length - 1) {
      setState(() {
        _step++;
        _wrongPick = null;
        _locked = false;
        _opts = _optionsFor(_step);
      });
    } else {
      setState(() => _step++);
      c.answer(AnswerFeedback(
        _mistakes == 0 ? Verdict.right : Verdict.wrong,
        _mistakes == 0 ? '${p.slot.label} built!' : '${p.slot.label} built',
        body: _mistakes == 0 ? 'Every sentence was the Band 8 one.' : '$_mistakes plain or broken choice${_mistakes == 1 ? '' : 's'} on the way – they come back tomorrow.',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.q.topic.report!;
    final t = Theme.of(context).textTheme;
    final done = _step >= p.steps.length;
    final built = p.steps.take(_step).map((s) => s.best).join(' ');
    return SessionFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build the ${p.slot.label.toLowerCase()}', style: t.titleLarge?.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          if (report.chart != null)
            ChartCard(child: ChartView(chart: report.chart!))
          else
            PromptCard(child: Text(report.question, style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.inkSoft))),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(children: [
            for (final (i, s) in p.steps.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == p.steps.length - 1 ? 0 : 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(color: i < _step ? AppColors.ink : (i == _step ? AppColors.stone : AppColors.line), borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 5),
                      Text(s.position == Position.middle ? 'Middle' : (s.position == Position.opening ? 'Opening' : 'Closing'),
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            child: Text.rich(TextSpan(style: const TextStyle(fontSize: 15.5, height: 1.5), children: [
              TextSpan(text: built),
              if (!done) const TextSpan(text: ' ________', style: TextStyle(color: AppColors.inkSoft)),
            ])),
          ),
          if (!done) ...[
            const SizedBox(height: 14),
            Text(p.steps[_step].prompt, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
            const SizedBox(height: 10),
            for (final (i, o) in _opts.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: AnswerCard(
                  text: o.text,
                  fontSize: 15,
                  note: _wrongPick == i ? o.why : null,
                  onTap: () => _pick(i),
                  state: _locked && o.correct ? AnswerState.right : (_wrongPick == i ? AnswerState.wrong : AnswerState.idle),
                ).animate(key: ValueKey('$_step-$i')).fadeIn(duration: 250.ms, delay: (50 * i).ms),
              ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Label the graph

class LabelView extends StatefulWidget {
  const LabelView(this.q, {super.key});
  final LabelQ q;
  @override
  State<LabelView> createState() => _LabelViewState();
}

class _LabelViewState extends State<LabelView> {
  late final labels = widget.q.topic.learn!.labels;
  late final _order = [for (var i = 0; i < labels.length; i++) i]..shuffle();
  late final _bank = [for (final l in labels) l.word]..shuffle();
  final _placed = <String, String>{}; // part → word
  int _i = 0;
  String? _wrong;
  int _mistakes = 0;
  final _missedParts = <String>{};

  Future<void> _pick(String word) async {
    if (_i >= _order.length) return;
    final l = labels[_order[_i]];
    final c = sessionOf(context);
    final id = '${widget.q.topic.id}-label-${l.part}-${l.word}';
    if (word != l.word) {
      if (_missedParts.add(l.part)) {
        _mistakes++;
        await c.record(id, correct: false);
      }
      setState(() => _wrong = word);
      return;
    }
    if (!_missedParts.contains(l.part)) await c.record(id, correct: true);
    setState(() {
      _placed[l.part] = _placed.containsKey(l.part) ? '${_placed[l.part]} · $word' : word;
      _bank.remove(word);
      _wrong = null;
      _i++;
    });
    if (_i >= _order.length) {
      c.answer(AnswerFeedback(
        _mistakes == 0 ? Verdict.right : Verdict.wrong,
        _mistakes == 0 ? 'Graph labelled!' : 'Graph labelled',
        body: _mistakes == 0 ? 'Every part has its Band 8 word.' : '$_mistakes part${_mistakes == 1 ? '' : 's'} took a second try.',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _i >= _order.length;
    final current = done ? null : labels[_order[_i]];
    return SessionFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(done ? 'All labelled' : 'Which Band 8 word fits the highlighted part?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          ChartCard(child: ChartView(chart: widget.q.topic.learn!.sample, highlight: current?.part, dimOthers: current != null, focusMap: true)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Finished parts are listed here, not drawn on the chart, so labels
          // never pile up on top of each other.
          if (_placed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final w in _placed.values) TagChip('✓ $w', color: const Color(0xFFE6EDCF), textColor: const Color(0xFF4F6414)),
              ]),
            ),
          if (current != null && current.plain.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text('You would write: ${current.plain.join(' / ')}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 14)),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in _bank)
              GestureDetector(
                onTap: () => _pick(w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: w == _wrong ? const Color(0xFFFBEAE5) : AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: w == _wrong ? AppColors.rust : AppColors.line, width: 1.5),
                  ),
                  child: Text(w, style: const TextStyle(fontSize: 15.5)),
                ).animate(target: w == _wrong ? 1 : 0).shakeX(hz: 4, amount: 4, duration: 300.ms),
              ),
          ]),
          if (_wrong != null && current != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Not “$_wrong” here – try another.', style: const TextStyle(color: AppColors.rust, fontSize: 13.5)),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Order the set

class OrderView extends StatefulWidget {
  const OrderView(this.q, {super.key});
  final OrderQ q;
  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  late final List<SetWord> _pool = [...widget.q.words]..shuffle();
  final _slots = <SetWord>[];
  bool _checked = false;

  Future<void> _check() async {
    if (_checked) return;
    setState(() => _checked = true);
    var ok = true;
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].strength != widget.q.words[i].strength) ok = false;
    }
    final c = sessionOf(context);
    await c.record('set-${widget.q.set.id}', correct: ok);
    if (!mounted) return;
    final order = widget.q.words.map((w) => w.w).join(' → ');
    c.answer(ok
        ? AnswerFeedback(Verdict.right, 'Right strength, every time', body: widget.q.set.nouns.isEmpty ? order : 'Nouns: ${widget.q.set.nouns.join(' · ')}')
        : AnswerFeedback(Verdict.wrong, 'Not quite', answer: order, body: 'Small → big. Pick the word whose strength matches the chart.'));
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.q.set;
    final n = widget.q.words.length;
    return SessionFrame(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${set.head} = …', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          const Text('Tap the words from smallest to biggest.', style: TextStyle(fontSize: 14.5)),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: const LinearGradient(colors: [Color(0xFFF6E3C8), AppColors.rust])),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(children: [Text('small', style: TextStyle(fontSize: 12)), Spacer(), Text('big', style: TextStyle(fontSize: 12))]),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          for (var i = 0; i < n; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _checked || i >= _slots.length
                    ? null
                    : () => setState(() {
                          _pool.add(_slots.removeAt(i));
                        }),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: i < _slots.length ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: !_checked || i >= _slots.length
                          ? (i < _slots.length ? Colors.transparent : AppColors.taupe)
                          : (_slots[i].strength == widget.q.words[i].strength ? AppColors.olive : AppColors.rust),
                      width: 1.6,
                    ),
                  ),
                  child: Row(children: [
                    Text('${i + 1}', style: const TextStyle(color: AppColors.inkSoft)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(i < _slots.length ? _slots[i].w : '', style: const TextStyle(fontSize: 17))),
                    if (i < _slots.length && !_checked) const Icon(AppIcons.close, size: 18, color: AppColors.inkSoft),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in _pool)
              ChoiceChipPill(w.w, selected: false, onTap: () => setState(() {
                    _pool.remove(w);
                    _slots.add(w);
                  })),
          ]),
        ],
      ),
      bottom: PillButton('Check', dark: true, onTap: _slots.length == n && !_checked ? _check : null),
    );
  }
}

// ------------------------------------------------------------ Adjective ↔ adverb

class AdjAdvView extends StatefulWidget {
  const AdjAdvView(this.q, {super.key});
  final AdjAdvQ q;
  @override
  State<AdjAdvView> createState() => _AdjAdvViewState();
}

class _AdjAdvViewState extends State<AdjAdvView> {
  int _stage = 0; // 0 = verb + adverb, 1 = adjective + noun
  String? _picked;
  bool _anyWrong = false;
  late List<String> _opts = _optionsFor(0);

  List<String> _optionsFor(int stage) {
    final p = widget.q.pair;
    final others = widget.q.options;
    final l = stage == 0
        ? [p.adv, p.adj, if (others.isNotEmpty) others.first.adv, p.plain]
        : [p.adj, p.adv, if (others.isNotEmpty) others.first.adj, if (others.length > 1) others[1].adj];
    return l.toSet().toList()..shuffle(Random());
  }

  String get _sentence {
    final p = widget.q.pair;
    return _stage == 0 ? p.verbSentence.replaceFirst(p.adv, '___') : p.nounSentence.replaceFirst(p.adj, '___');
  }

  String get _answer => _stage == 0 ? widget.q.pair.adv : widget.q.pair.adj;

  Future<void> _pick(String o) async {
    if (_picked != null) return;
    setState(() => _picked = o);
    final ok = o == _answer;
    if (!ok) _anyWrong = true;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_stage == 0) {
      setState(() {
        _stage = 1;
        _picked = null;
        _opts = _optionsFor(1);
      });
      return;
    }
    final p = widget.q.pair;
    final c = sessionOf(context);
    await c.record(p.entryId ?? 'adj-${p.adj}', correct: !_anyWrong);
    c.answer(AnswerFeedback(
      _anyWrong ? Verdict.wrong : Verdict.right,
      _anyWrong ? 'Two forms, one idea' : 'Both forms right!',
      body: '${p.verbSentence}\n${p.nounSentence}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.q.pair;
    return SessionFrame(
      header: PromptCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_stage == 0 ? 'Verb + adverb' : 'Adjective + noun', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            GapSentence(_sentence, fill: _picked == null ? null : _answer, fillColor: AppColors.olive),
            const SizedBox(height: 8),
            Text('You would write: “${p.plain}”', style: const TextStyle(fontSize: 13.5, color: AppColors.plain)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          for (final o in _opts)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: AnswerCard(
                text: o,
                onTap: () => _pick(o),
                state: _picked == null ? AnswerState.idle : (o == _answer ? AnswerState.right : (o == _picked ? AnswerState.wrong : AnswerState.idle)),
              ),
            ),
        ],
      ),
    );
  }
}
