import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/swap_models.dart';
import '../home/practice_heatmap.dart';
import '../library/chart_screen.dart';
import '../library/swap_deck_screen.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../progress/spaced_repetition.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

/// Year heatmap, mastery bars (New · Seen · Using · Natural), saved swaps and
/// progress per chart / essay / letter type. Everything is read from
/// providers, so it updates the moment a practice answer is recorded.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final repo = ref.watch(repoProvider);
    final activity = ref.watch(activityProvider);
    final progress = ref.watch(progressProvider);
    final counts = ref.watch(masteryCountsProvider);
    final total = repo.totalSwaps;
    final saved = [for (final id in progress.saved) if (repo.swap(id) != null) repo.swap(id)!];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Text('Progress', style: t.headlineMedium),
          const SizedBox(height: 16),

          // Headline numbers — no scores, just what you've done.
          Row(children: [
            Expanded(child: _Stat(value: '${activity.daysPractised()}', label: 'days practised', color: AppColors.sunflowerSoft)),
            const SizedBox(width: 8),
            Expanded(child: _Stat(value: '${activity.total}', label: 'swaps practised', color: AppColors.lilac)),
            const SizedBox(width: 8),
            Expanded(child: _Stat(value: '${counts[Mastery.natural] ?? 0}', label: 'feel natural', color: const Color(0xFFD8E4B0))),
          ]).animate().fadeIn(duration: 300.ms).moveY(begin: 8, end: 0),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                PracticeHeatmap(wordsOn: activity.wordsOn, weeks: 36),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mastery', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 14),
                  child: Text('How natural the $total Band 8 swaps feel', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ),
                Row(children: [for (final (i, m) in Mastery.values.indexed) Expanded(child: _MasteryBar(m, counts[m] ?? 0, total, delay: i * 90))]),
              ],
            ),
          ),

          if (saved.isNotEmpty) ...[
            const SizedBox(height: 12),
            Pressable(
              onTap: () => openSwapDeck(context, saved, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  const Icon(AppIcons.heartOn, color: AppColors.rust),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Saved swaps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${saved.length} to revise as flashcards', style: const TextStyle(fontSize: 12.5)),
                    ]),
                  ),
                  const Icon(AppIcons.chevron),
                ]),
              ),
            ),
          ],

          for (final (label, kind) in const [('Charts', TaskKind.task1), ('Essays', TaskKind.task2), ('Letters', TaskKind.letters)])
            if (repo.topicsFor(kind).isNotEmpty) ...[
              CapsLabel(label, padding: const EdgeInsets.fromLTRB(2, 20, 0, 8)),
              for (final topic in repo.topicsFor(kind)) _TopicRow(topic),
            ],

          const SizedBox(height: 16),
          PillButton('Start a review session', onTap: () => startPractice(context, const SessionRequest(PracticeMode.review))),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w300, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, height: 1.2)),
        ]),
      );
}

class _TopicRow extends ConsumerWidget {
  const _TopicRow(this.topic);
  final SwapTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(topicStatsProvider(topic.id));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: topic))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: topicColor(topic.id), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: MascotImage(Mascot.byName(topic.mascot), size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(topic.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: s.share),
                    duration: const Duration(milliseconds: 600),
                    builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 7, backgroundColor: AppColors.cream, color: AppColors.olive),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Text(s.isNew ? 'New' : '${s.percent}%', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  const _MasteryBar(this.mastery, this.count, this.total, {this.delay = 0});
  final Mastery mastery;
  final int count, total, delay;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;
    final dark = mastery != Mastery.newItem;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(40)),
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share.clamp(.2, 1)),
              duration: Duration(milliseconds: 700 + delay),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                heightFactor: v,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: masteryColor(mastery), borderRadius: BorderRadius.circular(40)),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark ? Colors.white : AppColors.ink)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(mastery.label, style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}
