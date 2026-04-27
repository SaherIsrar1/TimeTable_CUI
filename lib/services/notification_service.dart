import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Period → start time (HH:mm) matching ViewModels
  static const Map<String, String> _periodStartTimes = {
    "1": "08:30",
    "2": "09:55",
    "3": "11:20",
    "4": "13:40",
    "5": "15:05",
  };

  static const Map<String, int> _dayToWeekday = {
    "Monday": DateTime.monday,
    "Tuesday": DateTime.tuesday,
    "Wednesday": DateTime.wednesday,
    "Thursday": DateTime.thursday,
    "Friday": DateTime.friday,
  };

  /// How many minutes before class to fire the notification.
  static const int _reminderMinutesBefore = 10;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Attempt to use device's local timezone
    try {
      final localOffset = DateTime.now().timeZoneOffset;
      final locations = tz.timeZoneDatabase.locations;
      String? matchedLocation;
      for (final name in locations.keys) {
        final loc = tz.getLocation(name);
        final now = tz.TZDateTime.now(loc);
        if (now.timeZoneOffset == localOffset) {
          matchedLocation = name;
          break;
        }
      }
      final tzName = matchedLocation ?? 'Asia/Karachi';
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[NotificationService] Timezone set to: $tzName');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      debugPrint('[NotificationService] Timezone fallback to Asia/Karachi: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final didInit = await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
    debugPrint('[NotificationService] Initialized (result=$didInit).');
  }

  /// Request notification permission (Android 13+ / iOS).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      final exactAlarm = await android.requestExactAlarmsPermission();
      debugPrint(
          '[NotificationService] notif=$granted exactAlarm=$exactAlarm');
      return granted == true;
    }
    return true;
  }

  // ── Debug helper ───────────────────────────────────────────────────────────

  /// Fire a test notification immediately to verify the channel works.
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming class periods',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      99999,
      '✅ Notifications Working!',
      'You will receive class reminders 10 minutes before each class.',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    debugPrint('[NotificationService] Test notification fired.');
  }

  // ── Main scheduling API ────────────────────────────────────────────────────

  /// Cancels all existing notifications, then schedules class reminders
  /// for the next [weeksAhead] weeks based on the provided timetable data.
  ///
  /// Notifications fire [_reminderMinutesBefore] minutes before class starts.
  ///
  /// [role] — 'student' or 'teacher'
  /// [displayName] — section id or teacher name (used in notification body)
  /// [timetableData] — map of day → list of class maps (same shape as Firestore)
  static Future<void> scheduleWeeklyNotifications({
    required String role,
    required String displayName,
    required Map<String, dynamic> timetableData,
    int weeksAhead = 4,
  }) async {
    if (!_initialized) {
      debugPrint('[NotificationService] WARNING: Not initialized, initializing now...');
      await initialize();
    }

    await cancelAll();

    final bool isTeacher = role == 'teacher';
    int scheduledCount = 0;
    int skippedPast = 0;
    int skippedNoPeriod = 0;

    final now = DateTime.now();
    debugPrint('[NotificationService] Scheduling for "$displayName" ($role). '
        'Now = $now, weeksAhead = $weeksAhead');
    debugPrint('[NotificationService] Timetable days: ${timetableData.keys.toList()}');

    for (int weekOffset = 0; weekOffset < weeksAhead; weekOffset++) {
      for (final entry in _dayToWeekday.entries) {
        final dayName = entry.key;
        final targetWeekday = entry.value;

        final dayClasses = timetableData[dayName];
        if (dayClasses == null || dayClasses is! List || dayClasses.isEmpty) {
          continue;
        }

        // Find the target date for this weekday
        DateTime targetDate = _nextWeekday(now, targetWeekday, weekOffset);

        int periodIndex = 0;
        for (final classMap in dayClasses) {
          final period = classMap['period']?.toString() ?? '';
          final startTimeStr = _periodStartTimes[period];
          if (startTimeStr == null) {
            skippedNoPeriod++;
            periodIndex++;
            continue;
          }

          final timeParts = startTimeStr.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 8;
          final minute = int.tryParse(timeParts[1]) ?? 30;

          // Class start time
          final classStartTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hour,
            minute,
          );

          // Notification time = 10 minutes BEFORE class
          final notifTime =
              classStartTime.subtract(Duration(minutes: _reminderMinutesBefore));

          // Skip if the notification time is already in the past
          if (notifTime.isBefore(now)) {
            skippedPast++;
            periodIndex++;
            continue;
          }

          final tzScheduled = tz.TZDateTime.from(notifTime, tz.local);

          final notifId =
              _buildNotifId(weekOffset, _dayIndex(dayName), periodIndex);

          final course = classMap['course']?.toString() ?? 'Class';
          final room = classMap['room']?.toString() ?? '';
          final section = classMap['section']?.toString() ?? displayName;

          final String title = isTeacher
              ? '👨‍🏫 Lecture in $_reminderMinutesBefore min'
              : '📚 Class in $_reminderMinutesBefore min';

          final String body = isTeacher
              ? '$course | $section | Room $room'
              : '$course | Room $room | $startTimeStr';

          try {
            await _scheduleNotification(
              id: notifId,
              title: title,
              body: body,
              scheduledTime: tzScheduled,
            );
            scheduledCount++;

            // Log first few for debugging
            if (scheduledCount <= 5) {
              debugPrint(
                  '[NotificationService]   #$notifId → $dayName $startTimeStr '
                  '(notify at $tzScheduled) — $course');
            }
          } catch (e) {
            debugPrint(
                '[NotificationService] ERROR scheduling #$notifId: $e');
          }

          periodIndex++;
        }
      }
    }

    debugPrint(
        '[NotificationService] Done: $scheduledCount scheduled, '
        '$skippedPast skipped (past), $skippedNoPeriod skipped (no period).');
  }

  /// Cancels all pending class notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled.');
  }

  /// Returns the list of pending notification requests (for debugging).
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming class periods',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Deterministic notification ID: unique per week + day + period slot.
  static int _buildNotifId(int weekOffset, int dayIndex, int periodIndex) {
    return (weekOffset * 1000) + (dayIndex * 100) + periodIndex;
  }

  static int _dayIndex(String dayName) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return days.indexOf(dayName);
  }

  /// Returns the date of the [targetWeekday] in the week [weekOffset] weeks from [from].
  static DateTime _nextWeekday(
      DateTime from, int targetWeekday, int weekOffset) {
    // Start of this ISO week (Monday)
    final weekStart =
        from.subtract(Duration(days: from.weekday - DateTime.monday));
    final weekBase = weekStart.add(Duration(days: 7 * weekOffset));
    return weekBase
        .add(Duration(days: targetWeekday - DateTime.monday))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }
}
