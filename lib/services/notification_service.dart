import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../providers/chat_provider.dart';
import '../screens/conversation_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? initialPayload;

  static void handleNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final context = navigatorKey.currentContext;
    if (context != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (payload == 'none') {
        chatProvider.setTabIndex(1);
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        chatProvider.setTabIndex(0);
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ConversationScreen(chatId: payload),
          ),
        );
      }
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // Set local location to Asia/Kolkata as default for this environment, fallback if error
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // Fallback
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          handleNotificationClick(response.payload);
        }
      },
    );

    try {
      final NotificationAppLaunchDetails? details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        initialPayload = details?.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint("Error reading notification app launch details: $e");
    }
  }

  static Future<void> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("Error requesting notifications permission: $e");
    }

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint("Error requesting exact alarms permission: $e");
    }

    try {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint("Error requesting iOS permissions: $e");
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("Notification ignored: Scheduled time ($scheduledTime) is in the past compared to current time (${DateTime.now()})");
      return;
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime.toUtc(),
      tz.UTC,
    );

    debugPrint("Scheduling notification: ID: $id, Title: '$title', Time: $tzScheduledTime (UTC), Milliseconds: ${tzScheduledTime.millisecondsSinceEpoch}");

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'memzy_alarm_reminders_channel_v1',
      'Memzy Alarm Reminders',
      channelDescription: 'Channel for high priority, alarm-like reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(<int>[0, 1000, 500, 1000, 500, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT loops sound and vibration until dismissed
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint("Notification scheduled successfully via exact alarm!");
    } catch (e) {
      debugPrint("SecurityException or error scheduling exact alarm: $e. Falling back to inexact alarm.");
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint("Notification scheduled successfully via inexact alarm fallback!");
      } catch (e2) {
        debugPrint("Failed to schedule fallback alarm: $e2");
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
