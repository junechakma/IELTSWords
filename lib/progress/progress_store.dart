import 'spaced_repetition.dart';

/// Per-item progress (swaps, A–E entries, listening items), saved items and
/// items marked "don't know". Immutable — changed through `progressProvider`.
class Progress {
  const Progress({this.items = const {}, this.saved = const {}, this.unknown = const {}, this.now = _systemNow});

  final Map<String, ItemProgress> items;
  final Set<String> saved;
  final Set<String> unknown;

  /// "Today" for due checks (overridable in tests).
  final DateTime Function() now;

  static DateTime _systemNow() => DateTime.now();

  ItemProgress of(String id) => items[id] ?? ItemProgress.empty;
  Mastery mastery(String id) => of(id).mastery;

  Map<Mastery, int> masteryCounts(Iterable<String> ids) {
    final out = {for (final m in Mastery.values) m: 0};
    for (final id in ids) {
      out[mastery(id)] = out[mastery(id)]! + 1;
    }
    return out;
  }

  /// Share (0–1) of ids that are at least [atLeast].
  double share(Iterable<String> ids, {Mastery atLeast = Mastery.using}) {
    final l = ids.toList();
    if (l.isEmpty) return 0;
    return l.where((id) => mastery(id).index >= atLeast.index).length / l.length;
  }

  List<String> dueIds(Iterable<String> ids) {
    final t = now();
    return [for (final id in ids) if (of(id).isDue(t)) id];
  }

  /// Earliest upcoming review day among [ids], or null.
  DateTime? nextDue(Iterable<String> ids) {
    DateTime? best;
    for (final id in ids) {
      final d = of(id).due;
      if (d != null && (best == null || d.isBefore(best))) best = d;
    }
    return best;
  }

  bool isSaved(String id) => saved.contains(id);
  bool isUnknown(String id) => unknown.contains(id);

  Progress copyWith({Map<String, ItemProgress>? items, Set<String>? saved, Set<String>? unknown}) =>
      Progress(items: items ?? this.items, saved: saved ?? this.saved, unknown: unknown ?? this.unknown, now: now);
}
