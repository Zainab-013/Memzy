import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../providers/chat_provider.dart';
import '../screens/conversation_screen.dart';

class NotificationService {
  static const MethodChannel _alarmChannel = MethodChannel('com.stitch.memzy/alarm');

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? initialPayload;

  static void handleNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    
    // Payload can be "reminderId|chatId" or just "chatId"
    String targetChatId = payload;
    if (payload.contains('|')) {
      final parts = payload.split('|');
      targetChatId = parts.length > 1 ? parts[1] : parts[0];
    }

    final context = navigatorKey.currentContext;
    if (context != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (targetChatId == 'none') {
        chatProvider.setTabIndex(1);
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        chatProvider.setTabIndex(0);
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ConversationScreen(chatId: targetChatId),
          ),
        );
      }
    }
  }

  static void _handleStopAlarmAction(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.contains('|')) {
      final parts = payload.split('|');
      final reminderId = parts[0];
      final context = navigatorKey.currentContext;
      if (context != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.toggleReminderCompletion(reminderId);
      }
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("Local timezone successfully set to: $timeZoneName");
    } catch (e) {
      debugPrint("Failed to set timezone using FlutterTimezone ($e). Falling back to Asia/Kolkata.");
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

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
        if (response.notificationResponseType == NotificationResponseType.selectedNotificationAction &&
            response.actionId == 'stop_alarm') {
          _handleStopAlarmAction(response);
        } else if (response.payload != null) {
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

    try {
      if (Platform.isAndroid) {
        // Check & Request Exact Alarm Permission if not granted
        final bool canSchedule = await _alarmChannel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
        if (!canSchedule) {
          await _alarmChannel.invokeMethod('requestExactAlarmPermission');
        }
      }
    } catch (e) {
      debugPrint("Error requesting exact alarm permission via native bridge: $e");
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _alarmChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? true;
    } catch (e) {
      debugPrint("Error checking battery optimization status: $e");
      return true;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _alarmChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint("Error requesting battery optimization exemption: $e");
    }
  }

  static Future<void> openAppInfoSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _alarmChannel.invokeMethod('openAppInfoSettings');
    } catch (e) {
      debugPrint("Error opening app info settings: $e");
    }
  }


  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isAlarm = true,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("Notification ignored: Scheduled time ($scheduledTime) is in the past compared to current time (${DateTime.now()})");
      return;
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    debugPrint("Scheduling notification: ID: $id, Title: '$title', Time: $tzScheduledTime (Local), Milliseconds: ${tzScheduledTime.millisecondsSinceEpoch}, isAlarm: $isAlarm");


    final AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'memzy_reminders_channel_v8',
      'Memzy Reminders',
      channelDescription: 'Channel for all Memzy reminder notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    bool canUseExact = false;
    try {
      if (androidImplementation != null) {
        canUseExact = await androidImplementation.canScheduleExactNotifications() ?? false;
      }
    } catch (_) {}

    final AndroidScheduleMode scheduleMode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint("Notification scheduled successfully using $scheduleMode!");
    } catch (e) {
      debugPrint("Error scheduling alarm: $e. Falling back to inexact alarm.");
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
        debugPrint("Notification scheduled successfully via inexact fallback!");
      } catch (e2) {
        debugPrint("Failed to schedule fallback: $e2");
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    await _notificationsPlugin.cancel(id + 1);
  }
}
