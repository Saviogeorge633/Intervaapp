import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
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
    final running = await service.isRunning();
    if (running) {
      // Silent stop — no events sent, just die quietly
      service.invoke("silentStop");
      await Future.delayed(const Duration(milliseconds: 600));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_session', jsonEncode(state.toJson()));
    await service.startService();
    
    // Trigger start alert
    bool soundOn = prefs.getBool('sound_on') ?? true;
    bool vibOn = prefs.getBool('vibration_on') ?? true;
    NotificationService().triggerStartAlert(soundOn, vibOn);
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
  Timer? ticker;
  bool isPaused = false;
  bool isStopping = false;

  void doStop({bool sendEvent = true}) {
    if (isStopping) return;
    isStopping = true;
    ticker?.cancel();
    IsolateNameServer.removePortNameMapping('interva_timer_service');
    prefs.remove('active_session');
    prefs.setBool('stop_requested', false);
    NotificationService().cancelOngoingNotification();
    if (sendEvent) service.invoke('stopped');
    historyBox.close();
    service.stopSelf();
  }

  // Notification "Stop" button writes a flag we check each tick
  NotificationService.onActionCallback = (String actionId) {
    if (actionId == 'stop_timer') {
      doStop(sendEvent: true);
    }
  };

  final ReceivePort port = ReceivePort();
  IsolateNameServer.removePortNameMapping('interva_timer_service');
  IsolateNameServer.registerPortWithName(port.sendPort, 'interva_timer_service');

  port.listen((message) {
    if (message == 'stop_timer') {
      doStop(sendEvent: true);
    } else if (message == 'pause_timer') {
      isPaused = true;
    } else if (message == 'resume_timer') {
      isPaused = false;
    }
  });

  service.on('stopService').listen((event) => doStop(sendEvent: true));
  service.on('silentStop').listen((event) => doStop(sendEvent: false));

  service.on('pauseService').listen((event) {
    isPaused = true;
    // Send immediate update to sync UI
    final data = prefs.getString('active_session');
    if (data != null) {
      service.invoke('update', {
        'state': jsonDecode(data),
        'isPaused': true,
      });
    }
  });

  service.on('resumeService').listen((event) {
    isPaused = false;
    // Send immediate update to sync UI
    final data = prefs.getString('active_session');
    if (data != null) {
      service.invoke('update', {
        'state': jsonDecode(data),
        'isPaused': false,
      });
    }
  });

  // NEW: UI can request an immediate state update
  service.on('requestUpdate').listen((event) {
    final data = prefs.getString('active_session');
    if (data != null) {
      service.invoke('update', {
        'state': jsonDecode(data),
        'isPaused': isPaused,
      });
    }
  });

  service.on('skipNext').listen((event) async {
    final data = prefs.getString('active_session');
    if (data != null) {
      final state = ActiveSessionState.fromJson(jsonDecode(data));
      final totalDuration = state.intervals[state.currentIndex].durationSeconds;
      final elapsed = totalDuration - state.secondsLeft;

      // Record in history if the user ran this task for more than 10 seconds
      if (elapsed > 10) {
        await historyBox.add(HistoryEntry(
          intervalName: state.intervals[state.currentIndex].name,
          durationSeconds: totalDuration,
          actualSeconds: elapsed,
          completedAt: DateTime.now(),
        ));
      }

      if (state.currentIndex < state.intervals.length - 1) {
        final newState = ActiveSessionState(
          intervals: state.intervals,
          currentIndex: state.currentIndex + 1,
          secondsLeft: state.intervals[state.currentIndex + 1].durationSeconds,
        );
        await prefs.setString('active_session', jsonEncode(newState.toJson()));
        service.invoke('update', {
          'state': newState.toJson(),
          'isPaused': isPaused,
        });
      } else {
        ticker?.cancel();
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
        service.invoke('update', {
          'state': newState.toJson(),
          'isPaused': isPaused,
        });
      }
    }
  });

  ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
    if (isStopping) return;

    // 1. Check for notification Stop request (cross-isolate flag)
    await prefs.reload();
    if (prefs.getBool('stop_requested') == true) {
      await prefs.setBool('stop_requested', false);
      doStop(sendEvent: true);
      return;
    }

    // 2. Fetch current state
    final data = prefs.getString('active_session');
    if (data == null) {
      t.cancel();
      service.stopSelf();
      return;
    }

    // 3. Always send an update to keep UI in sync, even if paused
    final state = ActiveSessionState.fromJson(jsonDecode(data));
    service.invoke('update', {
      'state': state.toJson(),
      'isPaused': isPaused,
    });

    if (isPaused) return;

    if (state.secondsLeft > 0) {
      final newState = ActiveSessionState(
        intervals: state.intervals,
        currentIndex: state.currentIndex,
        secondsLeft: state.secondsLeft - 1,
      );
      await prefs.setString('active_session', jsonEncode(newState.toJson()));
      service.invoke('update', {
        'state': newState.toJson(),
        'isPaused': isPaused,
      });

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
        actualSeconds: state.intervals[state.currentIndex].durationSeconds, // fully completed
        completedAt: DateTime.now(),
      ));

      if (state.currentIndex < state.intervals.length - 1) {
        final nextState = ActiveSessionState(
          intervals: state.intervals,
          currentIndex: state.currentIndex + 1,
          secondsLeft: state.intervals[state.currentIndex + 1].durationSeconds,
        );
        await prefs.setString('active_session', jsonEncode(nextState.toJson()));
        service.invoke('update', {
          'state': nextState.toJson(),
          'isPaused': isPaused,
        });
      } else {
        t.cancel();
        await prefs.remove('active_session');
        NotificationService().cancelOngoingNotification();
        service.invoke('completed');
        historyBox.close();
        service.stopSelf();
      }
    }
  });
}
