import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/word_set_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Synonym scales (small → big), the no-change set, topic nouns and numbers.
class WordSetsScreen extends StatefulWidget {
  const WordSetsScreen({super.key});
  @override
  State<WordSetsScreen> createState() => _WordSetsScreenState();
}

class _WordSetsScreenState extends State<WordSetsScreen> {
  WordSetGroup _group = WordSetGroup.trends;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final sets = repo.setsIn(_group);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                const BackPill(),
                const Expanded(child: Text('Word sets', textAlign: TextAlign.center, style: TextStyle(fontSize: 17))),
                const SizedBox(width: 46),
              ]),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Groups that mean the same thing. Learn them together.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in WordSetGroup.values)
                    if (repo.setsIn(g).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _group = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(color: _group == g ? AppColors.ink : Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Text(g.label, style: TextStyle(fontSize: 14, color: _group == g ? Colors.white : AppColors.ink)),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [for (final s in sets) Padding(padding: const EdgeInsets.only(bottom: 10), child: _SetCard(s))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard(this.set);
  final WordSet set;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (set.mascot != null) Padding(padding: const EdgeInsets.only(right: 10), child: MascotImage(Mascot.byName(set.mascot), size: 48, sticker: true)),
            Expanded(child: Text('${set.head}${set.scale ? ' = …' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            if (set.scale) const Text('small → big', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ]),
          if (set.scale) ...[
            const SizedBox(height: 10),
            Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: const LinearGradient(colors: [Color(0xFFF6E3C8), AppColors.rust]))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [for (final w in set.ordered) TagChip(w.w, color: AppColors.cream)],
            ),
            if (set.nouns.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Nouns: ${set.nouns.join(' · ')}', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
          ] else if (set.words.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final w in set.words) TagChip(w.w, color: AppColors.cream)]),
            if (set.nouns.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Nouns: ${set.nouns.join(' · ')}', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
          ] else if (set.pairs.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in set.pairs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SwapText(plain: p.plain, formal: p.formal.join(' / '), size: 14.5),
              ),
          ] else if (set.adjAdv.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in set.adjAdv)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${p.adj}  ·  ${p.adv}', style: const TextStyle(fontSize: 14.5)),
              ),
          ],
          if (set.example != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(set.example!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft))),
          if (set.scale) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TagChip('Order the set', color: AppColors.sand, onTap: () => startPractice(context, const SessionRequest(PracticeMode.orderSet))),
            ),
          ],
        ],
      ),
    );
  }
}
