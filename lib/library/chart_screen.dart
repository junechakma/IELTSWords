import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../charts/chart_view.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/flow_widgets.dart';
import '../data/flow.dart';
import 'swap_deck_screen.dart';

/// One chart / essay type / letter type: a coloured header (prototype),
/// then a Learn tab and one tab per paragraph slot.
class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key, required this.topic, this.initialSlot});
  final SwapTopic topic;
  final Slot? initialSlot;

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  SwapTopic get t => widget.topic;
  // Tabs: Learn (charts), Full answer (model answer), then one per paragraph.
  late final List<(String, Slot?)> _tabs = [
    if (t.learn != null) ('Learn', null),
    if (t.report != null) ('Full answer', null),
    for (final s in t.task.slots) (s.label, s),
  ];
  late int _tab = widget.initialSlot == null ? 0 : _tabs.indexWhere((x) => x.$2 == widget.initialSlot).clamp(0, _tabs.length - 1);

  late final _tabKeys = [for (var i = 0; i < _tabs.length; i++) GlobalKey()];

  /// Selects tab [i] and scrolls its chip into view.
  void _select(int i) {
    setState(() => _tab = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tabKeys[i].currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: .5, duration: const Duration(milliseconds: 250));
    });
  }

  void _goToSlot(Slot s) => _select(_tabs.indexWhere((x) => x.$2 == s).clamp(0, _tabs.length - 1));

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(topicStatsProvider(t.id));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Coloured header band with a wavy edge (prototype chart screen).
          ClipPath(
            clipper: const WaveClipper(),
            child: Container(
              color: topicColor(t.id),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackPill(),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.task.label, style: TextStyle(fontSize: 13, color: AppColors.ink.withValues(alpha: .7))),
                            Text(t.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.1)),
                            const SizedBox(height: 6),
                            Text('${stats.total} swaps · ${stats.natural} natural · ${stats.percent}% in use', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      MascotImage(Mascot.byName(t.mascot), size: 108, sticker: true, idle: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final (i, (label, _)) in _tabs.indexed)
                  Padding(
                    key: _tabKeys[i],
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChipPill(label, selected: _tab == i, onTap: () => _select(i)),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tabs[_tab]) {
                  ('Learn', null) => _LearnTab(topic: t),
                  (_, null) => _AnswerTab(topic: t, onSlot: _goToSlot),
                  (_, final Slot slot) => _SlotTab(topic: t, slot: slot, onSlot: _goToSlot),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Learn tab

/// The annotated chart, one part at a time: swipe the word cards and the
/// chart highlights (and labels) only that part, so labels never pile up.
/// Tap a part of the chart to jump to its card; tap an alternative word to
/// see that variant on the chart.
class _LearnTab extends StatefulWidget {
  const _LearnTab({required this.topic});
  final SwapTopic topic;
  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  final _pager = PageController(viewportFraction: .9);
  int _i = 0;
  final _variant = <int, String>{}; // card index → alternative word chosen

  static const _cast = [Mascot.excited, Mascot.thinking, Mascot.playful, Mascot.focused, Mascot.cheerful, Mascot.confident, Mascot.kind, Mascot.friendly];
  static const _tints = [Color(0xFFFFF1D6), Color(0xFFF3EEFF), Color(0xFFFDE9E4), Color(0xFFEFF4DF)];

  Learn get learn => widget.topic.learn!;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _go(int i) => _pager.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final labels = learn.labels;
    final cur = labels[_i];
    final word = _variant[_i] ?? cur.word;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Every part has a Band 8 word', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Text('Swipe the cards or tap the chart', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ChartView(
                  key: ValueKey('$_i$word'),
                  chart: learn.sample,
                  highlight: cur.part,
                  labels: {cur.part: word},
                  selected: cur.part,
                  dimOthers: true,
                  labelHeadroom: 26,
                  onTapPart: (part) {
                    final j = labels.indexWhere((l) => l.part == part);
                    if (j >= 0) _go(j);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _pager,
            itemCount: labels.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _LabelCard(
                label: labels[i],
                word: _variant[i] ?? labels[i].word,
                mascot: _cast[i % _cast.length],
                tint: _tints[i % _tints.length],
                onVariant: (w) => setState(() => w == labels[i].word ? _variant.remove(i) : _variant[i] = w),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                onTap: () => _go(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(color: i == _i ? AppColors.ink : const Color(0xFFD6CFC4), borderRadius: BorderRadius.circular(4)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PillButton('Label the graph yourself', onTap: () => startPractice(context, SessionRequest(PracticeMode.labelGraph, topicId: widget.topic.id))),
      ],
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({required this.label, required this.word, required this.mascot, required this.tint, required this.onVariant});
  final LearnLabel label;
  final String word;
  final Mascot mascot;
  final Color tint;
  final ValueChanged<String> onVariant;

  @override
  Widget build(BuildContext context) {
    final variants = [label.word, ...label.also];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Positioned(right: 4, top: 4, child: MascotImage(mascot, size: 70, sticker: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label.plain.isNotEmpty)
                        Text(label.plain.join(' / '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust)),
                      Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final v in variants)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChipPill(v, selected: v == word, onTap: () => onVariant(v)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: Text(label.sentence, style: const TextStyle(fontSize: 15, height: 1.4), overflow: TextOverflow.fade)),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () => Speech.instance.speak(label.sentence),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(AppIcons.speak, size: 18),
                      SizedBox(width: 4),
                      Text('Hear it', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Full answer

/// The whole model answer, paragraph by paragraph, so you see how Intro →
/// Overview → Body 1 → Body 2 fit together. Band 8 words are highlighted;
/// tap a paragraph to open its flow.
class _AnswerTab extends StatelessWidget {
  const _AnswerTab({required this.topic, required this.onSlot});
  final SwapTopic topic;
  final ValueChanged<Slot> onSlot;

  @override
  Widget build(BuildContext context) {
    final report = topic.report!;
    final phrases = [for (final s in topic.swaps) ...s.formal];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: topicColor(topic.id).withValues(alpha: .45), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CapsLabel('The question', padding: EdgeInsets.only(bottom: 6)),
            Text(report.question, style: const TextStyle(fontSize: 14.5, height: 1.45, fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(AppIcons.sparkle, size: 15, color: AppColors.sunflower),
          const SizedBox(width: 6),
          Expanded(child: Text('Band 8 swaps are highlighted · ${report.wordCount} words', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
        ]),
        const SizedBox(height: 8),
        for (final (i, p) in report.paragraphs.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onSlot(p.slot),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Text(p.slot.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const Text('See flow', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    const Icon(AppIcons.chevron, size: 16),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 2, bottom: 8),
                    child: Text(slotPurpose(topic.task, p.slot), style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                  ),
                  ParagraphText(paragraph: p, highlights: phrases, size: 15.5),
                ]),
              ),
            ).animate(delay: (70 * i).ms).fadeIn(duration: 260.ms).moveY(begin: 8, end: 0),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ Paragraph flow

/// One paragraph as a flow: where it sits in the answer, the model
/// paragraph, then a numbered path ① Opening → ② Middle → ③ Closing. Each
/// step says what that sentence does, shows the model sentence, and lists
/// the swaps you use there (tap one for its flashcards).
class _SlotTab extends ConsumerWidget {
  const _SlotTab({required this.topic, required this.slot, required this.onSlot});
  final SwapTopic topic;
  final Slot slot;
  final ValueChanged<Slot> onSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = topic.bySlot(slot);
    final all = [for (final (_, swaps) in groups) ...swaps];
    final progress = ref.watch(progressProvider);
    final para = topic.report?.paragraph(slot);
    final phrases = [for (final s in all) ...s.formal];
    final positions = [
      for (final p in Position.values)
        if (groups.any((g) => g.$1 == p) || (para?.steps.any((s) => s.position == p) ?? false)) p,
    ];
    final slots = topic.task.slots;
    final idx = slots.indexOf(slot);
    var n = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        SlotFlowBar(task: topic.task, current: slot, onTap: onSlot),
        const SizedBox(height: 10),
        Text(slotPurpose(topic.task, slot), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        if (para != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CapsLabel('Model paragraph', padding: EdgeInsets.only(bottom: 6)),
              ParagraphText(paragraph: para, highlights: phrases, size: 15.5),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        // The numbered path through the paragraph.
        for (final (pi, pos) in positions.indexed) ...[
          () {
            final swaps = [for (final (p, list) in groups) if (p == pos) ...list];
            final model = para?.steps.where((s) => s.position == pos).map((s) => s.best).join(' ');
            final last = pi == positions.length - 1;
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Rail: numbered dot + connecting line.
                SizedBox(
                  width: 34,
                  child: Column(children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: topicColor(topic.id), shape: BoxShape.circle, border: Border.all(color: AppColors.ink, width: 1.5)),
                      child: Text('${pi + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.ink.withValues(alpha: .25))),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(pos.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      Text(positionPurpose(topic.task, slot, pos), style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                      if (model != null && model.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: topicColor(topic.id).withValues(alpha: .35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 14.5, height: 1.45), children: [
                            for (final (text, hi) in highlightRuns(model, phrases))
                              TextSpan(text: text, style: hi ? const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0xFFFDE6B0)) : null),
                          ])),
                        ),
                      ],
                      if (swaps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Swaps for this sentence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink.withValues(alpha: .6))),
                        const SizedBox(height: 6),
                        for (final s in swaps)
                          () {
                            final index = n++;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: SwapRow(swap: s, mastery: progress.mastery(s.id), onTap: () => openSwapDeck(context, all, index)),
                            );
                          }(),
                      ],
                    ]),
                  ),
                ),
              ]),
            ).animate(delay: (80 * pi).ms).fadeIn(duration: 260.ms).moveY(begin: 8, end: 0);
          }(),
        ],
        const SizedBox(height: 16),
        if (all.isNotEmpty) ...[
          PillButton('See these ${all.length} as flashcards', outline: true, icon: AppIcons.cards, onTap: () => openSwapDeck(context, all, 0)),
          const SizedBox(height: 8),
          PillButton(
            'Practise the ${slot.label.toLowerCase()}',
            dark: true,
            onTap: () => startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: topic.id, slot: slot)),
          ),
        ],
        if (idx < slots.length - 1) ...[
          const SizedBox(height: 8),
          PillButton('Next: ${slots[idx + 1].label}', outline: true, icon: AppIcons.arrow, onTap: () => onSlot(slots[idx + 1])),
        ],
      ],
    );
  }
}
