import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/active_session_state.dart';
import '../models/history_entry.dart';
import 'notification_service.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  final FlutterBackgroundService service = FlutterBackgroundService();

  Future<void> initialize() async {
    await NotificationService().initialize();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        initialNotificationTitle: 'Interva',
        initialNotificationContent: 'Preparing Timer...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startSession(ActiveSessionState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_session', jsonEncode(state.toJson()));
    await service.startService();
  }

  void stopSession() {
    service.invoke("stopService");
  }

  void pauseSession() {
    service.invoke("pauseService");
  }

  void resumeSession() {
    service.invoke("resumeService");
  }

  void skipNext() {
    service.invoke("skipNext");
  }

  void skipPrevious() {
    service.invoke("skipPrevious");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  await NotificationService().initialize(requestPermissions: false);
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryEntryAdapter());
  final historyBox = await Hive.openBox<HistoryEntry>('history_box');
  final prefs = await SharedPreferences.getInstance();
  Timer? timer;
  bool isPaused = false;

  service.on('stopService').listen((event) {
    timer?.cancel();
    historyBox.close();
    service.stopSelf();
  });

  service.on('pauseService').listen((event) {
    isPaused = true;
  });

  service.on('resumeService').listen((event) {
    isPaused = false;
  });

  service.on('skipNext').listen((event) async {
    final data = prefs.getString('active_session');
    if (data != null) {
      final state = ActiveSessionState.fromJson(jsonDecode(data));
      if (state.currentIndex < state.intervals.length - 1) {
        final newState = ActiveSessionState(
          intervals: state.intervals,
          currentIndex: state.currentIndex + 1,
          secondsLeft: state.intervals[state.currentIndex + 1].durationSeconds,
        );
        await prefs.setString('active_session', jsonEncode(newState.toJson()));
        service.invoke('update', newState.toJson());
      } else {
        timer?.cancel();
        await prefs.remove('active_session');
        service.invoke('completed');
        service.stopSelf();
      }
    }
  });

  service.on('skipPrevious').listen((event) async {
    final data = prefs.getString('active_session');
    if (data != null) {
      final state = ActiveSessionState.fromJson(jsonDecode(data));
      if (state.currentIndex > 0) {
        final newState = ActiveSessionState(
          intervals: state.intervals,
          currentIndex: state.currentIndex - 1,
          secondsLeft: state.intervals[state.currentIndex - 1].durationSeconds,
        );
        await prefs.setString('active_session', jsonEncode(newState.toJson()));
        service.invoke('update', newState.toJson());
      }
    }
  });

  timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isPaused) return;

    final data = prefs.getString('active_session');
    if (data == null) {
      timer.cancel();
      service.stopSelf();
      return;
    }

    final state = ActiveSessionState.fromJson(jsonDecode(data));

    if (state.secondsLeft > 0) {
      final newState = ActiveSessionState(
        intervals: state.intervals,
        currentIndex: state.currentIndex,
        secondsLeft: state.secondsLeft - 1,
      );
      await prefs.setString('active_session', jsonEncode(newState.toJson()));
      
      service.invoke('update', newState.toJson());

      String nextName = state.currentIndex < state.intervals.length - 1 
          ? state.intervals[state.currentIndex + 1].name 
          : 'None';
          
      NotificationService().updateOngoingNotification(
        state.intervals[state.currentIndex].name,
        newState.secondsLeft,
        nextName,
      );
    } else {
      bool soundOn = prefs.getBool('sound_on') ?? true;
      bool vibOn = prefs.getBool('vibration_on') ?? true;
      NotificationService().triggerCompletionAlert(soundOn, vibOn);

      historyBox.add(HistoryEntry(
        intervalName: state.intervals[state.currentIndex].name,
        durationSeconds: state.intervals[state.currentIndex].durationSeconds,
        completedAt: DateTime.now(),
      ));

      if (state.currentIndex < state.intervals.length - 1) {
        final nextState = ActiveSessionState(
          intervals: state.intervals,
          currentIndex: state.currentIndex + 1,
          secondsLeft: state.intervals[state.currentIndex + 1].durationSeconds,
        );
        await prefs.setString('active_session', jsonEncode(nextState.toJson()));
        service.invoke('update', nextState.toJson());
      } else {
        timer.cancel();
        await prefs.remove('active_session');
        service.invoke('completed');
        historyBox.close();
        service.stopSelf();
      }
    }
  });
}
