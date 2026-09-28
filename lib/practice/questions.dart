import 'dart:math';

import '../data/listening_models.dart';
import '../data/swap_models.dart';
import '../data/vocab_models.dart';
import '../data/word_set_models.dart';

/// One answer option. [kind] explains why a wrong option is wrong.
class Option {
  const Option(this.text, {this.correct = false, this.why, this.tooPlain = false});
  final String text;
  final bool correct;
  final String? why;
  final bool tooPlain;
}

/// A single screen in a practice session.
sealed class Question {
  const Question();

  /// Tag shown under the progress bar, e.g. "Pie · Overview".
  String get tag;
}

class SwapChoiceQ extends Question {
  const SwapChoiceQ(this.swap, this.topic, this.options);
  final Swap swap;
  final SwapTopic topic;
  final List<Option> options;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';
}

class SwapTypeQ extends Question {
  const SwapTypeQ(this.swap, this.topic);
  final Swap swap;
  final SwapTopic topic;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';
}

/// Band 8 sentence with the swap blanked out; tap the word that fits.
class FillGapQ extends Question {
  const FillGapQ(this.swap, this.topic, this.options);
  final Swap swap;
  final SwapTopic topic;
  final List<Option> options;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';
}

class RewriteQ extends Question {
  const RewriteQ(this.item, this.topic, this.options);
  final RewriteItem item;
  final SwapTopic topic;
  final List<Option> options;
  @override
  String get tag => '${topic.shortTitle} · ${item.slot.label}';
}

class SpotQ extends Question {
  const SpotQ(this.topic, this.slot, this.swaps);
  final SwapTopic topic;
  final Slot slot;
  final List<Swap> swaps;
  @override
  String get tag => '${topic.shortTitle} · ${slot.label}';
}

class BuildQ extends Question {
  const BuildQ(this.topic, this.paragraph);
  final SwapTopic topic;
  final ReportParagraph paragraph;
  @override
  String get tag => topic.title;
}

class DescribeQ extends Question {
  const DescribeQ(this.topic, this.item);
  final SwapTopic topic;
  final DescribeItem item;
  @override
  String get tag => '${topic.shortTitle} · ${item.slot.label}';
}

class AdjAdvQ extends Question {
  const AdjAdvQ(this.pair, this.options);
  final AdjAdvPair pair;

  /// Adjectives from other pairs used as wrong options.
  final List<AdjAdvPair> options;
  @override
  String get tag => 'Degree words';
}

class LabelQ extends Question {
  const LabelQ(this.topic);
  final SwapTopic topic;
  @override
  String get tag => topic.title;
}

class OrderQ extends Question {
  const OrderQ(this.set, this.words);
  final WordSet set;

  /// One word per strength step, in the right (small → big) order.
  final List<SetWord> words;
  @override
  String get tag => '${set.head} = …';
}

class FlashQ extends Question {
  const FlashQ(this.swap, this.topic);
  final Swap swap;
  final SwapTopic topic;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';
}

class MeaningQ extends Question {
  const MeaningQ(this.entry, this.options);
  final VocabEntry entry;
  final List<Option> options;
  @override
  String get tag => 'Meaning';
}

class LinkerSortQ extends Question {
  const LinkerSortQ(this.linkers, this.buckets);
  final List<VocabEntry> linkers;
  final List<String> buckets;
  @override
  String get tag => 'Linking words';
}

class RegisterQ extends Question {
  const RegisterQ(this.phrase, this.register, this.options, this.why);
  final String phrase;
  final String register;
  final List<String> options;
  final String why;
  @override
  String get tag => 'Letters';
}

class WhereQ extends Question {
  const WhereQ(this.q, this.map);
  final WhereQuestion q;
  final ListeningMap map;
  @override
  String get tag => 'Map';
}

class PictureQ extends Question {
  const PictureQ(this.item, this.options);
  final ListeningItem item;
  final List<ListeningItem> options;
  @override
  String get tag => item.type.label;
}

class RouteQ extends Question {
  const RouteQ(this.q, this.map);
  final RouteQuestion q;
  final ListeningMap map;
  @override
  String get tag => 'Route';
}

