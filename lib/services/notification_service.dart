import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    if (requestPermissions) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'interva_timer_channel', 
      'Interva Timer', 
      description: 'Ongoing timer updates', 
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'interva_alert_channel',
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
    
    final body = '$timeStr left' + (nextIntervalName != 'None' ? ' · Next: $nextIntervalName' : '');

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'interva_timer_channel',
      'Interva Timer',
      channelDescription: 'Ongoing timer updates',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true, // Prevents continuous lock-screen beeps
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
      id: 888, // MUST MATCH flutter_background_service default ID
      title: 'Interva – $intervalName',
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> triggerCompletionAlert(bool soundOn, bool vibrationOn) async {
    if (vibrationOn) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
    }
    
    if (soundOn) {
      const AndroidNotificationDetails loudAndroid = AndroidNotificationDetails(
        'interva_alert_channel',
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
}
