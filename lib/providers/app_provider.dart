import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/indexed_file.dart';
import '../data/services/database_service.dart';
import '../data/services/ocr_service.dart';

class AppProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _hasSeenOnboarding = true; // Default true or check SharedPreferences

  // Indexing State matching the screenshot card:
  // "1.248 öğe indekslendi   %62"
  // "Dizinleniyor · 47 dosya kaldı"
  bool _isIndexing = false;
  int _indexedCount = 1248;
  int _remainingCount = 47;
  double _progress = 0.62;

  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  int get currentTabIndex => _currentTabIndex;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isIndexing => _isIndexing;
  int get indexedCount => _indexedCount;
  int get remainingCount => _remainingCount;
  double get progress => _progress;

  AppProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    // Load actual count from database
    final count = await DatabaseService.instance.getIndexedCount();
    if (count > 0) {
      _indexedCount = count;
    }
    notifyListeners();
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
  }

  /// Lets the user add photos/screenshots, runs OCR, and adds them to index.
  Future<List<IndexedFile>> pickAndIndexImages({bool isScreenshot = false}) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) return [];

      _isIndexing = true;
      _remainingCount = pickedFiles.length;
      _progress = 0.1;
      notifyListeners();

      final List<IndexedFile> newIndexedFiles = [];
      final random = Random();

      for (int i = 0; i < pickedFiles.length; i++) {
        final xfile = pickedFiles[i];
        final file = File(xfile.path);
        final size = await file.length();
        final fileName = xfile.name;

        // Perform on-device OCR
        final ocrResult = await OcrService.instance.recognizeText(xfile.path);

        // Detect if screenshot based on name or flag
        final detectedScreenshot = isScreenshot ||
            fileName.toLowerCase().contains('screenshot') ||
            fileName.toLowerCase().contains('ekran');

        final indexedFile = IndexedFile(
          id: _uuid.v4(),
          name: fileName,
          path: xfile.path,
          category: detectedScreenshot ? 'ekran' : 'fotograf',
          size: size,
          ocrText: ocrResult,
          isScreenshot: detectedScreenshot,
          indexedAt: DateTime.now(),
          createdAt: DateTime.now(),
          thumbnailColorIndex: random.nextInt(6),
        );

        await DatabaseService.instance.insertFile(indexedFile);
        newIndexedFiles.add(indexedFile);

        _indexedCount++;
        _remainingCount = pickedFiles.length - (i + 1);
        _progress = (i + 1) / pickedFiles.length;
        notifyListeners();
      }

      _isIndexing = false;
      notifyListeners();
      return newIndexedFiles;
    } catch (e) {
      debugPrint('Error picking or indexing images: $e');
      _isIndexing = false;
      notifyListeners();
      return [];
    }
  }

  /// Simulates / runs full re-index
  Future<void> refreshIndex() async {
    _isIndexing = true;
    _remainingCount = 12;
    _progress = 0.2;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _progress = 0.55;
    _remainingCount = 6;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _progress = 1.0;
    _remainingCount = 0;
    _isIndexing = false;

    final count = await DatabaseService.instance.getIndexedCount();
    _indexedCount = count;
    notifyListeners();
  }
}
