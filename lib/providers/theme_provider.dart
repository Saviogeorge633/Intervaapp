import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  late bool _isDarkMode;

  ThemeProvider(this._storageService) {
    _isDarkMode = _storageService.isDarkMode;
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
