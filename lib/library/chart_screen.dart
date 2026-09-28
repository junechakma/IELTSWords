import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../charts/chart_view.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../progress/spaced_repetition.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'swap_detail_screen.dart';

/// One chart / essay type / letter type: Learn tab, then its slots.
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key, required this.topic, this.initialSlot});
  final SwapTopic topic;
  final Slot? initialSlot;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late int _tab = widget.topic.learn != null ? (widget.initialSlot == null ? 0 : 1 + _slotIndex(widget.initialSlot!)) : _slotIndex(widget.initialSlot ?? widget.topic.task.slots.first);

  int _slotIndex(Slot s) => widget.topic.task.slots.indexOf(s).clamp(0, widget.topic.task.slots.length - 1);

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final hasLearn = t.learn != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                const BackPill(),
                Expanded(child: Text(t.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17))),
                const SizedBox(width: 46),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.task.label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                      Text(t.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                      ListenableBuilder(
                        listenable: AppScope.of(context).progress,
                        builder: (context, _) {
                          final p = AppScope.of(context).progress;
                          final n = t.swaps.length;
                          final natural = t.swaps.where((s) => p.mastery(s.id) == Mastery.natural).length;
                          return Text('$n swaps · $natural natural', style: const TextStyle(fontSize: 13.5));
                        },
                      ),
                    ],
                  ),
                ),
                MascotImage(Mascot.byName(t.mascot), size: 74, sticker: true),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  if (hasLearn) _tabChip('Learn', 0),
                  for (final (i, s) in t.task.slots.indexed) _tabChip(s.label, (hasLearn ? 1 : 0) + i),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: (hasLearn && _tab == 0)
                  ? _LearnTab(topic: t)
                  : _SlotTab(topic: t, slot: t.task.slots[_tab - (hasLearn ? 1 : 0)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int i) {
    final selected = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(color: selected ? AppColors.ink : Colors.white, borderRadius: BorderRadius.circular(20)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 14, color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

class _LearnTab extends StatelessWidget {
  const _LearnTab({required this.topic});
  final SwapTopic topic;

  @override
  Widget build(BuildContext context) {
    final learn = topic.learn!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text('Every part has a Band 8 word — tap “Practise” to label it yourself', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
              ),
              ChartView(chart: learn.sample, labels: {for (final l in learn.labels) l.part: l.word}, labelHeadroom: 24),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final l in learn.labels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(l.word, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                    if (l.also.isNotEmpty) Text(l.also.join(' · '), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                  ]),
                  if (l.plain.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text('instead of: ${l.plain.join(' / ')}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5))),
                  const SizedBox(height: 4),
                  Text(l.sentence, style: const TextStyle(fontSize: 14.5, height: 1.35)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: PillButton('Label the graph yourself', onTap: () => startPractice(context, SessionRequest(PracticeMode.labelGraph, topicId: topic.id))),
        ),
      ],
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({required this.topic, required this.slot});
  final SwapTopic topic;
  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final groups = topic.bySlot(slot);
    final progress = AppScope.of(context).progress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        if (groups.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No swaps here yet.', style: TextStyle(color: AppColors.inkSoft)))),
        for (final (position, swaps) in groups) ...[
          CapsLabel(position.label),
          for (final s in swaps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListenableBuilder(
                listenable: progress,
                builder: (context, _) => SwapRow(
                  swap: s,
                  mastery: progress.mastery(s.id),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SwapDetailScreen(swap: s, topic: topic))),
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PillButton(
            'Practise ${topic.title.toLowerCase()} ${slot.label.toLowerCase()}',
            dark: true,
            onTap: groups.isEmpty ? null : () => startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: topic.id, slot: slot)),
          ),
        ),
      ],
    );
  }
}
