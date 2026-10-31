import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/database_service.dart';
import '../data/services/device_scanner_service.dart';

class AppProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _hasSeenOnboarding = true;
  bool _hasPermission = false;

  bool _isIndexing = false;
  int _indexedCount = 0;
  int _remainingCount = 0;
  double _progress = 1.0;

  int get currentTabIndex => _currentTabIndex;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasPermission => _hasPermission;
  bool get isIndexing => _isIndexing;
  int get indexedCount => _indexedCount;
  int get remainingCount => _remainingCount;
  double get progress => _progress;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    _hasPermission = await DeviceScannerService.instance.hasPermission();

    // Check count in database
    final count = await DatabaseService.instance.getIndexedCount();
    _indexedCount = count;
    notifyListeners();

    if (_hasPermission) {
      await scanDevice();
    }
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    notifyListeners();

    // Request permissions right after onboarding
    await requestStoragePermissions();
  }

  Future<bool> requestStoragePermissions() async {
    final granted = await DeviceScannerService.instance.requestPermissions();
    _hasPermission = granted;
    notifyListeners();

    if (granted) {
      await scanDevice();
    }
    return granted;
  }

  Future<void> scanDevice() async {
    _isIndexing = true;
    _progress = 0.1;
    notifyListeners();

    await DeviceScannerService.instance.scanDeviceFiles(
      onProgress: (current, total) {
        _indexedCount = current;
        _remainingCount = (total - current).clamp(0, total);
        _progress = (current / total).clamp(0.0, 1.0);
        notifyListeners();
      },
    );

    final finalCount = await DatabaseService.instance.getIndexedCount();
    _indexedCount = finalCount;
    _isIndexing = false;
    _progress = 1.0;
    _remainingCount = 0;
    notifyListeners();
  }
}
