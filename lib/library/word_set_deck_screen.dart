import 'package:flutter/material.dart';

import '../data/word_set_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/flash_deck.dart';
import '../widgets/strength_ladder.dart';
import '../theme/app_icons.dart';

/// One flashcard made from a word set: a whole synonym set, one topic-noun
/// pair, or one adjective/adverb pair.
sealed class SetCard {
  const SetCard(this.set);
  final WordSet set;
}

class WordsCard extends SetCard {
  const WordsCard(super.set);
}

class PairCard extends SetCard {
  const PairCard(super.set, this.pair);
  final TopicPair pair;
}

class AdjAdvCard extends SetCard {
  const AdjAdvCard(super.set, this.pair);
  final AdjAdvPair pair;
}

/// Splits sets into cards: synonym sets → one card each; topic nouns and
/// adjective/adverb sets → one card per pair.
List<SetCard> setCards(Iterable<WordSet> sets) => [
      for (final s in sets)
        if (s.adjAdv.isNotEmpty)
          for (final p in s.adjAdv) AdjAdvCard(s, p)
        else if (s.pairs.isNotEmpty)
          for (final p in s.pairs) PairCard(s, p)
        else if (s.words.isNotEmpty)
          WordsCard(s),
    ];

void openWordSetDeck(BuildContext context, List<SetCard> cards, int index) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordSetDeckScreen(cards: cards, initialIndex: index)));
}

class WordSetDeckScreen extends StatelessWidget {
  const WordSetDeckScreen({super.key, required this.cards, this.initialIndex = 0});
  final List<SetCard> cards;
  final int initialIndex;

  static const _tints = [AppColors.lilac, AppColors.peach, AppColors.sunflowerSoft, AppColors.blush, Color(0xFFB9CB7C), Color(0xFF9CC7E4)];
  static const _cast = [Mascot.thinking, Mascot.excited, Mascot.playful, Mascot.focused, Mascot.cheerful, Mascot.kind, Mascot.friendly, Mascot.confident];

  Mascot _mascotFor(int i) => cards[i].set.mascot != null && i % 3 == 0 ? Mascot.byName(cards[i].set.mascot) : _cast[i % _cast.length];

  @override
  Widget build(BuildContext context) {
    final group = cards.isEmpty ? null : cards.first.set.group;
    final (label, mode) = switch (group) {
      WordSetGroup.adjAdv => ('Practise adj ↔ adverb', PracticeMode.adjAdv),
      WordSetGroup.trends || WordSetGroup.numbers => ('Order the sets', PracticeMode.orderSet),
      _ => (null, null),
    };
    return FlashDeckScreen(
      count: cards.length,
      initialIndex: initialIndex,
      subtitle: (i) => '${cards[i].set.group.label} · ${cards[i].set.head}',
      front: (context, i) => _front(cards[i], _tints[i % _tints.length], _mascotFor(i)),
      back: (context, i) => _back(cards[i]),
      practiseLabel: label,
      onPractise: mode == null ? null : () => startPractice(context, SessionRequest(mode)),
    );
  }

  Widget _front(SetCard c, Color tint, Mascot mascot) {
    final (caption, big, prompt) = switch (c) {
      WordsCard(:final set) => (set.group.label, '${set.head} = …', set.scale ? 'Name the words, from small to big.' : 'How many ways can you say it?'),
      PairCard(:final pair) => ('Topic noun', pair.plain, 'Paraphrase it for your intro.'),
      AdjAdvCard(:final pair) => ('Adjective ↔ adverb', pair.plain, 'Say it with a Band 8 adverb — and as a noun phrase.'),
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: flashCardDecoration(tint),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Flexible(child: TagChip(caption)), const Spacer(), const FlipHint()]),
          const SizedBox(height: 22),
          Text(big, style: TextStyle(fontSize: c is WordsCard ? 32 : 36, fontWeight: FontWeight.w700, height: 1.1, decoration: c is WordsCard ? null : TextDecoration.lineThrough, decorationColor: AppColors.plain)),
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, box) => MascotImage(mascot, size: box.maxHeight.clamp(0, 200).toDouble(), sticker: true, idle: true)),
            ),
          ),
          Center(child: Text(prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, height: 1.3))),
        ],
      ),
    );
  }

  Widget _back(SetCard c) {
    final String? speak;
    final List<Widget> body;
    switch (c) {
      case WordsCard(:final set):
        speak = set.example;
        body = [
          Text('${set.head} = …', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (set.scale && set.steps.length >= 2)
            StrengthLadder(set: set)
          else
            for (final w in set.words)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Flexible(child: TagChip(w.w, color: AppColors.cream)),
                  const SizedBox(width: 8),
                  if (w.note != null) Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(w.note!, style: const TextStyle(fontSize: 13, height: 1.3)))),
                ]),
              ),
          if (set.nouns.isNotEmpty) ...[
            const SizedBox(height: 14),
            const CardCaption('As nouns'),
            const SizedBox(height: 4),
            Text(set.nouns.join(' · '), style: const TextStyle(fontSize: 14.5, height: 1.4)),
          ],
          if (set.example != null) ...[
            const SizedBox(height: 14),
            const CardCaption('Example'),
            const SizedBox(height: 4),
            Text(set.example!, style: const TextStyle(fontSize: 16, height: 1.45)),
          ],
        ];
      case PairCard(:final pair):
        speak = pair.example;
        body = [
          Text(pair.plain, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, decorationColor: AppColors.plain)),
          const SizedBox(height: 2),
          Text(pair.formal.first, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1)),
          if (pair.formal.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final f in pair.formal.skip(1)) TagChip(f, color: AppColors.cream)]),
          ],
          if (pair.example != null) ...[
            const SizedBox(height: 16),
            const CardCaption('In a sentence'),
            const SizedBox(height: 4),
            Text(pair.example!, style: const TextStyle(fontSize: 16.5, height: 1.45)),
          ],
        ];
      case AdjAdvCard(:final pair):
        speak = pair.verbSentence;
        body = [
          Text(pair.plain, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, decorationColor: AppColors.plain)),
          const SizedBox(height: 4),
          Text('${pair.adv}  ·  ${pair.adj}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 16),
          const CardCaption('Verb + adverb'),
          const SizedBox(height: 4),
          Text(pair.verbSentence, style: const TextStyle(fontSize: 16, height: 1.45)),
          const SizedBox(height: 12),
          const CardCaption('Adjective + noun'),
          const SizedBox(height: 4),
          Text(pair.nounSentence, style: const TextStyle(fontSize: 16, height: 1.45)),
        ];
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: flashCardDecoration(Colors.white),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body))),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Spacer(),
            MascotImage(Mascot.pick(Mascot.correct, c.set.id.length), size: 84, sticker: true),
            if (speak != null) ...[
              const SizedBox(width: 8),
              RoundIconButton(icon: AppIcons.speak, tooltip: 'Hear it', color: AppColors.cream, onTap: () => Speech.instance.speak(speak!)),
            ],
          ]),
        ],
      ),
    );
  }
}
