import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) async {
  if (response.actionId == 'stop_timer') {
    DartPluginRegistrant.ensureInitialized();
    
    // 1. Try direct communication with the running service isolate
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('interva_timer_service');
    if (sendPort != null) {
      sendPort.send('stop_timer');
    }
    
    // 2. Fallback: Write the flag in case the ticker is between pulses or name server failed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stop_requested', true);
    
    // 3. Last resort: If service isn't running, clear the session data so it doesn't try to resume
    // This handles the "Kill session" part of the user's request.
    await prefs.remove('active_session');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Callback for notification action buttons.
  static void Function(String actionId)? onActionCallback;

  Future<void> initialize({bool requestPermissions = true}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
        
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: requestPermissions,
      requestBadgePermission: requestPermissions,
      requestAlertPermission: requestPermissions,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (onActionCallback != null && response.actionId != null) {
          onActionCallback!(response.actionId!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    if (requestPermissions) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'interva_timer_channel', 
      'Interva Timer', 
      description: 'Ongoing timer updates', 
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'interva_alert_channel_v2',
      'Interva Alerts',
      description: 'Alerts when intervals finish',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);
  }

  Future<void> updateOngoingNotification(String intervalName, int remainingSeconds, String nextIntervalName) async {
    final min = remainingSeconds ~/ 60;
    final sec = remainingSeconds % 60;
    final timeStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    
    final body = '$timeStr left${nextIntervalName != 'None' ? ' · Next: $nextIntervalName' : ''}';

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'interva_timer_channel',
      'Interva Timer',
      channelDescription: 'Ongoing timer updates',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@drawable/ic_notification',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'Interva – $intervalName',
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelOngoingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 888);
  }

  Future<void> triggerCompletionAlert(bool soundOn, bool vibrationOn) async {
    if (vibrationOn) {
      try {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [0, 500, 200, 500]);
        }
      } catch (e) {
        // Ignore vibration errors on unsupported devices
      }
    }
    
    if (soundOn) {
      const AndroidNotificationDetails loudAndroid = AndroidNotificationDetails(
        'interva_alert_channel_v2',
        'Interva Alerts',
        channelDescription: 'Alerts when intervals finish',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_notification',
      );
      
      const NotificationDetails loudDetails = NotificationDetails(
        android: loudAndroid,
        iOS: DarwinNotificationDetails(presentSound: true),
      );

      await flutterLocalNotificationsPlugin.show(
        id: 889,
        title: 'Interval Complete!',
        body: 'Moving to the next stage.',
        notificationDetails: loudDetails,
      );
    }
  }

  Future<void> triggerStartAlert(bool soundOn, bool vibrationOn) async {
    if (vibrationOn) {
      try {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [0, 200]); // Short vibration for start
        }
      } catch (e) {
        // Ignore
      }
    }
    
    if (soundOn) {
      const AndroidNotificationDetails loudAndroid = AndroidNotificationDetails(
        'interva_alert_channel_v2',
        'Interva Alerts',
        channelDescription: 'Alerts when intervals finish',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_notification',
      );
      
      const NotificationDetails loudDetails = NotificationDetails(
        android: loudAndroid,
        iOS: DarwinNotificationDetails(presentSound: true),
      );

      await flutterLocalNotificationsPlugin.show(
        id: 890,
        title: 'Timer Started!',
        body: 'Focus time.',
        notificationDetails: loudDetails,
      );
    }
  }
}
