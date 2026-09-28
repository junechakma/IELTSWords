import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'spaced_repetition.dart';

/// Per-item progress (swaps, A–E entries, listening items), saved words and
/// words marked "don't know". Stored as JSON in shared_preferences.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs) {
    final raw = _prefs.getString(_kProgress);
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) => _items[k] = ItemProgress.fromJson(v as Map<String, dynamic>));
    }
    _saved.addAll(_prefs.getStringList(_kSaved) ?? const []);
    _unknown.addAll(_prefs.getStringList(_kUnknown) ?? const []);
  }

  /// In-memory store for tests.
  ProgressStore.memory(SharedPreferences prefs) : this._(prefs);

  static const _kProgress = 'progress';
  static const _kSaved = 'saved';
  static const _kUnknown = 'unknown';

  final SharedPreferences _prefs;
  final Map<String, ItemProgress> _items = {};
  final Set<String> _saved = {};
  final Set<String> _unknown = {};

  /// Overrides "now" in tests.
  DateTime Function() clock = DateTime.now;

  static Future<ProgressStore> load() async => ProgressStore._(await SharedPreferences.getInstance());

  ItemProgress of(String id) => _items[id] ?? ItemProgress.empty;
  Mastery mastery(String id) => of(id).mastery;

  Map<Mastery, int> masteryCounts(Iterable<String> ids) {
    final out = {for (final m in Mastery.values) m: 0};
    for (final id in ids) {
      out[mastery(id)] = out[mastery(id)]! + 1;
    }
    return out;
  }

  /// Share (0–1) of ids that are at least Using.
  double share(Iterable<String> ids, {Mastery atLeast = Mastery.using}) {
    final l = ids.toList();
    if (l.isEmpty) return 0;
    return l.where((id) => mastery(id).index >= atLeast.index).length / l.length;
  }

  List<String> dueIds(Iterable<String> ids) {
    final now = clock();
    return [for (final id in ids) if (of(id).isDue(now)) id];
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

  Future<ItemProgress> record(String id, {required bool correct, bool core = true, bool typed = false}) async {
    final p = SpacedRepetition.answer(of(id), correct: correct, core: core, typed: typed, now: clock());
    _items[id] = p;
    await _save();
    notifyListeners();
    return p;
  }

  bool isSaved(String id) => _saved.contains(id);
  Set<String> get saved => Set.unmodifiable(_saved);

  Future<void> toggleSaved(String id) async {
    if (!_saved.remove(id)) _saved.add(id);
    await _prefs.setStringList(_kSaved, _saved.toList());
    notifyListeners();
  }

  bool isUnknown(String id) => _unknown.contains(id);
  Set<String> get unknown => Set.unmodifiable(_unknown);

  Future<void> setUnknown(String id, bool v) async {
    v ? _unknown.add(id) : _unknown.remove(id);
    await _prefs.setStringList(_kUnknown, _unknown.toList());
    notifyListeners();
  }

  Future<void> reset() async {
    _items.clear();
    _saved.clear();
    _unknown.clear();
    await Future.wait([_prefs.remove(_kProgress), _prefs.remove(_kSaved), _prefs.remove(_kUnknown)]);
    notifyListeners();
  }

  Future<void> _save() => _prefs.setString(_kProgress, jsonEncode({for (final e in _items.entries) e.key: e.value.toJson()}));
}
