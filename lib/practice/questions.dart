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
