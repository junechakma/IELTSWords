import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../progress/spaced_repetition.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'chart_screen.dart';
import 'listening_screen.dart';
import 'word_sets_screen.dart';

/// Library: browse every chart/essay/letter type, plus Word sets and Listening.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _task = 0; // 0 Task 1, 1 Task 2, 2 Letters
  String _query = '';

  static const _tabs = [TaskKind.task1, TaskKind.task2, TaskKind.letters];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.repo;
    final t = Theme.of(context).textTheme;
    final searching = _query.trim().isNotEmpty;
    final results = searching ? repo.searchSwaps(_query) : const [];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Text('Library', style: t.headlineMedium),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 20, color: AppColors.inkSoft),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search “shows”, “went up”…', isDense: true),
                  style: const TextStyle(fontSize: 15),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          if (searching) ...[
            Text('${results.length} result${results.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            const SizedBox(height: 10),
            for (final s in results.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListenableBuilder(
                  listenable: scope.progress,
                  builder: (context, _) => SwapRow(
                    swap: s,
                    mastery: scope.progress.mastery(s.id),
                    subtitle: '${repo.topic(s.topicId).title} · ${s.slot.label}',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: repo.topic(s.topicId), initialSlot: s.slot))),
                  ),
                ),
              ),
          ] else ...[
            Row(children: [
              for (final (i, k) in _tabs.indexed)
                Expanded(
                  child: Pressable(
                    onTap: () => setState(() => _task = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _task == i ? AppColors.ink : Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Text(k.label, style: TextStyle(fontSize: 13.5, color: _task == i ? Colors.white : AppColors.ink)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .92,
              children: [for (final topic in repo.topicsFor(_tabs[_task])) _TopicTile(topic: topic)],
            ),
            const SizedBox(height: 26),
            SectionTitle('More'),
            const SizedBox(height: 12),
            _WideCard(
              title: 'Word sets',
              subtitle: 'Synonyms, small → big, topic nouns',
              mascot: Mascot.thinking,
              color: AppColors.lilac,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WordSetsScreen())),
            ),
            const SizedBox(height: 10),
            _WideCard(
              title: 'Listening maps',
              subtitle: 'Directions, positions, traps',
              mascot: Mascot.peaceful,
              color: const Color(0xFF9CC7E4),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ListeningScreen())),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});
  final SwapTopic topic;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: topic))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: topicColor(topic.id), borderRadius: BorderRadius.circular(22)),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -6,
              child: MascotImage(Mascot.byName(topic.mascot), size: 52, sticker: true),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(topicIcon(topic.id), size: 20, color: AppColors.ink),
                const SizedBox(height: 8),
                Text(topic.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.15)),
                const Spacer(),
                ListenableBuilder(
                  listenable: progress,
                  builder: (context, _) {
                    final n = topic.swaps.length;
                    final natural = topic.swaps.where((s) => progress.mastery(s.id) == Mastery.natural).length;
                    return Text(n == 0 ? 'New' : '$n swaps · $natural natural', style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({required this.title, required this.subtitle, required this.mascot, required this.color, required this.onTap});
  final String title, subtitle;
  final Mascot mascot;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            MascotImage(mascot, size: 54, sticker: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ]),
        ),
      );
}
