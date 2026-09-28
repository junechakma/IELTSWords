// Swap model: plain word -> Band 8 word, placed in a paragraph slot and position.
// Loaded from task1_by_chart.json, task2_swaps.json and letter_swaps.json.

import 'chart_sample.dart';

enum Slot {
  intro('Intro'),
  overview('Overview'),
  body1('Body 1'),
  body2('Body 2'),
  conclusion('Conclusion'),
  opening('Opening'),
  body('Body'),
  closing('Closing');

  const Slot(this.label);
  final String label;
}

enum Position {
  opening('Opening sentence'),
  middle('Middle'),
  closing('Closing sentence');

  const Position(this.label);
  final String label;
}

enum GroupKind { chart, task2, letter }

/// A wrong choice with the reason it is wrong ("Too plain", "Wrong meaning"...).
class Option {
  const Option(this.text, {this.ok = false, this.why});

  factory Option.fromJson(Map<String, dynamic> j) => Option(j['t'] as String, ok: j['ok'] == true, why: j['why'] as String?);

  final String text;
  final bool ok;
  final String? why;
}

class Swap {
  Swap({
    required this.id,
    required this.plain,
    required this.formal,
    required this.plainSentence,
    required this.formalSentence,
    required this.distractors,
    required this.entryIds,
    required this.note,
    required this.slot,
    required this.position,
    required this.groupId,
  });

  factory Swap.fromJson(Map<String, dynamic> j, {required Slot slot, required Position position, required String groupId}) => Swap(
        id: j['id'] as String,
        plain: j['plain'] as String,
        formal: (j['formal'] as List).cast<String>(),
        plainSentence: j['plainSentence'] as String,
        formalSentence: j['formalSentence'] as String,
        distractors: [for (final d in j['distractors'] as List) Option.fromJson(d as Map<String, dynamic>)],
        entryIds: ((j['entryIds'] as List?) ?? const []).cast<String>(),
        note: j['note'] as String? ?? '',
        slot: slot,
        position: position,
        groupId: groupId,
      );

  final String id;
  final String plain;

  /// Band 8 options; the first is the main answer. All of them fit the same gap.
  final List<String> formal;
  final String plainSentence;
  final String formalSentence;
  final List<Option> distractors;
  final List<String> entryIds;
  final String note;
  final Slot slot;
  final Position position;
  final String groupId;

  String get main => formal.first;

  /// plainSentence split around the plain phrase: (before, after).
  (String, String) get gap {
    final i = plainSentence.indexOf(plain);
    return (plainSentence.substring(0, i), plainSentence.substring(i + plain.length));
  }

  bool accepts(String typed) {
    final t = normalise(typed);
    return formal.any((f) => normalise(f) == t);
  }

