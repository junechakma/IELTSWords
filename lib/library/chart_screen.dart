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
  bool get _hasLearn => t.learn != null;
  late int _tab = widget.initialSlot == null ? 0 : (_hasLearn ? 1 : 0) + t.task.slots.indexOf(widget.initialSlot!).clamp(0, t.task.slots.length - 1);

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(topicStatsProvider(t.id));
    final tabs = [if (_hasLearn) 'Learn', for (final s in t.task.slots) s.label];

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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, label) in tabs.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChipPill(label, selected: _tab == i, onTap: () => setState(() => _tab = i)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: (_hasLearn && _tab == 0) ? _LearnTab(topic: t) : _SlotTab(topic: t, slot: t.task.slots[_tab - (_hasLearn ? 1 : 0)]),
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

// ------------------------------------------------------------ Slot tabs

class _SlotTab extends ConsumerWidget {
  const _SlotTab({required this.topic, required this.slot});
  final SwapTopic topic;
  final Slot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = topic.bySlot(slot);
    final all = [for (final (_, swaps) in groups) ...swaps];
    final progress = ref.watch(progressProvider);
    var n = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        if (groups.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No swaps here yet.', style: TextStyle(color: AppColors.inkSoft)))),
        for (final (position, swaps) in groups) ...[
          CapsLabel(position.label),
          for (final s in swaps)
            () {
              final index = n++;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SwapRow(
                  swap: s,
                  mastery: progress.mastery(s.id),
                  onTap: () => openSwapDeck(context, all, index),
                ),
              ).animate(delay: (25 * index).ms).fadeIn(duration: 220.ms).moveY(begin: 6, end: 0);
            }(),
        ],
        const SizedBox(height: 8),
        if (all.isNotEmpty) ...[
          PillButton('See them as flashcards', outline: true, onTap: () => openSwapDeck(context, all, 0)),
          const SizedBox(height: 8),
          PillButton(
            'Practise ${topic.title.toLowerCase()} ${slot.label.toLowerCase()}',
            dark: true,
            onTap: () => startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: topic.id, slot: slot)),
          ),
        ],
      ],
    );
  }
}
