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
import 'progress_charts.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

/// Streak, learned, mistakes and right-answer stats, today's review, the
/// practice heatmap, how-well-you-know-it bars, most-missed words, saved swaps
/// and progress per chart / essay / letter type. Everything is read from
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
    final today = ref.watch(clockProvider)();

    // Every answer ever recorded (swaps, word sets, listening).
    var answers = 0, mistakes = 0;
    for (final p in progress.items.values) {
      answers += p.seen;
      mistakes += p.wrong;
    }
    final rightPct = answers == 0 ? null : ((answers - mistakes) * 100 / answers).round();
    final due = progress.dueIds(ref.watch(allSwapIdsProvider));
    final missed = [for (final s in repo.allSwaps) if (progress.of(s.id).wrong > 0) s]
      ..sort((a, b) => progress.of(b.id).wrong.compareTo(progress.of(a.id).wrong));
    final topMissed = missed.take(5).toList();

    // Last 7 days of practice, and reviews coming up in the next 7 (anything
    // overdue counts as today).
    final day0 = SpacedRepetition.dayOf(today);
    final week = [for (var i = 6; i >= 0; i--) day0.subtract(Duration(days: i))];
    final ahead = [for (var i = 0; i < 7; i++) day0.add(Duration(days: i))];
    final reviews = List.filled(7, 0);
    for (final s in repo.allSwaps) {
      final d = progress.of(s.id).due;
      if (d == null) continue;
      final i = SpacedRepetition.dayOf(d).difference(day0).inDays;
      if (i < 7) reviews[i < 0 ? 0 : i]++;
    }

    // Wrong answers grouped by topic and by paragraph part.
    MistakeRow rowOf(String label, Iterable<String> ids) {
      var a = 0, w = 0;
      for (final id in ids) {
        a += progress.of(id).seen;
        w += progress.of(id).wrong;
      }
      return MistakeRow(label, a, w);
    }
    final byTopic = [for (final t in repo.topics) rowOf(t.title, [for (final s in t.swaps) s.id])];
    final byPart = [for (final slot in Slot.values) rowOf(slot.label, [for (final s in repo.allSwaps) if (s.slot == slot) s.id])];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Text('Progress', style: t.headlineMedium),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: _Stat(value: '${activity.streak(today: today)}', label: 'day streak\nin a row', color: AppColors.sunflowerSoft)),
            const SizedBox(width: 8),
            Expanded(child: _Stat(value: '${counts[Mastery.natural] ?? 0}', label: 'words learned\nof $total', color: const Color(0xFFD8E4B0))),
          ]).animate().fadeIn(duration: 300.ms).moveY(begin: 8, end: 0),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _Stat(value: '$mistakes', label: 'mistakes\nin total', color: AppColors.blush)),
            const SizedBox(width: 8),
            Expanded(child: _Stat(value: rightPct == null ? '–' : '$rightPct%', label: 'answers right\n$answers answered', color: AppColors.lilac)),
          ]).animate().fadeIn(duration: 300.ms, delay: 80.ms).moveY(begin: 8, end: 0),
          const SizedBox(height: 12),

          Pressable(
            onTap: () => startPractice(context, const SessionRequest(PracticeMode.review)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const Icon(AppIcons.timer, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(due.isEmpty ? 'Nothing to review today' : '${due.length} words to review today',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(due.isEmpty ? 'Come back tomorrow, or practise something new' : 'Review now so you don\'t forget them',
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                  ]),
                ),
                const Icon(AppIcons.chevron, color: Colors.white),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Days you practised', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: Text('${activity.lastWeek(today: today)} words this week · ${activity.daysPractised(today: today)} days this year',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ),
                PracticeHeatmap(wordsOn: activity.wordsOn, weeks: 36),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ChartCard(
            title: 'Last 7 days',
            subtitle: 'Words practised each day · tap a bar',
            child: DayBars(values: [for (final d in week) activity.wordsOn(d)], labels: [for (final d in week) dayLabel(d, today)], color: AppColors.olive, unit: 'words', highlight: 6),
          ),
          const SizedBox(height: 12),

          ChartCard(
            title: 'Coming reviews',
            subtitle: 'Words due for review in the next 7 days',
            child: DayBars(values: reviews, labels: [for (final d in ahead) dayLabel(d, today)], color: AppColors.sunflower, unit: 'due'),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How well you know your words', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 14),
                  child: Text('All $total Band 8 words, grouped by how well you know them', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ),
                Row(children: [for (final (i, m) in Mastery.values.indexed) Expanded(child: _MasteryBar(m, counts[m] ?? 0, total, delay: i * 90))]),
              ],
            ),
          ),

          const SizedBox(height: 12),
          ChartCard(
            title: 'Where you make mistakes',
            subtitle: 'Share of your answers that were wrong, worst first',
            child: MistakeBars(groups: {'By topic': byTopic, 'By paragraph part': byPart}),
          ),

          if (topMissed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Words you often get wrong', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 10),
                    child: Text('Plain word → Band 8 word', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                  ),
                  for (final s in topMissed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: s.plain, style: const TextStyle(color: AppColors.inkSoft)),
                            const TextSpan(text: '  →  '),
                            TextSpan(text: s.formal.first, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]), style: const TextStyle(fontSize: 14.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(10)),
                          child: Text('${progress.of(s.id).wrong}× wrong', style: const TextStyle(fontSize: 12, color: AppColors.rust, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  PillButton('Practise these ${missed.length > 20 ? 20 : missed.length}',
                      height: 46,
                      onTap: () => startPractice(context, SessionRequest(PracticeMode.fillGap, swapIds: [for (final s in missed.take(20)) s.id], size: missed.length.clamp(1, 20)))),
                ],
              ),
            ),
          ],

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
          Text(mastery.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(mastery.hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.2, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
