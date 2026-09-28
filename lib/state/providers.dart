import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_store.dart';
import '../data/swap_models.dart';
import '../data/vocab_repository.dart';
import '../mascots/mascot.dart';
import '../progress/progress_store.dart';
import '../progress/spaced_repetition.dart';

// ---------------------------------------------------------------- roots
//
// Overridden in main() (and tests) with the loaded values.

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override sharedPrefsProvider'));
final repoProvider = Provider<VocabRepository>((ref) => throw UnimplementedError('override repoProvider'));

/// "Now" — overridable so tests can move time forward.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// ---------------------------------------------------------------- settings

const _kName = 'name';
const _kBuddy = 'buddy';
const _kGoal = 'dailyGoal';
const _kTracks = 'tracks';
const _kReminderOn = 'reminderOn';
const _kReminderMinutes = 'reminderMinutes';
const _kReadAloud = 'readAloud';

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  Settings build() {
    final p = ref.watch(sharedPrefsProvider);
    final n = p.getString(_kName)?.trim();
    final tracks = p.getStringList(_kTracks);
    return Settings(
      name: n == null || n.isEmpty ? null : n,
      buddy: Mascot.values.asNameMap()[p.getString(_kBuddy)] ?? Mascot.delighted,
      dailyGoal: p.getInt(_kGoal) ?? 10,
      tracks: tracks == null ? const {StudyTrack.task1, StudyTrack.task2} : {for (final t in tracks) if (StudyTrack.values.asNameMap()[t] != null) StudyTrack.values.byName(t)},
      reminderOn: p.getBool(_kReminderOn) ?? false,
      reminderMinutes: p.getInt(_kReminderMinutes) ?? 20 * 60,
      readAloud: p.getBool(_kReadAloud) ?? false,
    );
  }

  Future<void> setName(String v) async {
    final t = v.trim();
    state = t.isEmpty ? state.copyWith(clearName: true) : state.copyWith(name: t);
    await _p.setString(_kName, t);
  }

  Future<void> setBuddy(Mascot m) async {
    state = state.copyWith(buddy: m);
    await _p.setString(_kBuddy, m.name);
  }

  Future<void> setGoal(int g) async {
    state = state.copyWith(dailyGoal: g);
    await _p.setInt(_kGoal, g);
  }

  Future<void> toggleTrack(StudyTrack t) async {
    final s = {...state.tracks};
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(tracks: s);
    await _p.setStringList(_kTracks, [for (final x in s) x.name]);
  }

  Future<void> setReminder(bool on, [int? minutes]) async {
    state = state.copyWith(reminderOn: on, reminderMinutes: minutes);
    await _p.setBool(_kReminderOn, on);
    if (minutes != null) await _p.setInt(_kReminderMinutes, minutes);
  }

  Future<void> setReadAloud(bool v) async {
    state = state.copyWith(readAloud: v);
    await _p.setBool(_kReadAloud, v);
  }
}

// ---------------------------------------------------------------- activity (practice map)

const _kActivity = 'activity';

final activityProvider = NotifierProvider<ActivityNotifier, Activity>(ActivityNotifier.new);

class ActivityNotifier extends Notifier<Activity> {
  @override
  Activity build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_kActivity);
    if (raw == null) return const Activity();
    return Activity({for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries) e.key: e.value as int});
  }

  Future<void> recordPractice(int words, {DateTime? day}) async {
    final k = Activity.key(day ?? ref.read(clockProvider)());
    final m = {...state.byDay, k: (state.byDay[k] ?? 0) + words};
    state = Activity(m);
    await ref.read(sharedPrefsProvider).setString(_kActivity, jsonEncode(m));
  }

  Future<void> reset() async {
    state = const Activity();
    await ref.read(sharedPrefsProvider).remove(_kActivity);
  }

  /// Sample days so the practice map can be previewed (never saved).
  void seedDemo() {
    final today = ref.read(clockProvider)();
    const pattern = [0, 4, 7, 0, 3, 12, 0, 6, 2, 0, 9, 18, 5, 0, 3];
    state = Activity({
      ...state.byDay,
      for (var i = 1; i < 126; i++)
        if (pattern[(i * 7 + i ~/ 5) % pattern.length] > 0) Activity.key(today.subtract(Duration(days: i))): pattern[(i * 7 + i ~/ 5) % pattern.length],
    });
  }
}

