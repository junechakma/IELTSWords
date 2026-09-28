import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_scope.dart';
import '../data/swap_models.dart';
import '../library/chart_screen.dart';
import '../library/library_screen.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/quick_practice_sheet.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'practice_heatmap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  static const _quickModes = [PracticeMode.swapIt, PracticeMode.buildParagraph, PracticeMode.describe, PracticeMode.spotPlain];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.repo;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');
    final (chart, slot) = repo.todaysPractice(now);
    final swapsToday = chart.swapsIn(slot);

    return ListenableBuilder(
      listenable: Listenable.merge([scope.store, scope.progress]),
      builder: (context, _) {
        final store = scope.store;
        final dueCount = scope.progress.dueIds([for (final s in repo.allSwaps) s.id]).length;

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
                        Text(store.name == null ? greeting : 'Hi, ${store.name}', style: t.headlineMedium),
                        const SizedBox(height: 2),
                        Text('${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}', style: t.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(color: AppColors.sunflower, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(5),
                    child: MascotImage(store.buddy, size: 42),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0),

              const SizedBox(height: 22),

              // Today's practice + Review side card (mockup 3)
              SizedBox(
                height: 238,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: chart.id, slot: slot)),
                        child: _TodayCard(chart: chart, slot: slot, count: swapsToday.length),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Pressable(
                      onTap: () => startPractice(context, const SessionRequest(PracticeMode.review)),
                      child: Container(
                        width: 78,
                        decoration: BoxDecoration(color: AppColors.taupe, borderRadius: BorderRadius.circular(22)),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            const MascotImage(Mascot.thinking, size: 50),
                            if (dueCount > 0)
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                                    child: Text('$dueCount', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Center(
                                child: RotatedBox(quarterTurns: 3, child: Text('Review', style: t.titleLarge?.copyWith(fontSize: 19))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 80.ms).fadeIn(duration: 400.ms).moveY(begin: 12, end: 0),

              const SizedBox(height: 30),

              // Heatmap
              const SectionTitle('Practice map'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                child: PracticeHeatmap(wordsOn: store.wordsOn),
              ),

              const SizedBox(height: 30),

              // Charts board (mockup 4)
              SectionTitle('Charts', action: 'See all', onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()))),
              const SizedBox(height: 12),
              GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  for (final c in repo.charts.take(5)) _ChartTile(c),
                  _AllChartsTile(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()))),
                ],
              ),

              const SizedBox(height: 30),

              // Quick practice (mockup 3)
              SectionTitle('Quick practice', action: 'See all', onAction: () => openQuickPractice(context)),
              const SizedBox(height: 12),
              SizedBox(
                height: 158,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    for (final (i, m) in _quickModes.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: Pressable(onTap: () => startPractice(context, SessionRequest(m)), child: _QuickCard(m))
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
      },
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.chart, required this.slot, required this.count});

  final SwapTopic chart;
  final Slot slot;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.sunflowerSoft, borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          Positioned(right: -40, bottom: -50, child: _circle(210, const Color(0xFFFDD888))),
          Positioned(right: 30, bottom: -80, child: _circle(150, const Color(0xFFFBE3AE))),
          Positioned(right: 4, bottom: 6, child: MascotImage(Mascot.byName(chart.mascot), size: 128, sticker: true, idle: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's practice", style: t.titleLarge?.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 150,
                  child: Text('${chart.title} · ${slot.label}\n$count swaps', style: t.bodyMedium?.copyWith(color: AppColors.ink, height: 1.35)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(30)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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

  static Widget _circle(double d, Color c) =>
      Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _ChartTile extends StatelessWidget {
  const _ChartTile(this.chart);
  final SwapTopic chart;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: chart))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: topicColor(chart.id), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chart.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.2)),
                  const SizedBox(height: 4),
                  Text('${chart.swaps.length} swaps', style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            MascotImage(Mascot.byName(chart.mascot), size: 40),
          ]),
        ),
      );
}

class _AllChartsTile extends StatelessWidget {
  const _AllChartsTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
          alignment: Alignment.center,
          child: const Text('All charts →', style: TextStyle(color: AppColors.sunflower, fontSize: 15.5, fontWeight: FontWeight.w500)),
        ),
      );
}

class _QuickCard extends StatelessWidget {
  const _QuickCard(this.mode);
  final PracticeMode mode;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: 164,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(color: mode.color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -8, top: -8, child: MascotImage(mode.mascot, size: 46, sticker: true)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 34),
                child: Text(mode.title, style: t.titleMedium?.copyWith(fontSize: 15.5, height: 1.2)),
              ),
              const SizedBox(height: 8),
              Text(mode.hint, style: t.bodySmall?.copyWith(color: const Color(0xFF3A3A3A), fontSize: 12.5, height: 1.4)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Text(mode.group.name, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
