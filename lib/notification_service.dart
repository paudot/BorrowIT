import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Time of the return reminder (8:00 AM on the return date).
// For testing, set this to a few minutes from now.
int reminderHour = 8;
int reminderMinute = 0;

// How the notifications look on Android
NotificationDetails borrowitDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'borrowit_channel',
    'BorrowIT',
    channelDescription: 'Request status updates and return reminders',
    importance: Importance.max,
    priority: Priority.high,
  ),
);

// Set up notifications (called once in main.dart)
Future<void> initNotifications() async {
  tz.initializeTimeZones();
  // Scheduled notifications need a time zone
  tz.setLocalLocation(tz.getLocation('Asia/Manila'));

  AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings: settings);

  // Android 13 and up asks the user for permission
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

// Shows a notification right away when the request status changes
Future<void> showStatusNotification(String equipmentName, String status) async {
  try {
    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await notificationsPlugin.show(
      id: id,
      title: 'Request $status',
      body: 'Your request for $equipmentName is now $status.',
      notificationDetails: borrowitDetails,
    );
  } catch (e) {
    debugPrint('Notification failed: $e');
  }
}

// Schedules the return reminder for the return date
// Schedules the return reminder for the return date
Future<void> scheduleReturnReminder(
    int reminderId, String equipmentName, DateTime returnDate) async {
  try {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime when = tz.TZDateTime(tz.local, returnDate.year,
        returnDate.month, returnDate.day, reminderHour, reminderMinute);
    debugPrint('Reminder: now = $now, reminder time = $when');

    // Skip if that time already passed
    if (when.isBefore(now)) {
      debugPrint('Reminder skipped: that time already passed');
      return;
    }
    // Needs the manifest receivers and permissions. The id lets us cancel it later
    await notificationsPlugin.zonedSchedule(
      id: reminderId,
      title: 'Return reminder',
      body: 'Please return the $equipmentName today.',
      scheduledDate: when,
      notificationDetails: borrowitDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    List<PendingNotificationRequest> pending =
        await notificationsPlugin.pendingNotificationRequests();
    debugPrint('Reminder scheduled. Pending notifications: ${pending.length}');
  } catch (e) {
    debugPrint('Reminder failed: $e');
  }
}

// Removes a scheduled reminder
Future<void> cancelReminder(int reminderId) async {
  try {
    await notificationsPlugin.cancel(id: reminderId);
  } catch (e) {
    debugPrint('Cancel reminder failed: $e');
  }
}