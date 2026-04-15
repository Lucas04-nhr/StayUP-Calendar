import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import 'course_reminder.dart';
import 'models.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'course_reminder_channel';
  static const String _channelName = 'Course Reminders';
  static const String _channelDescription =
      'Reminder notifications before class';
  static const int _scheduleWindowDays = 14;
  static const int _maxPendingNotifications = 60;

  bool _syncing = false;
  bool _syncRequestedAgain = false;
  bool _pluginAvailable = true;
  bool _initialized = false;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      defaultPresentSound: true,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initializationSettings);
      await _requestPermissions();
      _initialized = true;
    } on MissingPluginException catch (e) {
      _pluginAvailable = false;
      debugPrint('LocalNotificationService unavailable: $e');
    }
  }

  bool get isPluginAvailable => _pluginAvailable;

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _requestPermissions() async {
    // Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permissions granted: $granted');
    }

    // macOS
    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macosPlugin != null) {
      await macosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<bool> showCourseReminder({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    if (!_pluginAvailable) {
      debugPrint('LocalNotificationService: show skipped - plugin unavailable');
      return false;
    }

    try {
      // Ensure permissions are requested before showing notification
      await _requestPermissions();

      debugPrint(
        'LocalNotificationService: showing notification id=$notificationId, title=$title, body=$body',
      );
      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: _notificationDetails,
      );
      debugPrint('LocalNotificationService: show completed successfully');
      return true;
    } on MissingPluginException catch (e) {
      _pluginAvailable = false;
      debugPrint('LocalNotificationService show failed: $e');
      return false;
    } catch (e) {
      debugPrint('LocalNotificationService show error: $e');
      return false;
    }
  }

  Future<void> syncCourseReminderSchedules(AppState appState) async {
    if (_syncing) {
      _syncRequestedAgain = true;
      return;
    }

    _syncing = true;
    try {
      do {
        _syncRequestedAgain = false;
        await _syncCourseReminderSchedulesInternal(appState);
      } while (_syncRequestedAgain);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncCourseReminderSchedulesInternal(AppState appState) async {
    if (!_pluginAvailable) {
      return;
    }

    await _plugin.cancelAllPendingNotifications();

    final reminderMinutes = appState.courseReminderMinutes;
    if (reminderMinutes <= 0) {
      return;
    }

    final l10n = _resolveAppLocalizations(appState);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week1Monday = _week1MondayFor(appState.config.firstWeekDay);
    final plans = <_ScheduledCourseReminder>[];

    for (var offset = 0; offset < _scheduleWindowDays; offset++) {
      final date = today.add(Duration(days: offset));
      final currentWeek = (date.difference(week1Monday).inDays ~/ 7) + 1;
      if (currentWeek < 1 || currentWeek > appState.config.totalWeeks) {
        continue;
      }

      for (final course in appState.courses) {
        if (course.day != date.weekday) continue;
        if (!course.weeks.contains(currentWeek)) continue;
        if (course.startSection < 1 ||
            course.startSection > appState.customTimes.length) {
          continue;
        }

        final startTimeStr = appState.customTimes[course.startSection - 1][0];
        final startMinutes = CourseReminderManager.timeStringToMinutes(
          startTimeStr,
        );
        final classStart = DateTime(
          date.year,
          date.month,
          date.day,
          startMinutes ~/ 60,
          startMinutes % 60,
        );
        final notifyAt = classStart.subtract(
          Duration(minutes: reminderMinutes),
        );

        if (!notifyAt.isAfter(now.add(const Duration(seconds: 5)))) {
          continue;
        }

        final location = course.location.isNotEmpty
            ? course.location
            : l10n.courseReminderLocationUnknown;
        final body = l10n.courseReminderNotificationBody(
          reminderMinutes,
          location,
          course.name,
        );

        plans.add(
          _ScheduledCourseReminder(
            id: _notificationId(course.id, date, reminderMinutes),
            notifyAt: notifyAt,
            title: '要上课了！',
            body: body,
          ),
        );
      }
    }

    plans.sort((a, b) => a.notifyAt.compareTo(b.notifyAt));

    for (final plan in plans.take(_maxPendingNotifications)) {
      await _plugin.zonedSchedule(
        id: plan.id,
        scheduledDate: tz.TZDateTime.from(plan.notifyAt, tz.local),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: plan.title,
        body: plan.body,
      );
    }
  }

  DateTime _week1MondayFor(DateTime firstWeekDay) {
    return firstWeekDay.subtract(Duration(days: firstWeekDay.weekday - 1));
  }

  int _notificationId(int courseId, DateTime date, int reminderMinutes) {
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    return (courseId * 100000000 + ymd + reminderMinutes) & 0x7fffffff;
  }

  AppLocalizations _resolveAppLocalizations(AppState appState) {
    final locale =
        appState.appLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
    return lookupAppLocalizations(locale);
  }
}

class _ScheduledCourseReminder {
  final int id;
  final DateTime notifyAt;
  final String title;
  final String body;

  const _ScheduledCourseReminder({
    required this.id,
    required this.notifyAt,
    required this.title,
    required this.body,
  });
}
