import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_scope.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../progress/spaced_repetition.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_glyph.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'chart_screen.dart';
import 'listening_screen.dart';
import 'swap_deck_screen.dart';
import 'word_sets_screen.dart';

/// Library: browse every chart / essay / letter type, plus Word sets and
/// Listening maps (prototype: coloured cards with a chart glyph, count and a
/// sticker mascot).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _task = 0;
  String _query = '';

  static const _tabs = [TaskKind.task1, TaskKind.task2, TaskKind.letters];
  static const _tabLabels = ['Charts', 'Essays', 'Letters'];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.repo;
    final t = Theme.of(context).textTheme;
    final searching = _query.trim().isNotEmpty;
    final results = searching ? repo.searchSwaps(_query) : const <Swap>[];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Text('Library', style: t.headlineMedium),
          const SizedBox(height: 16),
          Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 21, color: AppColors.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search “shows”, “went up”…', hintStyle: TextStyle(color: AppColors.inkSoft), isDense: true),
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (searching) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
              child: Text('${results.length} swap${results.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ),
            for (final (i, s) in results.take(40).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListenableBuilder(
                  listenable: scope.progress,
                  builder: (context, _) => SwapRow(
                    swap: s,
                    mastery: scope.progress.mastery(s.id),
                    subtitle: '${repo.topic(s.topicId).title} · ${s.slot.label}',
                    onTap: () => openSwapDeck(context, results.take(40).toList(), i),
                  ),
                ),
              ),
          ] else ...[
            // Segmented control (prototype: grey track, dark selected pill).
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE9E4DA), borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                for (final (i, label) in _tabLabels.indexed)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _task = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _task == i ? AppColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _task == i ? Colors.white : AppColors.ink)),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.32,
              children: [
                for (final (i, topic) in repo.topicsFor(_tabs[_task]).indexed)
                  _TopicCard(topic: topic).animate(key: ValueKey('${_task}_$i'), delay: (40 * i).ms).fadeIn(duration: 250.ms).moveY(begin: 10, end: 0),
              ],
            ),
            const SizedBox(height: 22),
            _WideCard(
              title: 'Word sets',
              subtitle: 'Increase = climb · surge · soar\nsmall → big, topic nouns',
              mascot: Mascot.thinking,
              color: AppColors.lilac,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WordSetsScreen())),
            ),
            const SizedBox(height: 10),
            _WideCard(
              title: 'Listening maps',
              subtitle: 'opposite · next to · at the far end\ndirections and traps',
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});
  final SwapTopic topic;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChartScreen(topic: topic))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: topicColor(topic.id), borderRadius: BorderRadius.circular(22)),
        child: Stack(
          children: [
            Positioned(right: 2, bottom: 2, child: MascotImage(Mascot.byName(topic.mascot), size: 58, sticker: true)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 62, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChartGlyph(topic.id, fallback: topicIcon(topic.id)),
                  const Spacer(),
                  Text(topic.title, maxLines: 2, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.15)),
                  const SizedBox(height: 3),
                  ListenableBuilder(
                    listenable: progress,
                    builder: (context, _) {
                      final ids = [for (final s in topic.swaps) s.id];
                      final seen = ids.where((id) => progress.mastery(id) != Mastery.newItem).length;
                      final pct = (progress.share(ids) * 100).round();
                      return Text(
                        seen == 0 ? '${ids.length} swaps · New' : '${ids.length} swaps · $pct%',
                        style: TextStyle(fontSize: 12.5, color: AppColors.ink.withValues(alpha: .72)),
                      );
                    },
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
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.ink.withValues(alpha: .75))),
              ]),
            ),
            MascotImage(mascot, size: 66, sticker: true),
          ]),
        ),
      );
}
