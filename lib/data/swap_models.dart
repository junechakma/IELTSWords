import 'chart_models.dart';

/// Where a swap lives in the answer: a paragraph slot and a sentence position.
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

enum TaskKind {
  task1('Task 1'),
  task2('Task 2'),
  letters('Letters');

  const TaskKind(this.label);
  final String label;

  List<Slot> get slots => switch (this) {
        task1 => const [Slot.intro, Slot.overview, Slot.body1, Slot.body2],
        task2 => const [Slot.intro, Slot.body1, Slot.body2, Slot.conclusion],
        letters => const [Slot.opening, Slot.body, Slot.closing],
      };
}

class Trap {
  const Trap(this.text, this.why);
  final String text;
  final String why;
}

/// One habit to train: plain phrase → Band 8 phrase, inside a real sentence.
class Swap {
  const Swap({
    required this.id,
    required this.topicId,
    required this.slot,
    required this.position,
    required this.plain,
    required this.formal,
    required this.plainSentence,
    required this.formalSentence,
    required this.traps,
    this.form,
    this.note,
    this.entryIds = const [],
  });

  factory Swap.fromJson(Map<String, dynamic> j, {required String topicId, required Slot slot, required Position position}) => Swap(
        id: j['id'] as String,
        topicId: topicId,
        slot: slot,
        position: position,
        plain: j['plain'] as String,
        formal: (j['formal'] as List).cast<String>(),
        plainSentence: j['plainSentence'] as String,
        formalSentence: j['formalSentence'] as String,
        traps: [for (final t in (j['traps'] as List? ?? const [])) Trap((t as Map)['text'] as String, t['why'] as String? ?? '')],
        form: j['form'] as String?,
        note: j['note'] as String?,
        entryIds: (j['entryIds'] as List? ?? const []).cast<String>(),
      );

  final String id;
  final String topicId;
  final Slot slot;
  final Position position;
  final String plain;
  final List<String> formal;
  final String plainSentence;
  final String formalSentence;
  final List<Trap> traps;
  final String? form;
  final String? note;
  final List<String> entryIds;

  String get best => formal.first;
  List<String> get also => formal.skip(1).toList();

  /// Plain sentence split around the plain phrase: (before, after).
  (String, String) get plainParts {
    final i = plainSentence.indexOf(plain);
    return (plainSentence.substring(0, i), plainSentence.substring(i + plain.length));
  }

  (String, String) get formalParts {
    final i = formalSentence.indexOf(best);
    if (i < 0) return (formalSentence, '');
    return (formalSentence.substring(0, i), formalSentence.substring(i + best.length));
  }

  /// Accepts any formal option, ignoring case, extra spaces and final punctuation.
  bool accepts(String typed) {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[’‘]'), "'").replaceAll(RegExp(r'[.,!?;:]+$'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final t = norm(typed);
    return formal.any((f) => norm(f) == t);
  }
}

class SwapGroup {
  const SwapGroup(this.slot, this.position, this.swaps);
  final Slot slot;
  final Position position;
  final List<Swap> swaps;
}

class LearnLabel {
  const LearnLabel({required this.part, required this.word, this.also = const [], this.plain = const [], required this.sentence});
  factory LearnLabel.fromJson(Map<String, dynamic> j) => LearnLabel(
        part: j['part'] as String,
        word: j['word'] as String,
        also: (j['also'] as List? ?? const []).cast<String>(),
        plain: (j['plain'] as List? ?? const []).cast<String>(),
        sentence: j['sentence'] as String,
      );
  final String part;
  final String word;
  final List<String> also;
  final List<String> plain;
  final String sentence;
}

class Learn {
  const Learn({required this.title, required this.sample, required this.labels});
  factory Learn.fromJson(Map<String, dynamic> j) => Learn(
        title: j['title'] as String? ?? '',
        sample: ChartData.fromJson(j['sample'] as Map<String, dynamic>),
        labels: [for (final l in j['labels'] as List) LearnLabel.fromJson(l as Map<String, dynamic>)],
      );
  final String title;
  final ChartData sample;
  final List<LearnLabel> labels;
}

class DescribeItem {
  const DescribeItem({required this.id, required this.part, required this.slot, required this.sentence, required this.answer, required this.options, this.tooPlain = const [], this.why});
  factory DescribeItem.fromJson(Map<String, dynamic> j) => DescribeItem(
        id: j['id'] as String,
        part: j['part'] as String,
        slot: Slot.values.byName(j['slot'] as String),
        sentence: j['sentence'] as String,
        answer: j['answer'] as String,
        options: (j['options'] as List).cast<String>(),
        tooPlain: (j['tooPlain'] as List? ?? const []).cast<String>(),
        why: j['why'] as String?,
      );
  final String id, part, sentence, answer;
  final Slot slot;
  final List<String> options, tooPlain;
  final String? why;
}

