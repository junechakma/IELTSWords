import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

/// Daily practice reminder.
class Reminders {
  Reminders._();
  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get supported => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> _init() async {
    if (!supported) return false;
    if (_ready) return true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    return _ready;
  }

  /// Schedules (or cancels) a daily reminder at [minutes] after midnight.
  Future<void> apply({required bool on, required int minutes}) async {
    if (!await _init()) return;
    try {
      await _plugin.cancelAll();
      if (!on) return;
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      // Scheduled in UTC for the chosen local time (repeats daily at that time).
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: 1,
        title: 'IELTS Words',
        body: 'A few swaps today? shows → illustrates, went up → rose sharply.',
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        matchDateTimeComponents: DateTimeComponents.time,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('daily', 'Daily reminder', importance: Importance.defaultImportance),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Reminder failed: $e');
    }
  }
}
