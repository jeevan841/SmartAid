// lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _setLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // v22: initialize() takes a named `settings` parameter
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;

    // Request permissions (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    debugPrint(
        '[NotificationService] Initialized, timezone=${tz.local.name}');
  }

  /// Schedule a daily repeating alarm for all time-slots of one medication.
  Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required List<String> scheduledTimes, // ["08:00", "20:30"]
  }) async {
    if (kIsWeb) return;
    await initialize();

    final baseId = _baseId(medicationId);

    for (int i = 0; i < scheduledTimes.length; i++) {
      final parts = scheduledTimes[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      await _scheduleDailyAt(
        notificationId: baseId + i,
        medicationName: medicationName,
        hour: hour,
        minute: minute,
      );
    }
  }

  /// Cancel all reminders for a medication (up to 10 slots per medication).
  Future<void> cancelMedicationReminders(String medicationId) async {
    if (kIsWeb) return;
    await initialize();
    final baseId = _baseId(medicationId);
    for (int i = 0; i < 10; i++) {
      // v22: cancel() takes a named `id` parameter
      await _plugin.cancel(id: baseId + i);
    }
    debugPrint('[NotificationService] Cancelled reminders for $medicationId');
  }

  /// Cancel every notification (e.g. on sign-out).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancelAll();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<void> _scheduleDailyAt({
    required int notificationId,
    required String medicationName,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Daily reminders to take your medications on time.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduleTime = _nextOccurrence(hour, minute);

    // v22: zonedSchedule() uses all named parameters
    await _plugin.zonedSchedule(
      id: notificationId,
      title: '💊 Time for $medicationName',
      body: 'Tap to open SmartAid and log your dose.',
      scheduledDate: scheduleTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // daily repeat
    );

    debugPrint(
      '[NotificationService] Scheduled "$medicationName" daily at '
      '$hour:${minute.toString().padLeft(2, '0')} (id=$notificationId)',
    );
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  void _setLocalTimezone() {
    final rawName = DateTime.now().timeZoneName;
    // Map common abbreviated names to IANA identifiers
    const fallbacks = {
      'IST': 'Asia/Kolkata',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'GMT': 'Etc/GMT',
      'BST': 'Europe/London',
      'CET': 'Europe/Paris',
    };

    String resolvedName = rawName;
    try {
      tz.getLocation(rawName); // Check if IANA name works directly
    } catch (_) {
      resolvedName = fallbacks[rawName] ?? 'UTC';
    }

    try {
      tz.setLocalLocation(tz.getLocation(resolvedName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Stable positive base-ID derived from Firestore document ID.
  int _baseId(String medicationId) =>
      (medicationId.hashCode.abs() % 1000000) * 10;
}
