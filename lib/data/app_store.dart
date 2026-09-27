import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mascots/mascot.dart';

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

  final SharedPreferences _prefs;
  final Map<String, int> _activity = {};

  static Future<AppStore> load() async => AppStore._(await SharedPreferences.getInstance());

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  String? get name => _prefs.getString(_kName);
  Mascot get buddy => Mascot.values.asNameMap()[_prefs.getString(_kBuddy)] ?? Mascot.delighted;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  int wordsOn(DateTime day) => _activity[_key(day)] ?? 0;

  Future<void> recordPractice(int words, {DateTime? day}) async {
    final k = _key(day ?? DateTime.now());
    _activity[k] = (_activity[k] ?? 0) + words;
    await _prefs.setString(_kActivity, jsonEncode(_activity));
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
