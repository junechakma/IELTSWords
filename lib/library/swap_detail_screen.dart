import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// One swap, on its own: plain → Band 8, where to use it, both sentences.
class SwapDetailScreen extends StatelessWidget {
  const SwapDetailScreen({super.key, required this.swap, required this.topic});
  final Swap swap;
  final SwapTopic topic;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Row(children: [
              const BackPill(),
              const Spacer(),
              ListenableBuilder(
                listenable: progress,
                builder: (context, _) => RoundIconButton(
                  icon: progress.isSaved(swap.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: progress.isSaved(swap.id) ? AppColors.rust : AppColors.ink,
                  tooltip: 'Save',
                  onTap: () => progress.toggleSaved(swap.id),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.volume_up_rounded,
                tooltip: 'Hear it',
                onTap: () => Speech.instance.speak(swap.formalSentence),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: topicColor(topic.id), borderRadius: BorderRadius.circular(28)),
              child: Stack(
                children: [
                  Positioned(right: -6, bottom: -6, child: MascotImage(Mascot.byName(topic.mascot), size: 88, sticker: true)),
                  Padding(
                    padding: const EdgeInsets.only(right: 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(swap.plain, style: const TextStyle(fontSize: 17, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough)),
                        const SizedBox(height: 2),
                        Text(swap.best, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.1)),
                        if (swap.also.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('also: ${swap.also.join(' · ')}', style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const CapsLabel('Where to use it', padding: EdgeInsets.only(left: 2, bottom: 8)),
            Wrap(spacing: 8, runSpacing: 8, children: [TagChip('${topic.title} · ${swap.slot.label}', color: AppColors.ink, textColor: Colors.white), TagChip(swap.position.label)]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOU’D WRITE', style: TextStyle(fontSize: 11.5, letterSpacing: .6, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(swap.plainSentence, style: const TextStyle(fontSize: 15.5, height: 1.4, color: AppColors.inkSoft)),
                  const Divider(height: 26, color: AppColors.line),
                  const Text('BAND 8', style: TextStyle(fontSize: 11.5, letterSpacing: .6, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(swap.formalSentence, style: const TextStyle(fontSize: 16.5, height: 1.4)),
                  if (swap.note != null) ...[
                    const SizedBox(height: 10),
                    Text(swap.note!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: progress,
              builder: (context, _) {
                final p = progress.of(swap.id);
                return Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.taupe, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your level', style: TextStyle(fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text(p.mastery.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(children: [for (var i = 0; i < 5; i++) Expanded(child: Container(margin: const EdgeInsets.only(right: 4), height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: i < p.box ? AppColors.cocoa : Colors.white.withValues(alpha: .6))))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.lilac, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Next review', style: TextStyle(fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text(p.due == null ? '—' : _dueLabel(p.due!), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PillButton('Practise this swap', dark: true, onTap: () => startPractice(context, SessionRequest(PracticeMode.swapIt, swapIds: [swap.id], size: 1))),
            ),
          ],
        ),
      ),
    );
  }

  static String _dueLabel(DateTime d) {
    final days = d.difference(DateTime.now()).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'in 1 day';
    return 'in $days days';
  }
}
