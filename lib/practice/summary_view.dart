import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_scope.dart';
import '../state/providers.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import 'practice_mode.dart';
import 'session_builder.dart';
import 'session_controller.dart';
import 'session_screen.dart';
import '../theme/app_icons.dart';

/// End of a session: mascot, what moved, "plain words you still used". No score.
class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.controller, required this.request});
  final SessionController controller;
  final SessionRequest request;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final repo = context.readProvider(repoProvider);
    final perfect = c.mistakes == 0 && c.practised.isNotEmpty;
    final mascot = perfect ? Mascot.perfect : Mascot.pick(Mascot.finished, c.practised.length);
    final noun = c.mode.group == ModeGroup.listening ? 'items' : (c.mode == PracticeMode.meaningMatch || c.mode == PracticeMode.linkerSort || c.mode == PracticeMode.letterRegister ? 'words' : 'swaps');
    final missedSwaps = [for (final id in c.plainUsed) if (repo.swap(id) != null) repo.swap(id)!];
    final missedOther = [for (final id in c.toReview) if (repo.swap(id) == null) id];

    String labelFor(String id) {
      final e = repo.entry(id);
      if (e != null) return e.term;
      for (final i in repo.listening.items) {
        if (i.id == id) return i.term;
      }
      return id;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.sunflowerSoft,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
          ),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 20),
          child: Stack(
            children: [
              if (perfect) const Positioned.fill(child: Confetti()),
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'Close',
                      button: true,
                      child: GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.all(6), child: Icon(AppIcons.close))),
                    ),
                  ),
                  MascotImage(mascot, size: 150, sticker: true)
                      .animate()
                      .scaleXY(begin: .5, end: 1, duration: 600.ms, curve: Curves.elasticOut)
                      .then(delay: 200.ms)
                      .shimmer(duration: 900.ms, color: Colors.white54),
                  const SizedBox(height: 10),
                  Text(perfect ? 'No plain words!' : 'Session done', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${c.title ?? c.mode.title} · ${c.practised.length} $noun practised', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _Stat('⬆ ${c.movedUp.length} moved up')),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat('★ ${c.nowNatural.length} now natural')),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat('${c.toReview.length} to review')),
                    ],
                  ).animate(delay: 250.ms).fadeIn().moveY(begin: 10, end: 0),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            children: [
              if (missedSwaps.isNotEmpty) ...[
                Text('Plain words you still used', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                for (final s in missedSwaps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                      child: SwapText(plain: s.plain, formal: s.best),
                    ),
                  ),
              ],
              if (missedOther.isNotEmpty) ...[
                Text('To look at again', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final id in missedOther) TagChip(labelFor(id))]),
              ],
              if (missedSwaps.isEmpty && missedOther.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    perfect ? 'Every answer was the Band 8 one. They will come back for review in a few days.' : 'Nice work. Missed items come back tomorrow.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.45, color: AppColors.inkSoft),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                if (missedSwaps.isNotEmpty) ...[
                  Expanded(
                    child: PillButton(
                      'Practise these ${missedSwaps.length}',
                      outline: true,
                      onTap: () {
                        final nav = Navigator.of(context);
                        final ctx = nav.context;
                        nav.pop();
                        startPractice(ctx, SessionRequest(PracticeMode.swapIt, swapIds: [for (final s in missedSwaps) s.id], size: math.max(missedSwaps.length, 1)),
                            title: 'Plain words');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: PillButton('Done', dark: true, onTap: () => Navigator.of(context).pop())),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5)),
      );
}