  static String normalise(String s) =>
      s.toLowerCase().replaceAll('’', "'").replaceAll(RegExp(r'[.,!?]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class ReportStep {
  const ReportStep({required this.position, required this.ask, required this.options});

  factory ReportStep.fromJson(Map<String, dynamic> j) => ReportStep(
        position: Position.values.byName(j['position'] as String),
        ask: j['ask'] as String,
        options: [for (final o in j['options'] as List) Option.fromJson(o as Map<String, dynamic>)],
      );

  final Position position;
  final String ask;
  final List<Option> options;

  Option get answer => options.firstWhere((o) => o.ok);
}

class ReportParagraph {
  const ReportParagraph({required this.slot, required this.steps});

  factory ReportParagraph.fromJson(Map<String, dynamic> j) => ReportParagraph(
        slot: Slot.values.byName(j['slot'] as String),
        steps: [for (final s in j['steps'] as List) ReportStep.fromJson(s as Map<String, dynamic>)],
      );

  final Slot slot;
  final List<ReportStep> steps;

  String get text => steps.map((s) => s.answer.text).join(' ');
}

class Rewrite {
  const Rewrite({required this.id, required this.slot, required this.plain, required this.options});

  factory Rewrite.fromJson(Map<String, dynamic> j) => Rewrite(
        id: j['id'] as String,
        slot: Slot.values.byName(j['slot'] as String),
        plain: j['plain'] as String,
        options: [for (final o in j['options'] as List) Option.fromJson(o as Map<String, dynamic>)],
      );

  final String id;
  final Slot slot;
  final String plain;
  final List<Option> options;
}

/// A piece of a Spot-the-plain-words paragraph: plain text, or a marked plain phrase with its swap.
class SpotPiece {
  const SpotPiece(this.text, [this.formal]);
  final String text;
  final String? formal;
  bool get isPlain => formal != null;
}

class SpotParagraph {
  SpotParagraph({required this.id, required this.slot, required this.pieces});

  factory SpotParagraph.fromJson(Map<String, dynamic> j) {
    final text = j['text'] as String;
    final pieces = <SpotPiece>[];
    var last = 0;
    for (final m in RegExp(r'\{([^{}|]+)\|([^{}|]+)\}').allMatches(text)) {
      if (m.start > last) pieces.add(SpotPiece(text.substring(last, m.start)));
      pieces.add(SpotPiece(m.group(1)!, m.group(2)!));
      last = m.end;
    }
    if (last < text.length) pieces.add(SpotPiece(text.substring(last)));
    return SpotParagraph(id: j['id'] as String, slot: Slot.values.byName(j['slot'] as String), pieces: pieces);
  }

  final String id;
  final Slot slot;
  final List<SpotPiece> pieces;

  Iterable<SpotPiece> get marks => pieces.where((p) => p.isPlain);
  String get formalText => pieces.map((p) => p.formal ?? p.text).join();
}

class DescribeItem {
  const DescribeItem({required this.id, required this.part, required this.slot, required this.sentence, required this.options});

  factory DescribeItem.fromJson(Map<String, dynamic> j) => DescribeItem(
        id: j['id'] as String,
        part: j['part'] as String,
        slot: Slot.values.byName(j['slot'] as String),
        sentence: j['sentence'] as String,
        options: [for (final o in j['options'] as List) Option.fromJson(o as Map<String, dynamic>)],
      );

  final String id;
  final String part;
  final Slot slot;
  final String sentence;
  final List<Option> options;
}

class LearnLabel {
  const LearnLabel({required this.part, required this.word, required this.also, required this.plain, required this.adverbs, required this.sentence});

  factory LearnLabel.fromJson(Map<String, dynamic> j) => LearnLabel(
        part: j['part'] as String,
        word: j['word'] as String,
        also: ((j['also'] as List?) ?? const []).cast<String>(),
        plain: ((j['plain'] as List?) ?? const []).cast<String>(),
        adverbs: ((j['adverbs'] as List?) ?? const []).cast<String>(),
        sentence: j['sentence'] as String,
      );

  final String part;
  final String word;
  final List<String> also;
  final List<String> plain;
  final List<String> adverbs;
  final String sentence;
}

class Learn {
  const Learn({required this.headline, required this.tip, required this.labels});

  factory Learn.fromJson(Map<String, dynamic> j) => Learn(
        headline: j['headline'] as String,
        tip: j['tip'] as String? ?? '',
        labels: [for (final l in j['labels'] as List) LearnLabel.fromJson(l as Map<String, dynamic>)],
      );

  final String headline;
  final String tip;
  final List<LearnLabel> labels;
}

/// A chart type (Task 1), a Task 2 essay type or a letter type: everything is a group of swaps.
class SwapGroup {
  SwapGroup({
    required this.id,
    required this.title,
    required this.kind,
    required this.mascot,
    required this.question,
    required this.swaps,
    required this.report,
    required this.rewrites,
    required this.spot,
    this.sample,
    this.learn,
    this.describe = const [],
  });

  factory SwapGroup.fromJson(Map<String, dynamic> j, GroupKind kind) {
    final id = j['id'] as String;
    return SwapGroup(
      id: id,
      title: j['title'] as String,
      kind: kind,
      mascot: j['mascot'] as String,
      question: j['question'] as String,
      swaps: [
        for (final g in j['slots'] as List)
          for (final s in (g as Map<String, dynamic>)['swaps'] as List)
            Swap.fromJson(s as Map<String, dynamic>,
                slot: Slot.values.byName(g['slot'] as String), position: Position.values.byName(g['position'] as String), groupId: id),
      ],
      report: [for (final p in j['report'] as List) ReportParagraph.fromJson(p as Map<String, dynamic>)],
      rewrites: [for (final r in (j['rewrites'] as List?) ?? const []) Rewrite.fromJson(r as Map<String, dynamic>)],
      spot: [for (final s in (j['spot'] as List?) ?? const []) SpotParagraph.fromJson(s as Map<String, dynamic>)],
      sample: j['sample'] == null ? null : ChartSample.fromJson(j['sample'] as Map<String, dynamic>),
      learn: j['learn'] == null ? null : Learn.fromJson(j['learn'] as Map<String, dynamic>),
      describe: [for (final d in (j['describe'] as List?) ?? const []) DescribeItem.fromJson(d as Map<String, dynamic>)],
    );
  }

  final String id;
  final String title;
  final GroupKind kind;
  final String mascot;
  final String question;
  final List<Swap> swaps;
  final List<ReportParagraph> report;
  final List<Rewrite> rewrites;
  final List<SpotParagraph> spot;
  final ChartSample? sample;
  final Learn? learn;
  final List<DescribeItem> describe;

  List<Slot> get slots => switch (kind) {
        GroupKind.chart => const [Slot.intro, Slot.overview, Slot.body1, Slot.body2],
        GroupKind.task2 => const [Slot.intro, Slot.body1, Slot.body2, Slot.conclusion],
        GroupKind.letter => const [Slot.opening, Slot.body, Slot.closing],
      };

  List<Swap> inSlot(Slot s) => swaps.where((w) => w.slot == s).toList();

  /// Short name used on chips: "Line", "Bar", "Opinion"...
  String get short => title.split(' ').first;
}

class WordSetWord {
  const WordSetWord(this.w, this.strength, this.note);
  final String w;
  final int strength;
  final String? note;
}

class WordPair {
  const WordPair(this.plain, this.formal);
  final String plain;
  final List<String> formal;
}

class WordSet {
  const WordSet({
    required this.id,
    required this.group,
    required this.head,
    required this.scale,
    required this.words,
    required this.nouns,
    required this.pairs,
    required this.example,
    required this.avoid,
  });

  factory WordSet.fromJson(Map<String, dynamic> j) => WordSet(
        id: j['id'] as String,
        group: j['group'] as String,
        head: j['head'] as String,
        scale: j['scale'] == true,
        words: [
          for (final w in (j['words'] as List?) ?? const [])
            WordSetWord(w['w'] as String, (w['strength'] as num?)?.toInt() ?? 1, w['note'] as String?),
        ],
        nouns: ((j['nouns'] as List?) ?? const []).cast<String>(),
        pairs: [
          for (final p in (j['pairs'] as List?) ?? const []) WordPair(p['plain'] as String, (p['formal'] as List).cast<String>()),
        ],
        example: j['example'] as String?,
        avoid: ((j['avoid'] as List?) ?? const []).cast<String>(),
      );

  final String id;
  final String group;
  final String head;

  /// True when the words are ordered small -> big and strength matters.
  final bool scale;
  final List<WordSetWord> words;
  final List<String> nouns;
  final List<WordPair> pairs;
  final String? example;
  final List<String> avoid;
}
