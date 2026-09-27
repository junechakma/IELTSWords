import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/app_store.dart';
import '../data/vocab_repository.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';
import 'practice_heatmap.dart';
import 'section_blobs.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.repo, required this.store});

  final VocabRepository repo;
  final AppStore store;

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming next'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');
    final today = repo.todaysSection(now);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
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
                      Text('${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}', style: t.bodyMedium),
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

            // Today's words + Review side card (mockup 3)
            SizedBox(
              height: 238,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => _soon(context, 'Practice'),
                      child: _TodayCard(title: today.title, code: today.code, words: today.wordCount),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Pressable(
                    onTap: () => _soon(context, 'Review'),
                    child: Container(
                      width: 78,
                      decoration: BoxDecoration(color: AppColors.taupe, borderRadius: BorderRadius.circular(22)),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          const MascotImage(Mascot.thinking, size: 50),
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
            _SectionHeader(title: 'Practice map'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
              child: PracticeHeatmap(wordsOn: store.wordsOn),
            ),

            const SizedBox(height: 30),

            // Sections board (mockup 4)
            _SectionHeader(title: 'Sections', action: 'See all', onAction: () => _soon(context, 'Library')),
            const SizedBox(height: 12),
            SectionBlobs(
              sections: {for (final s in repo.sections) s.code: s},
              totalSections: repo.sections.length,
              onOpen: (code) => _soon(context, code == null ? 'Library' : repo.section(code).title),
            ),

            const SizedBox(height: 30),

            // Quick practice (mockup 3)
            _SectionHeader(title: 'Quick practice', action: 'See all', onAction: () => _soon(context, 'Practice')),
            const SizedBox(height: 12),
            SizedBox(
              height: 158,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final (i, q) in _quick.indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: Pressable(onTap: () => _soon(context, q.title), child: _QuickCard(q))
                          .animate(delay: (200 + i * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .moveX(begin: 20, end: 0),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.title, required this.code, required this.words});

  final String title;
  final String code;
  final int words;

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
          Positioned(right: 4, bottom: 6, child: MascotImage(Mascot.forSection(code), size: 128, sticker: true, idle: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's words", style: t.titleLarge?.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 150,
                  child: Text('$title · $words words', style: t.bodyMedium?.copyWith(color: AppColors.ink, height: 1.35)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: t.titleLarge)),
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: t.bodyMedium?.copyWith(color: AppColors.ink))),
      ],
    );
  }
}

class _Quick {
  const _Quick(this.title, this.prompt, this.tag, this.color, this.tagColor, this.mascot);
  final String title;
  final String prompt;
  final String tag;
  final Color color;
  final Color tagColor;
  final Mascot mascot;
}

const _quick = [
  _Quick('Flashcards', 'Flip the card.\nDo you remember?', 'All words', AppColors.blush, Color(0xFFC8323F), Mascot.focused),
  _Quick('Fill the gap', 'Which word fits\nthe sentence?', 'Task 2', AppColors.lilac, Color(0xFF6B3FC4), Mascot.confused),
  _Quick('Describe a graph', 'Soared, dipped or\nlevelled off?', 'Task 1', AppColors.peach, Color(0xFFB4541F), Mascot.excited),
  _Quick('Linker sort', 'Contrast, result\nor adding?', 'Essays', AppColors.sand, Color(0xFF5E6B2A), Mascot.silly),
];

class _QuickCard extends StatelessWidget {
  const _QuickCard(this.q);
  final _Quick q;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: 164,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(color: q.color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -8, top: -8, child: MascotImage(q.mascot, size: 46, sticker: true)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 34),
                child: Text(q.title, style: t.titleMedium?.copyWith(fontSize: 15.5, height: 1.2)),
              ),
              const SizedBox(height: 8),
              Text(q.prompt, style: t.bodySmall?.copyWith(color: const Color(0xFF3A3A3A), fontSize: 12.5, height: 1.4)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Text(q.tag, style: TextStyle(fontSize: 12.5, color: q.tagColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
