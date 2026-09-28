import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mascots/mascot.dart';

/// What the learner is preparing for (setup screen, profile).
enum StudyTrack {
  task1('Task 1'),
  task2('Task 2'),
  letters('Letters'),
  listening('Listening maps');

  const StudyTrack(this.label);
  final String label;
}

/// User settings and the daily practice log (words practised per day) for the heatmap.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs) {
    final raw = _prefs.getString(_kActivity);
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) => _activity[k] = v as int);
    }
  }

  static const _kOnboarded = 'onboarded';
  static const _kName = 'name';
  static const _kBuddy = 'buddy';
  static const _kActivity = 'activity';
  static const _kGoal = 'dailyGoal';
  static const _kTracks = 'tracks';
  static const _kReminderOn = 'reminderOn';
  static const _kReminderMinutes = 'reminderMinutes';
  static const _kReadAloud = 'readAloud';

  /// Buddy choices on the setup screen and in the profile.
  static const buddies = [Mascot.delighted, Mascot.peaceful, Mascot.kind, Mascot.goofy, Mascot.playful, Mascot.proud];
  static const goals = [5, 10, 20];

  final SharedPreferences _prefs;
  final Map<String, int> _activity = {};

  static Future<AppStore> load() async => AppStore._(await SharedPreferences.getInstance());

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  String? get name {
    final n = _prefs.getString(_kName)?.trim();
    return n == null || n.isEmpty ? null : n;
  }

  Mascot get buddy => Mascot.values.asNameMap()[_prefs.getString(_kBuddy)] ?? Mascot.delighted;
  int get dailyGoal => _prefs.getInt(_kGoal) ?? 10;
  Set<StudyTrack> get tracks {
    final l = _prefs.getStringList(_kTracks);
    if (l == null) return {StudyTrack.task1, StudyTrack.task2};
    return {for (final t in l) if (StudyTrack.values.asNameMap()[t] != null) StudyTrack.values.byName(t)};
  }

  bool get reminderOn => _prefs.getBool(_kReminderOn) ?? false;
  int get reminderMinutes => _prefs.getInt(_kReminderMinutes) ?? 20 * 60;
  bool get readAloud => _prefs.getBool(_kReadAloud) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  Future<void> saveSetup({required String name, required int goal, required Set<StudyTrack> tracks, required Mascot buddy}) async {
    await Future.wait([
      _prefs.setString(_kName, name.trim()),
      _prefs.setInt(_kGoal, goal),
      _prefs.setStringList(_kTracks, [for (final t in tracks) t.name]),
      _prefs.setString(_kBuddy, buddy.name),
      _prefs.setBool(_kOnboarded, true),
    ]);
    notifyListeners();
  }

  Future<void> setName(String v) => _set(() => _prefs.setString(_kName, v.trim()));
  Future<void> setBuddy(Mascot m) => _set(() => _prefs.setString(_kBuddy, m.name));
  Future<void> setGoal(int g) => _set(() => _prefs.setInt(_kGoal, g));
  Future<void> setTracks(Set<StudyTrack> t) => _set(() => _prefs.setStringList(_kTracks, [for (final x in t) x.name]));
  Future<void> setReminder(bool on, [int? minutes]) => _set(() async {
        await _prefs.setBool(_kReminderOn, on);
        if (minutes != null) await _prefs.setInt(_kReminderMinutes, minutes);
      });
  Future<void> setReadAloud(bool v) => _set(() => _prefs.setBool(_kReadAloud, v));

  Future<void> _set(Future<Object?> Function() f) async {
    await f();
    notifyListeners();
  }

  int wordsOn(DateTime day) => _activity[_key(day)] ?? 0;

  /// Number of days with any practice in the last [days] days.
  int daysPractised({int days = 365}) {
    final today = DateTime.now();
    var n = 0;
    for (var i = 0; i < days; i++) {
      if (wordsOn(today.subtract(Duration(days: i))) > 0) n++;
    }
    return n;
  }

  Future<void> recordPractice(int words, {DateTime? day}) async {
    final k = _key(day ?? DateTime.now());
    _activity[k] = (_activity[k] ?? 0) + words;
    await _prefs.setString(_kActivity, jsonEncode(_activity));
    notifyListeners();
  }

  Future<void> resetActivity() async {
    _activity.clear();
    await _prefs.remove(_kActivity);
    notifyListeners();
  }

  /// Fills the in-memory log with sample days so the heatmap can be previewed.
  /// Enabled only with `--dart-define=DEMO_ACTIVITY=true`; never saved.
  void seedDemoActivity() {
    final today = DateTime.now();
    const pattern = [0, 4, 7, 0, 3, 12, 0, 6, 2, 0, 9, 18, 5, 0, 3];
    for (var i = 1; i < 126; i++) {
      final v = pattern[(i * 7 + i ~/ 5) % pattern.length];
      if (v > 0) _activity[_key(today.subtract(Duration(days: i)))] = v;
    }
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
