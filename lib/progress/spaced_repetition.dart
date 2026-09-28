/// Leitner boxes: correct moves up a box (review after 1, 2, 4, 7, 15 days),
/// wrong drops to box 1.
enum Mastery {
  newItem('Not tried', 'Not practised yet'),
  seen('Learning', 'Seen, still new'),
  using('Almost', 'Mostly right'),
  natural('Learned', 'You know it');

  const Mastery(this.label, this.hint);
  final String label;

  /// One-line plain-English meaning, shown under the label.
  final String hint;
}

class ItemProgress {
  const ItemProgress({this.box = 0, this.due, this.typed = false, this.seen = 0, this.wrong = 0, this.last});

  factory ItemProgress.fromJson(Map<String, dynamic> j) => ItemProgress(
        box: j['b'] as int? ?? 0,
        due: j['d'] == null ? null : DateTime.parse(j['d'] as String),
        typed: j['t'] as bool? ?? false,
        seen: j['s'] as int? ?? 0,
        wrong: j['w'] as int? ?? 0,
        last: j['l'] == null ? null : DateTime.parse(j['l'] as String),
      );

  Map<String, dynamic> toJson() => {
        'b': box,
        if (due != null) 'd': _day(due!),
        if (typed) 't': true,
        's': seen,
        if (wrong > 0) 'w': wrong,
        if (last != null) 'l': _day(last!),
      };

  static const empty = ItemProgress();

  /// Leitner box 0 (never answered) to 5.
  final int box;

  /// Next review day (null = never answered).
  final DateTime? due;

  /// Produced (typed) correctly at least once — needed for Natural.
  final bool typed;
  final int seen;
  final int wrong;
  final DateTime? last;

  Mastery get mastery {
    if (seen == 0) return Mastery.newItem;
    if (box >= 5 && typed) return Mastery.natural;
    if (box >= 3) return Mastery.using;
    return Mastery.seen;
  }

  bool isDue(DateTime today) => due != null && !SpacedRepetition.dayOf(due!).isAfter(SpacedRepetition.dayOf(today));

  static String _day(DateTime d) => SpacedRepetition.dayOf(d).toIso8601String().substring(0, 10);
}

abstract final class SpacedRepetition {
  /// Days until the next review for boxes 1–5.
  static const intervals = [1, 1, 2, 4, 7, 15];

  /// Highest box a side-mode answer (flashcards, meaning match…) can reach: Seen.
  static const sideCap = 2;

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Applies one answer. Core modes can move a swap all the way to Natural;
  /// side modes only up to Seen.
  static ItemProgress answer(ItemProgress p, {required bool correct, bool core = true, bool typed = false, required DateTime now}) {
    final today = dayOf(now);
    int box;
    if (!correct) {
      box = 1;
    } else if (core) {
      box = (p.box + 1).clamp(1, 5);
    } else {
      box = p.box >= sideCap ? p.box : p.box + 1;
    }
    return ItemProgress(
      box: box,
      due: today.add(Duration(days: intervals[box])),
      typed: p.typed || (correct && core && typed),
      seen: p.seen + 1,
      wrong: p.wrong + (correct ? 0 : 1),
      last: today,
    );
  }
}