// ---------------------------------------------------------------- progress

const _kProgress = 'progress';
const _kSaved = 'saved';
const _kUnknown = 'unknown';

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

class ProgressNotifier extends Notifier<Progress> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  Progress build() {
    final p = ref.watch(sharedPrefsProvider);
    final raw = p.getString(_kProgress);
    return Progress(
      items: raw == null ? const {} : {for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries) e.key: ItemProgress.fromJson(e.value as Map<String, dynamic>)},
      saved: {...?p.getStringList(_kSaved)},
      unknown: {...?p.getStringList(_kUnknown)},
      now: ref.watch(clockProvider),
    );
  }

  /// Current snapshot, for non-widget code (the session controller).
  Progress get current => state;

  /// Applies one answer and returns the item's new progress.
  Future<ItemProgress> record(String id, {required bool correct, bool core = true, bool typed = false}) async {
    final next = SpacedRepetition.answer(state.of(id), correct: correct, core: core, typed: typed, now: state.now());
    final items = {...state.items, id: next};
    state = state.copyWith(items: items);
    await _p.setString(_kProgress, jsonEncode({for (final e in items.entries) e.key: e.value.toJson()}));
    return next;
  }

  Future<void> toggleSaved(String id) async {
    final s = {...state.saved};
    if (!s.remove(id)) s.add(id);
    state = state.copyWith(saved: s);
    await _p.setStringList(_kSaved, s.toList());
  }

  Future<void> setUnknown(String id, bool v) async {
    final s = {...state.unknown};
    v ? s.add(id) : s.remove(id);
    state = state.copyWith(unknown: s);
    await _p.setStringList(_kUnknown, s.toList());
  }

  Future<void> reset() async {
    state = state.copyWith(items: const {}, saved: const {}, unknown: const {});
    await Future.wait([_p.remove(_kProgress), _p.remove(_kSaved), _p.remove(_kUnknown)]);
  }
}

// ---------------------------------------------------------------- derived

/// Ids of every swap in the app.
final allSwapIdsProvider = Provider<List<String>>((ref) => [for (final s in ref.watch(repoProvider).allSwaps) s.id]);

/// Swaps due for review today.
final dueCountProvider = Provider<int>((ref) => ref.watch(progressProvider).dueIds(ref.watch(allSwapIdsProvider)).length);

/// New / Seen / Using / Natural counts across all swaps.
final masteryCountsProvider = Provider<Map<Mastery, int>>((ref) => ref.watch(progressProvider).masteryCounts(ref.watch(allSwapIdsProvider)));

/// Progress for one chart / essay / letter type.
class TopicStats {
  const TopicStats({required this.total, required this.seen, required this.natural, required this.share});
  final int total, seen, natural;
  final double share;
  bool get isNew => seen == 0;
  int get percent => (share * 100).round();
}

final topicStatsProvider = Provider.family<TopicStats, String>((ref, topicId) {
  final t = ref.watch(repoProvider).topic(topicId);
  final p = ref.watch(progressProvider);
  final ids = [for (final s in t.swaps) s.id];
  return TopicStats(
    total: ids.length,
    seen: ids.where((id) => p.mastery(id) != Mastery.newItem).length,
    natural: ids.where((id) => p.mastery(id) == Mastery.natural).length,
    share: p.share(ids),
  );
});

/// Today's chart + slot on Home.
final todaysPracticeProvider = Provider<(SwapTopic, Slot)>((ref) => ref.watch(repoProvider).todaysPractice(ref.watch(clockProvider)()));
