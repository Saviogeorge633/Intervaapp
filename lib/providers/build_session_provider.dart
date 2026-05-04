import 'package:flutter/material.dart';
import '../models/timer_interval.dart';
import '../models/interval_session.dart';
import '../services/storage_service.dart';

class BuildSessionProvider extends ChangeNotifier {
  final StorageService _storageService;
  
  List<IntervalSession> _templates = [];
  List<TimerInterval> _currentIntervals = [];
  String _currentSessionName = "Custom Set";

  BuildSessionProvider(this._storageService) {
    _loadTemplates();
  }

  StorageService get storageService => _storageService;
  List<IntervalSession> get templates => _templates;
  List<TimerInterval> get currentIntervals => _currentIntervals;
  String get currentSessionName => _currentSessionName;

  void _loadTemplates() {
    _templates = _storageService.loadTemplates();
    notifyListeners();
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + DateTime.now().microsecond.toString();

  void addInterval(String name, int durationSeconds, int colorValue) {
    final newInterval = TimerInterval(
      id: _generateId(),
      name: name,
      durationSeconds: durationSeconds,
      colorValue: colorValue,
    );
    _currentIntervals.add(newInterval);
    notifyListeners();
  }

  void editInterval(String id, String name, int durationSeconds, int colorValue) {
    final index = _currentIntervals.indexWhere((i) => i.id == id);
    if (index != -1) {
      _currentIntervals[index] = TimerInterval(
        id: id,
        name: name,
        durationSeconds: durationSeconds,
        colorValue: colorValue,
      );
      notifyListeners();
    }
  }

  void removeInterval(String id) {
    _currentIntervals.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void reorderIntervals(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _currentIntervals.removeAt(oldIndex);
    _currentIntervals.insert(newIndex, item);
    notifyListeners();
  }

  void setSessionName(String name) {
    _currentSessionName = name;
    notifyListeners();
  }

  void saveCurrentAsTemplate() {
    if (_currentIntervals.isEmpty) return;
    final session = IntervalSession(
      id: _generateId(),
      name: _currentSessionName,
      intervals: List.from(_currentIntervals),
    );
    _templates.add(session);
    _storageService.saveTemplates(_templates);
    notifyListeners();
  }

  void removeTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    _storageService.saveTemplates(_templates);
    notifyListeners();
  }

  
  void loadTemplate(IntervalSession template) {
    _currentSessionName = template.name;
    _currentIntervals = List.from(template.intervals);
    notifyListeners();
  }

  void clearCurrent() {
    _currentIntervals.clear();
    _currentSessionName = "Custom Set";
    notifyListeners();
  }
}
