import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezones with all timezone data
    tz.initializeTimeZones();
    
    // Get local timezone
    final String currentTimeZone = DateTime.now().timeZoneName;
    debugPrint('Current timezone: $currentTimeZone');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('Notifications initialized successfully');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - opens the app
    debugPrint('Notification tapped: ${response.payload}');
    // The app will open automatically when notification is tapped
  }

  Future<bool> requestPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission() ?? false;
      debugPrint('Android notification permission: $granted');
      return granted;
    }

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      debugPrint('iOS notification permission: $granted');
      return granted;
    }

    return false;
  }

  Future<void> scheduleEveryHours({
    required int id,
    required String medicationName,
    required int hours,
    String? dosing,
    int? totalDoses,
  }) async {
    await cancelNotification(id);

    final now = DateTime.now();
    var nextDose = DateTime(now.year, now.month, now.day, now.hour);

    // Schedule notifications for the next month or until totalDoses reached
    int doseCount = 0;
    final maxDoses = totalDoses ?? 100; // Default to 100 if unlimited

    while (doseCount < maxDoses && doseCount < 100) {
      nextDose = nextDose.add(Duration(hours: hours));

      await _scheduleNotification(
        id: id + doseCount,
        title: 'Time to take your medication',
        body: _buildNotificationBody(medicationName, dosing),
        scheduledDate: nextDose,
      );

      doseCount++;
    }
  }

  Future<void> scheduleFixedHours({
    required int id,
    required String medicationName,
    required List<TimeOfDay> times,
    String? dosing,
    int? totalDoses,
  }) async {
    await cancelNotification(id);

    final now = DateTime.now();
    int notificationId = id;

    debugPrint('=== Scheduling Fixed Hours ===');
    debugPrint('Medication: $medicationName');
    debugPrint('Times: ${times.map((t) => '${t.hour}:${t.minute}').join(', ')}');
    debugPrint('Current time: $now');

    // Calculate total days needed
    final dosesPerDay = times.length;
    final daysNeeded = totalDoses != null ? (totalDoses / dosesPerDay).ceil() : 30;

    int scheduledCount = 0;
    for (int day = 0; day < daysNeeded && day < 30; day++) {
      final targetDate = now.add(Duration(days: day));

      for (final time in times) {
        var scheduledDate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          time.hour,
          time.minute,
        );

        // Only schedule if in the future
        if (scheduledDate.isAfter(now)) {
          await _scheduleNotification(
            id: notificationId++,
            title: 'Time to take your medication',
            body: _buildNotificationBody(medicationName, dosing),
            scheduledDate: scheduledDate,
          );
          scheduledCount++;
        }
      }
    }
    
    debugPrint('Total notifications scheduled: $scheduledCount');
  }

  Future<void> scheduleEveryDays({
    required int id,
    required String medicationName,
    required int days,
    required List<TimeOfDay> times,
    String? dosing,
    int? totalDoses,
  }) async {
    await cancelNotification(id);

    final now = DateTime.now();
    int notificationId = id;

    // Calculate cycles needed
    final dosesPerCycle = times.length;
    final cyclesNeeded = totalDoses != null ? (totalDoses / dosesPerCycle).ceil() : 30;

    for (int cycle = 0; cycle < cyclesNeeded && cycle < 30; cycle++) {
      final targetDate = now.add(Duration(days: days * cycle));

      for (final time in times) {
        var scheduledDate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          time.hour,
          time.minute,
        );

        // Only schedule if in the future
        if (scheduledDate.isAfter(now)) {
          await _scheduleNotification(
            id: notificationId++,
            title: 'Time to take your medication',
            body: _buildNotificationBody(medicationName, dosing),
            scheduledDate: scheduledDate,
          );
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    debugPrint('Scheduling notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Body: $body');
    debugPrint('  Scheduled for: $scheduledDate');
    debugPrint('  TZ Scheduled for: $tzScheduledDate');
    debugPrint('  Current time: ${DateTime.now()}');

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'medication_reminder',
    );
    
    debugPrint('Notification scheduled successfully with ID: $id');
  }

  String _buildNotificationBody(String medicationName, String? dosing) {
    if (dosing != null && dosing.isNotEmpty) {
      return '$medicationName - $dosing';
    }
    return medicationName;
  }

  Future<void> cancelNotification(int id) async {
    // Cancel the base notification and potential related ones
    for (int i = 0; i < 100; i++) {
      await _notifications.cancel(id + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Test method - schedules a notification 5 seconds from now
  Future<void> scheduleTestNotification() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
    
    await _scheduleNotification(
      id: 99999,
      title: 'Test Notification',
      body: 'This is a test notification scheduled 5 seconds ago',
      scheduledDate: scheduledDate,
    );
    
    debugPrint('Test notification scheduled for 5 seconds from now');
  }
}
