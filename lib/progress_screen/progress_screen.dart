import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../home/practice_heatmap.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../progress/spaced_repetition.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([scope.store, scope.progress]),
      builder: (context, _) {
        final ids = [for (final s in scope.repo.allSwaps) s.id];
        final counts = scope.progress.masteryCounts(ids);

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
            children: [
              Text('Progress', style: t.headlineMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(child: Text('This year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                      Text('${scope.store.daysPractised()} days practised', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    ]),
                    const SizedBox(height: 10),
                    PracticeHeatmap(wordsOn: scope.store.wordsOn, weeks: 36),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mastery', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                    const Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 12),
                      child: Text('How natural the Band 8 swaps feel', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    ),
                    Row(children: [for (final m in Mastery.values) Expanded(child: _MasteryBar(m, counts[m] ?? 0, ids.length))]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const CapsLabel('By chart', padding: EdgeInsets.only(left: 2, bottom: 8)),
              for (final chart in scope.repo.charts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      MascotImage(Mascot.byName(chart.mascot), size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: Text(chart.title)),
                      SizedBox(
                        width: 90,
                        height: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: scope.progress.share([for (final s in chart.swaps) s.id]),
                            backgroundColor: AppColors.cream,
                            color: AppColors.olive,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PillButton('Start a new session', onTap: () => startPractice(context, const SessionRequest(PracticeMode.review))),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MasteryBar extends StatelessWidget {
  const _MasteryBar(this.mastery, this.count, this.total);
  final Mastery mastery;
  final int count, total;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;
    final color = masteryColor(mastery);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$count', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: share.clamp(.04, 1),
                    alignment: Alignment.bottomCenter,
                    child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(mastery.label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
