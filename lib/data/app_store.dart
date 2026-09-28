import '../mascots/mascot.dart';

/// What the learner is preparing for (profile).
enum StudyTrack {
  task1('Task 1'),
  task2('Task 2'),
  letters('Letters'),
  listening('Listening maps');

  const StudyTrack(this.label);
  final String label;
}

/// Profile + preferences (immutable; changed through `settingsProvider`).
class Settings {
  const Settings({
    this.name,
    this.buddy = Mascot.delighted,
    this.dailyGoal = 10,
    this.tracks = const {StudyTrack.task1, StudyTrack.task2},
    this.reminderOn = false,
    this.reminderMinutes = 20 * 60,
    this.readAloud = false,
  });

  /// Buddy choices in the profile.
  static const buddies = [Mascot.delighted, Mascot.peaceful, Mascot.kind, Mascot.goofy, Mascot.playful, Mascot.proud];
  static const goals = [5, 10, 20];

  final String? name;
  final Mascot buddy;
  final int dailyGoal;
  final Set<StudyTrack> tracks;
  final bool reminderOn;
  final int reminderMinutes;
  final bool readAloud;

  Settings copyWith({
    String? name,
    bool clearName = false,
    Mascot? buddy,
    int? dailyGoal,
    Set<StudyTrack>? tracks,
    bool? reminderOn,
    int? reminderMinutes,
    bool? readAloud,
  }) =>
      Settings(
        name: clearName ? null : (name ?? this.name),
        buddy: buddy ?? this.buddy,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        tracks: tracks ?? this.tracks,
        reminderOn: reminderOn ?? this.reminderOn,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        readAloud: readAloud ?? this.readAloud,
      );
}

/// Swaps practised per day, for the practice map (immutable).
class Activity {
  const Activity([this.byDay = const {}]);
  final Map<String, int> byDay;

  static String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int wordsOn(DateTime day) => byDay[key(day)] ?? 0;

  /// Number of days with any practice in the last [days] days.
  int daysPractised({int days = 365, DateTime? today}) {
    final t = today ?? DateTime.now();
    var n = 0;
    for (var i = 0; i < days; i++) {
      if (wordsOn(t.subtract(Duration(days: i))) > 0) n++;
    }
    return n;
  }

  int get total => byDay.values.fold(0, (a, b) => a + b);
}
