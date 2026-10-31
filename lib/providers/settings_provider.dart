import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/database_service.dart';
import '../../core/utils/file_size_formatter.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _pauseIndexing = false;
  bool _autoAddScreenshots = true;
  int _storageUsedBytes = 48 * 1024 * 1024; // 48 MB default matching screenshot

  ThemeMode get themeMode => _themeMode;
  bool get pauseIndexing => _pauseIndexing;
  bool get autoAddScreenshots => _autoAddScreenshots;
  int get storageUsedBytes => _storageUsedBytes;
  String get formattedStorage => FileSizeFormatter.format(_storageUsedBytes);

  String get themeModeDisplay {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode') ?? 'dark';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    _pauseIndexing = prefs.getBool('pause_indexing') ?? false;
    _autoAddScreenshots = prefs.getBool('auto_add_screenshots') ?? true;

    final actualBytes = await DatabaseService.instance.getTotalStorageBytes();
    if (actualBytes > 0) {
      _storageUsedBytes = actualBytes;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.system) modeStr = 'system';
    await prefs.setString('theme_mode', modeStr);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setPauseIndexing(bool value) async {
    _pauseIndexing = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pause_indexing', value);
    notifyListeners();
  }

  Future<void> setAutoAddScreenshots(bool value) async {
    _autoAddScreenshots = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_add_screenshots', value);
    notifyListeners();
  }

  Future<void> clearLocalIndex() async {
    await DatabaseService.instance.clearAllIndexedFiles();
    await DatabaseService.instance.clearSearchHistory();
    _storageUsedBytes = 0;
    notifyListeners();
  }

  Future<void> exportIndex() async {
    final jsonStr = await DatabaseService.instance.exportDatabaseJson();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/bulbeni_dizin_yedek.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'BulBeni Dizin Yedeği (JSON)',
    );
  }
}
