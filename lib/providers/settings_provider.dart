import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  late bool _isSoundOn;
  late bool _isVibrationOn;

  SettingsProvider(this._storageService) {
    _isSoundOn = _storageService.isSoundOn;
    _isVibrationOn = _storageService.isVibrationOn;
  }

  bool get isSoundOn => _isSoundOn;
  bool get isVibrationOn => _isVibrationOn;

  void toggleSound() {
    _isSoundOn = !_isSoundOn;
    _storageService.setSound(_isSoundOn);
    notifyListeners();
  }

  void toggleVibration() {
    _isVibrationOn = !_isVibrationOn;
    _storageService.setVibration(_isVibrationOn);
    notifyListeners();
  }
}