class SpellQ extends Question {
  const SpellQ(this.item);
  final ListeningItem item;
  @override
  String get tag => item.type.label;
}

class TrapQ extends Question {
  const TrapQ(this.q);
  final TrapQuestion q;
  @override
  String get tag => 'Trap';
}

/// One card in a "Plain or Band 8?" round.
class SpeedCard {
  const SpeedCard(this.swap, {required this.formal});
  final Swap swap;

  /// True when the card shows the Band 8 phrase, false for the plain one.
  final bool formal;
  String get text => formal ? swap.best : swap.plain;
  String get sentence => formal ? swap.formalSentence : swap.plainSentence;
}

/// A whole round of swipe cards.
class SpeedQ extends Question {
  const SpeedQ(this.cards);
  final List<SpeedCard> cards;
  @override
  String get tag => '${cards.length} cards';
}

/// Tap-to-match: plain phrases on one side, Band 8 on the other.
class MatchQ extends Question {
  const MatchQ(this.swaps);
  final List<Swap> swaps;
  @override
  String get tag => '${swaps.length} pairs';
}

/// Rebuild the Band 8 sentence from shuffled chips (the swap stays one chip).
class SentenceQ extends Question {
  const SentenceQ(this.swap, this.topic, this.chips);
  final Swap swap;
  final SwapTopic topic;
  final List<String> chips;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';

  /// The sentence split into chips, keeping the Band 8 phrase whole.
  static List<String> chipsOf(Swap s) {
    final (before, after) = s.formalParts;
    List<String> words(String t) => [for (final w in t.split(RegExp(r'\s+'))) if (w.isNotEmpty) w];
    return [...words(before), s.best, ...words(after)];
  }
}

/// Spell the Band 8 word from scrambled letter tiles.
class TilesQ extends Question {
  const TilesQ(this.swap, this.topic, this.letters);
  final Swap swap;
  final SwapTopic topic;
  final List<String> letters;
  @override
  String get tag => '${topic.shortTitle} · ${swap.slot.label}';
}

/// A sentence about a real exam map with its key word gapped.
class MapGapQ extends Question {
  const MapGapQ(this.set, this.sentence, this.options);
  final MapSet set;
  final MapSentence sentence;
  final List<String> options;
  @override
  String get tag => 'Set ${set.number} · ${set.title}';
}

/// What shape a trend word describes.
enum TrendShape { up, down, flat, wave }

/// Draw the line a trend word describes ("plummeted" → steep fall).
class DrawQ extends Question {
  const DrawQ(this.set, this.word, this.shape);
  final WordSet set;
  final SetWord word;
  final TrendShape shape;
  @override
  String get tag => set.head;
}

/// Tap how big a change a word describes, on a 1–5 scale.
class DialQ extends Question {
  const DialQ(this.set, this.word);
  final WordSet set;
  final SetWord word;
  @override
  String get tag => set.head;
}

/// Phrases float up as bubbles; pop only the Band 8 ones.
class BubbleQ extends Question {
  const BubbleQ(this.items);
  final List<SpeedCard> items;
  @override
  String get tag => '${items.where((i) => i.formal).length} to pop';
}

extension TopicTitle on SwapTopic {
  /// "Pie" for "Pie chart", "Line" for "Line graph".
  String get shortTitle => switch (id) {
        'line' => 'Line',
        'bar' => 'Bar',
        'pie' => 'Pie',
        'table' => 'Table',
        'map' => 'Map',
        'process' => 'Process',
        'mixed' => 'Mixed',
        _ => title,
      };
}

/// Builds swap-choice options: the right one, 2 traps and (if room) the plain word.
List<Option> swapOptions(Swap s, Random rnd) {
  final opts = <Option>[
    Option(s.best, correct: true),
    for (final t in s.traps.take(3)) Option(t.text, why: t.why, tooPlain: t.why.toLowerCase().contains('plain')),
  ];
  if (opts.length < 4 && !opts.any((o) => o.text == s.plain)) {
    opts.add(Option(s.plain, why: 'too plain – the word you would normally write', tooPlain: true));
  }
  return opts..shuffle(rnd);
}
