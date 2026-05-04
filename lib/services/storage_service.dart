import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_entry.dart';
import '../models/interval_session.dart';
import '../models/active_session_state.dart';
import '../models/timer_interval.dart';

class StorageService {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keySound = 'sound_on';
  static const String _keyVibration = 'vibration_on';
  static const String _keyActiveSession = 'active_session';
  static const String _keyTemplates = 'custom_templates';
  static const String _keyHasSeededTemplates = 'has_seeded_templates';
  static const String _historyBoxName = 'history_box';

  SharedPreferences? _prefs;
  Box<HistoryEntry>? _historyBox;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    Hive.registerAdapter(HistoryEntryAdapter());
    _historyBox = await Hive.openBox<HistoryEntry>(_historyBoxName);
  }

  // Settings
  bool get isDarkMode => _prefs?.getBool(_keyDarkMode) ?? true; // Premium default
  bool get isSoundOn => _prefs?.getBool(_keySound) ?? true;
  bool get isVibrationOn => _prefs?.getBool(_keyVibration) ?? true;

  Future<void> setDarkMode(bool value) async => _prefs?.setBool(_keyDarkMode, value);
  Future<void> setSound(bool value) async => _prefs?.setBool(_keySound, value);
  Future<void> setVibration(bool value) async => _prefs?.setBool(_keyVibration, value);

  // Active Session
  Future<void> saveActiveSession(ActiveSessionState state) async {
    await _prefs?.setString(_keyActiveSession, jsonEncode(state.toJson()));
  }

  ActiveSessionState? loadActiveSession() {
    final String? data = _prefs?.getString(_keyActiveSession);
    if (data == null) return null;
    try {
      return ActiveSessionState.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    await _prefs?.remove(_keyActiveSession);
  }

  // Templates
  Future<void> saveTemplates(List<IntervalSession> templates) async {
    final List<String> encoded = templates.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs?.setStringList(_keyTemplates, encoded);
  }

  List<IntervalSession> loadTemplates() {
    final bool hasSeeded = _prefs?.getBool(_keyHasSeededTemplates) ?? false;
    final List<String>? data = _prefs?.getStringList(_keyTemplates);
    
    if (!hasSeeded && (data == null || data.isEmpty)) {
      _prefs?.setBool(_keyHasSeededTemplates, true);
      final seeded = [
        IntervalSession(id: 's1', name: "Workout - 15 mins", intervals: [
           TimerInterval(id: 's1i1', name: "Running", durationSeconds: 300, colorValue: 0xFF2196F3),
           TimerInterval(id: 's1i2', name: "Break", durationSeconds: 300, colorValue: 0xFF4CAF50),
           TimerInterval(id: 's1i3', name: "Running", durationSeconds: 300, colorValue: 0xFF2196F3),
        ]),
        IntervalSession(id: 's2', name: "Study - 45 mins", intervals: [
           TimerInterval(id: 's2i1', name: "Studying", durationSeconds: 1800, colorValue: 0xFF9C27B0),
           TimerInterval(id: 's2i2', name: "Break", durationSeconds: 300, colorValue: 0xFF4CAF50),
           TimerInterval(id: 's2i3', name: "Test", durationSeconds: 600, colorValue: 0xFFFF9800),
        ]),
        IntervalSession(id: 's3', name: "Work - 60 mins", intervals: [
           TimerInterval(id: 's3i1', name: "Work", durationSeconds: 3000, colorValue: 0xFFF44336),
           TimerInterval(id: 's3i2', name: "Break", durationSeconds: 600, colorValue: 0xFF4CAF50),
        ]),
      ];
      saveTemplates(seeded);
      return seeded;
    }

    if (data == null) return [];
    try {
      return data.map((e) => IntervalSession.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      return [];
    }
  }

  // History
  Future<void> addHistoryEntry(HistoryEntry entry) async {
    await _historyBox?.add(entry);
  }

  List<HistoryEntry> getHistoryEntries() {
    return _historyBox?.values.toList() ?? [];
  }
}