class RewriteItem {
  const RewriteItem({required this.id, required this.slot, required this.plain, required this.best, required this.tooPlain, required this.tooPlainWhy, required this.broken, required this.brokenWhy});
  factory RewriteItem.fromJson(Map<String, dynamic> j) => RewriteItem(
        id: j['id'] as String,
        slot: Slot.values.byName(j['slot'] as String),
        plain: j['plain'] as String,
        best: j['best'] as String,
        tooPlain: j['tooPlain'] as String,
        tooPlainWhy: j['tooPlainWhy'] as String,
        broken: j['broken'] as String,
        brokenWhy: j['brokenWhy'] as String,
      );
  final String id, plain, best, tooPlain, tooPlainWhy, broken, brokenWhy;
  final Slot slot;
}

class ReportStep {
  const ReportStep({required this.position, required this.prompt, required this.best, required this.others});
  factory ReportStep.fromJson(Map<String, dynamic> j) => ReportStep(
        position: Position.values.byName(j['position'] as String),
        prompt: j['prompt'] as String,
        best: j['best'] as String,
        others: [for (final o in j['others'] as List) Trap((o as Map)['text'] as String, o['why'] as String? ?? '')],
      );
  final Position position;
  final String prompt, best;
  final List<Trap> others;
}

class ReportParagraph {
  const ReportParagraph(this.slot, this.steps);
  factory ReportParagraph.fromJson(Map<String, dynamic> j) =>
      ReportParagraph(Slot.values.byName(j['slot'] as String), [for (final s in j['steps'] as List) ReportStep.fromJson(s as Map<String, dynamic>)]);
  final Slot slot;
  final List<ReportStep> steps;

  String get text => steps.map((s) => s.best).join(' ');
}

class Report {
  const Report({required this.question, this.chart, required this.paragraphs});
  factory Report.fromJson(Map<String, dynamic> j) => Report(
        question: j['question'] as String,
        chart: j['chart'] == null ? null : ChartData.fromJson(j['chart'] as Map<String, dynamic>),
        paragraphs: [for (final p in j['paragraphs'] as List) ReportParagraph.fromJson(p as Map<String, dynamic>)],
      );
  final String question;
  final ChartData? chart;
  final List<ReportParagraph> paragraphs;

  ReportParagraph? paragraph(Slot s) {
    for (final p in paragraphs) {
      if (p.slot == s) return p;
    }
    return null;
  }

  int get wordCount => paragraphs.fold(0, (n, p) => n + p.text.split(RegExp(r'\s+')).length);
}

/// A chart type (Task 1), essay type (Task 2) or letter type, with its swaps by slot.
class SwapTopic {
  const SwapTopic({
    required this.id,
    required this.task,
    required this.title,
    required this.mascot,
    required this.blurb,
    required this.groups,
    this.learn,
    this.describe = const [],
    this.rewrites = const [],
    this.report,
  });

  factory SwapTopic.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return SwapTopic(
      id: id,
      task: TaskKind.values.byName(j['task'] as String),
      title: j['title'] as String,
      mascot: j['mascot'] as String,
      blurb: j['blurb'] as String? ?? '',
      groups: [
        for (final g in j['slots'] as List)
          () {
            final slot = Slot.values.byName((g as Map)['slot'] as String);
            final pos = Position.values.byName(g['position'] as String);
            return SwapGroup(slot, pos, [
              for (final s in g['swaps'] as List) Swap.fromJson(s as Map<String, dynamic>, topicId: id, slot: slot, position: pos),
            ]);
          }(),
      ],
      learn: j['learn'] == null ? null : Learn.fromJson(j['learn'] as Map<String, dynamic>),
      describe: [for (final d in (j['describe'] as List? ?? const [])) DescribeItem.fromJson(d as Map<String, dynamic>)],
      rewrites: [for (final r in (j['rewrites'] as List? ?? const [])) RewriteItem.fromJson(r as Map<String, dynamic>)],
      report: j['report'] == null ? null : Report.fromJson(j['report'] as Map<String, dynamic>),
    );
  }

  final String id;
  final TaskKind task;
  final String title;
  final String mascot;
  final String blurb;
  final List<SwapGroup> groups;
  final Learn? learn;
  final List<DescribeItem> describe;
  final List<RewriteItem> rewrites;
  final Report? report;

  List<Swap> get swaps => [for (final g in groups) ...g.swaps];

  List<Swap> swapsIn(Slot slot) => [for (final g in groups) if (g.slot == slot) ...g.swaps];

  /// Swaps of one slot, grouped opening → middle → closing.
  List<(Position, List<Swap>)> bySlot(Slot slot) => [
        for (final p in Position.values)
          if (swapsIn(slot).any((s) => s.position == p)) (p, [for (final s in swapsIn(slot)) if (s.position == p) s]),
      ];
}
