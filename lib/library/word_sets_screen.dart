import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_set_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../theme/app_theme.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'word_set_deck_screen.dart';

/// Synonym scales (small → big), the no-change set, topic nouns and numbers.
class WordSetsScreen extends ConsumerStatefulWidget {
  const WordSetsScreen({super.key});
  @override
  ConsumerState<WordSetsScreen> createState() => _WordSetsScreenState();
}

class _WordSetsScreenState extends ConsumerState<WordSetsScreen> {
  WordSetGroup _group = WordSetGroup.trends;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final sets = repo.setsIn(_group);
    final cards = setCards(sets);
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
                children: [
                  if (cards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PillButton('See ${_group.label.toLowerCase()} as flashcards · ${cards.length}', icon: AppIcons.cards, onTap: () => openWordSetDeck(context, cards, 0)),
                    ),
                  for (final s in sets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SetCard(s, onTap: () => openWordSetDeck(context, cards, cards.indexWhere((c) => c.set.id == s.id).clamp(0, cards.length - 1))),
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

class _SetCard extends StatelessWidget {
  const _SetCard(this.set, {required this.onTap});
  final WordSet set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
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
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TagChip('▶ Flashcards', color: AppColors.lilac, onTap: onTap),
            if (set.scale) ...[
              const SizedBox(width: 6),
              TagChip('Order the set', color: AppColors.sand, onTap: () => startPractice(context, const SessionRequest(PracticeMode.orderSet))),
            ],
          ]),
        ],
      ),
      ),
    );
  }
}
