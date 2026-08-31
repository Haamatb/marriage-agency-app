// ─────────────────────────────────────────────────────────────────────────────
// notification_service.dart — Local push notifications (Android)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../../features/marriages/data/dao/marriage_dao.dart';
import '../../features/agencies/data/dao/agency_dao.dart';

// ── Background Worker Callback (top-level) ────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == BackgroundWorkerService.kDailyCheckTask) {
      await BackgroundWorkerService._runDailyCheck();
    }
    return Future.value(true);
  });
}

// ── Notification Service ──────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'marriage_agency_channel';
  static const _channelName = 'توثيق الزواجات والوكالات';
  static const _channelDesc = 'إشعارات التذكير والنواقص';

  Future<void> init() async {
    if (!Platform.isAndroid) return;

    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (_) {
        // Fallback to local timezone
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Navigate to the relevant record when notification tapped
        },
      );

      // Create notification channel
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request notification permission (Android 13+)
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      // Graceful fallback if notification permission or channel init fails
      // ignore: avoid_print
      print('NotificationService init notice: $e');
    }
  }

  // ── Schedule Marriage Reminder ────────────────────────────────────────────
  Future<void> scheduleMarriageReminder({
    required int notificationId,
    required String husbandName,
    required String wifeName,
    required DateTime marriageDateTime,
    int minutesBefore = 60,
  }) async {
    if (!Platform.isAndroid) return;

    final scheduledTime = tz.TZDateTime.from(
      marriageDateTime.subtract(Duration(minutes: minutesBefore)),
      tz.local,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      notificationId,
      'تذكير بعقد زواج',
      'عقد زواج $husbandName و$wifeName خلال $minutesBefore دقيقة',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Show Pending Documents Alert ──────────────────────────────────────────
  Future<void> showPendingDocumentsAlert({
    required int count,
    required String details,
  }) async {
    if (!Platform.isAndroid) return;

    await _plugin.show(
      9999,
      'ملفات تحتاج متابعة',
      '$count سجل يحتاج إكمال ($details)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            '$count سجل يحتاج إكمال الوثائق:\n$details',
          ),
        ),
      ),
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}

// ── Background Worker ─────────────────────────────────────────────────────────

class BackgroundWorkerService {
  static const kDailyCheckTask = 'daily_stale_records_check';

  static Future<void> init() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register daily periodic task
    await Workmanager().registerPeriodicTask(
      kDailyCheckTask,
      kDailyCheckTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  static Future<void> _runDailyCheck() async {
    // Query stale records from local DB
    final marriageDao = MarriageDao.instance;
    final agencyDao = AgencyDao.instance;

    final staleMarriages = await marriageDao.getStaleRecords(daysThreshold: 3);
    final staleAgencies = await agencyDao.getStaleRecords(daysThreshold: 3);

    final totalStale = staleMarriages.length + staleAgencies.length;

    if (totalStale > 0) {
      final details = <String>[];
      if (staleMarriages.isNotEmpty) {
        details.add('${staleMarriages.length} زواج');
      }
      if (staleAgencies.isNotEmpty) {
        details.add('${staleAgencies.length} وكالة');
      }

      await NotificationService.instance.showPendingDocumentsAlert(
        count: totalStale,
        details: details.join(' و'),
      );
    }
  }
}
