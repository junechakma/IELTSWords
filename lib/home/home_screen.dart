import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/swap_models.dart';
import '../library/chart_screen.dart';
import '../library/word_list_screen.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/quick_practice_sheet.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../shell/app_shell.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'practice_heatmap.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final activity = ref.watch(activityProvider);
    final due = ref.watch(dueCountProvider);
    final (chart, slot) = ref.watch(todaysPracticeProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');
    final todaySwaps = chart.swapsIn(slot);
    final today = activity.wordsOn(now);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.name == null ? greeting : 'Hi, ${settings.name}', style: t.headlineMedium),
                    const SizedBox(height: 2),
                    Text('${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
                  ],
                ),
              ),
              Pressable(
                onTap: () => ref.read(tabProvider.notifier).state = 3,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.sunflower, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(5),
                  child: MascotImage(settings.buddy, size: 42),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0),

          const SizedBox(height: 22),

          // Today's practice + Review side card (prototype)
          SizedBox(
            height: 238,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: chart.id, slot: slot)),
                    child: _TodayCard(chart: chart, slot: slot, swaps: todaySwaps),
                  ),
                ),
                const SizedBox(width: 9),
                Pressable(
                  onTap: () => startPractice(context, const SessionRequest(PracticeMode.review)),
                  child: _ReviewCard(due: due),
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 400.ms).moveY(begin: 12, end: 0),

          const SizedBox(height: 12),
          const PairsBanner().animate(delay: 120.ms).fadeIn(duration: 400.ms).moveY(begin: 12, end: 0),

          const SizedBox(height: 30),

          // Practice map
          const SectionTitle('Practice map'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: PracticeHeatmap(wordsOn: activity.wordsOn),
          ),
          if (today >= settings.dailyGoal)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(children: [
                const Icon(AppIcons.sparkle, size: 16, color: AppColors.sunflower),
                const SizedBox(width: 6),
                Text('Daily goal done — $today swaps today', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),

          const SizedBox(height: 30),

          // Charts board (prototype: pill cells joined into L-shapes and circles)
          SectionTitle('Charts', action: 'See all', onAction: () => ref.read(tabProvider.notifier).state = 1),
          const SizedBox(height: 12),
          const _ChartBoard().animate(delay: 150.ms).fadeIn(duration: 400.ms).moveY(begin: 12, end: 0),

          const SizedBox(height: 30),

          // Quick practice
          SectionTitle('Quick practice', action: 'See all', onAction: () => openQuickPractice(context)),
          const SizedBox(height: 12),
          SizedBox(
            height: 158,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final (i, q) in _quick(chart).indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: Pressable(onTap: () => startPractice(context, q.request), child: _QuickCard(q))
                        .animate(delay: (200 + i * 60).ms)
                        .fadeIn(duration: 350.ms)
                        .moveX(begin: 20, end: 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<_Quick> _quick(SwapTopic chart) => [
        const _Quick(PracticeMode.fillGap, 'The figure ___\nto 40%.', 'All charts', Color(0xFFB4541F), SessionRequest(PracticeMode.fillGap)),
        const _Quick(PracticeMode.matchPairs, 'went up ⇄ surged\nshows ⇄ depicts', 'Plain → Band 8', Color(0xFF6B3FC4), SessionRequest(PracticeMode.matchPairs)),
        const _Quick(PracticeMode.typeIt, 'went up a lot\n→ type it', 'Spelling counts', Color(0xFF6B3FC4), SessionRequest(PracticeMode.typeIt)),
        const _Quick(PracticeMode.swapIt, 'went up a lot\n→ surged', 'All charts', Color(0xFFA86A00), SessionRequest(PracticeMode.swapIt)),
        _Quick(PracticeMode.buildParagraph, 'Intro → overview\n→ body', chart.title, const Color(0xFF6B3FC4), SessionRequest(PracticeMode.buildParagraph, topicId: chart.id)),
        const _Quick(PracticeMode.describe, 'Soared, dipped or\nlevelled off?', 'Task 1', Color(0xFFB4541F), SessionRequest(PracticeMode.describe)),
        const _Quick(PracticeMode.spotPlain, 'Tap the words you\nwould normally write', 'Your habits', Color(0xFFC8323F), SessionRequest(PracticeMode.spotPlain)),
        const _Quick(PracticeMode.labelGraph, 'Every part of the\nchart, its word', 'Task 1', Color(0xFFB4541F), SessionRequest(PracticeMode.labelGraph)),
      ];
}

// ------------------------------------------------------------ Today card

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.chart, required this.slot, required this.swaps});
  final SwapTopic chart;
  final Slot slot;
  final List<Swap> swaps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final example = swaps.isEmpty ? null : swaps.first;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.sunflowerSoft, borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          Positioned(right: -40, bottom: -50, child: _circle(210, const Color(0xFFFDD888))),
          Positioned(right: 30, bottom: -80, child: _circle(150, const Color(0xFFFBE3AE))),
          Positioned(right: 2, bottom: 6, child: MascotImage(Mascot.byName(chart.mascot), size: 116, sticker: true, idle: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's practice", style: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${chart.title} · ${slot.label}\n${swaps.length} swaps', style: const TextStyle(fontSize: 14, height: 1.35)),
                if (example != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 170),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .6), borderRadius: BorderRadius.circular(12)),
                    child: SwapText(plain: example.plain, formal: example.best, size: 12.5, maxLines: 2),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(30)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      SizedBox(width: 8),
                      Icon(AppIcons.arrow, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circle(double d, Color c) => Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.due});
  final int due;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      decoration: BoxDecoration(color: AppColors.taupe, borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              const MascotImage(Mascot.thinking, size: 50),
              Expanded(
                child: Center(
                  child: RotatedBox(quarterTurns: 3, child: Text('Review', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19))),
                ),
              ),
            ],
          ),
          if (due > 0)
            Positioned(
              top: 10,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                child: Text('$due', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Chart board

/// The prototype's tile board (mockup 4): two L-shapes made of joined pill
/// cells (line graph, pie chart) with big thin counts, two circles (bar,
/// map), a pill (process) and a dark "more" pill. Laid out on a 343 × 255
/// grid and scaled to the available width.
class _ChartBoard extends ConsumerWidget {
  const _ChartBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoProvider);
    SwapTopic? topic(String id) => repo.topicOrNull(id);
    void open(String id) {
      final t = topic(id);
      if (t != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: t)));
    }

    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / 343;
      Rect r(double x, double y, double w, double h) => Rect.fromLTWH(x * s, y * s, w * s, h * s);

      List<Widget> lShape({required double x, required String id, required Color color, required Color band, required String label}) {
        final t = topic(id);
        return [
          _Pill(rect: r(x, 0, 168, 81), color: color, band: band, onTap: () => open(id)),
          _Pill(rect: r(x + 87, 0, 81, 168), color: color, band: band, onTap: () => open(id)),
          Positioned.fromRect(
            rect: r(x + 4, 4, 74, 74),
            child: IgnorePointer(child: t == null ? const SizedBox() : Center(child: MascotImage(Mascot.byName(t.mascot), size: 66 * s, sticker: true))),
          ),
          Positioned.fromRect(
            rect: r(x + 93, 34, 72, 44),
            child: IgnorePointer(child: Text(label, style: TextStyle(fontSize: 13.5 * s, fontWeight: FontWeight.w600, height: 1.1))),
          ),
          Positioned.fromRect(
            rect: r(x + 87, 84, 81, 80),
            child: IgnorePointer(
              child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${t?.swaps.length ?? 0}', style: TextStyle(fontSize: 44 * s, fontWeight: FontWeight.w300, height: 1, color: AppColors.ink.withValues(alpha: .82))),
                Text('swaps', style: TextStyle(fontSize: 11.5 * s, color: AppColors.ink.withValues(alpha: .65))),
              ])),
            ),
          ),
        ];
      }

      Widget circle({required double x, required double y, required String id, required Color color, required String label}) {
        final t = topic(id);
        return Positioned.fromRect(
          rect: r(x, y, 81, 81),
          child: Pressable(
            onTap: () => open(id),
            child: Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Stack(alignment: Alignment.center, children: [
                if (t != null) Positioned(top: 5 * s, child: MascotImage(Mascot.byName(t.mascot), size: 54 * s)),
                Positioned(bottom: 7 * s, child: Text(label, style: TextStyle(fontSize: 11.5 * s, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        );
      }

      final process = topic('process');
      return SizedBox(
        height: 255 * s,
        child: Stack(
          children: [
            ...lShape(x: 0, id: 'line', color: AppColors.peach, band: const Color(0xFFF3CDAA), label: 'Line\ngraph'),
            ...lShape(x: 174, id: 'pie', color: AppColors.lilac, band: const Color(0xFFE9E4FD), label: 'Pie\nchart'),
            circle(x: 0, y: 87, id: 'bar', color: AppColors.sunflower, label: 'Bar'),
            circle(x: 174, y: 87, id: 'map', color: AppColors.blush, label: 'Map'),
            // Process pill
            Positioned.fromRect(
              rect: r(0, 174, 168, 81),
              child: Pressable(
                onTap: () => open('process'),
                child: Container(
                  padding: EdgeInsets.only(left: 10 * s),
                  decoration: BoxDecoration(color: const Color(0xFFB9CB7C), borderRadius: BorderRadius.circular(41 * s)),
                  child: Row(children: [
                    if (process != null) MascotImage(Mascot.byName(process.mascot), size: 60 * s),
                    SizedBox(width: 6 * s),
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Process\ndiagram', style: TextStyle(fontSize: 13.5 * s, fontWeight: FontWeight.w600, height: 1.1)))),
                  ]),
                ),
              ),
            ),
            // More: table, mixed, Task 2 → Library tab
            Positioned.fromRect(
              rect: r(174, 174, 169, 81),
              child: Pressable(
                onTap: () => ref.read(tabProvider.notifier).state = 1,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(41 * s)),
                  child: Text('Table · Mixed\nTask 2 →',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.sunflower, fontSize: 15 * s, fontWeight: FontWeight.w600, height: 1.25)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// One pill cell with the lighter top band from the prototype.
class _Pill extends StatelessWidget {
  const _Pill({required this.rect, required this.color, required this.band, required this.onTap});
  final Rect rect;
  final Color color, band;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(rect.shortestSide / 2)),
            alignment: Alignment.topCenter,
            child: Container(height: rect.shortestSide * .25, color: band),
          ),
        ),
      );
}

// ------------------------------------------------------------ Quick practice

class _Quick {
  const _Quick(this.mode, this.prompt, this.tag, this.tagColor, this.request);
  final PracticeMode mode;
  final String prompt;
  final String tag;
  final Color tagColor;
  final SessionRequest request;
}

class _QuickCard extends StatelessWidget {
  const _QuickCard(this.q);
  final _Quick q;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(color: q.mode.color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -8, top: -8, child: MascotImage(q.mode.mascot, size: 46, sticker: true)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 34),
                child: Text(q.mode.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.2)),
              ),
              const SizedBox(height: 8),
              Text(q.prompt, style: const TextStyle(color: Color(0xFF3A3A3A), fontSize: 12.5, height: 1.4)),
              const Spacer(),
              Container(
                constraints: const BoxConstraints(maxWidth: 136),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Text(q.tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: q.tagColor, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
