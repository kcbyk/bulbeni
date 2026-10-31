import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/indexed_file.dart';
import 'database_service.dart';
import 'ocr_service.dart';

class DeviceScannerService {
  static final DeviceScannerService instance = DeviceScannerService._internal();
  DeviceScannerService._internal();

  final Uuid _uuid = const Uuid();
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Requests appropriate permissions based on Android version
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      // Check photos/media permission (Android 13+)
      final photosStatus = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();

      if (photosStatus.isGranted || storageStatus.isGranted) {
        return true;
      }

      // Check if manage external storage is needed for full file access
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted || photosStatus.isGranted || storageStatus.isGranted;
    }

    return true;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final photos = await Permission.photos.isGranted;
      final storage = await Permission.storage.isGranted;
      final manage = await Permission.manageExternalStorage.isGranted;
      return photos || storage || manage;
    }
    return true;
  }

  /// Scans device storage for photos, screenshots, and PDFs
  Future<List<IndexedFile>> scanDeviceFiles({
    void Function(int current, int total)? onProgress,
  }) async {
    if (_isScanning) return [];
    _isScanning = true;

    final List<IndexedFile> discoveredFiles = [];

    try {
      final List<Directory> scanDirs = [];

      if (Platform.isAndroid) {
        const root = '/storage/emulated/0';
        final paths = [
          '$root/DCIM/Camera',
          '$root/DCIM',
          '$root/Pictures/Screenshots',
          '$root/Pictures',
          '$root/Download',
          '$root/Documents',
        ];

        for (final p in paths) {
          final dir = Directory(p);
          if (dir.existsSync()) {
            scanDirs.add(dir);
          }
        }
      } else {
        // Desktop or other platform fallback
        final docsDir = await getApplicationDocumentsDirectory();
        final downloadsDir = await getDownloadsDirectory();
        final picturesDir = await getApplicationSupportDirectory();

        scanDirs.add(docsDir);
        if (downloadsDir != null && downloadsDir.existsSync()) scanDirs.add(downloadsDir);
        if (picturesDir.existsSync()) scanDirs.add(picturesDir);
      }

      final List<File> candidates = [];
      const validExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];

      for (final dir in scanDirs) {
        try {
          final entities = dir.listSync(recursive: false, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              if (validExtensions.any((ext) => lower.endsWith(ext))) {
                candidates.add(entity);
              }
            }
          }
        } catch (e) {
          debugPrint('Error accessing directory ${dir.path}: $e');
        }
      }

      // Sort newest first
      candidates.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      // Limit initial scan batch for quick responsiveness
      final batch = candidates.take(150).toList();

      for (int i = 0; i < batch.length; i++) {
        final file = batch[i];
        final path = file.path;
        final name = path.split(Platform.pathSeparator).last;
        final lowerName = name.toLowerCase();

        String category = 'fotograf';
        bool isScreenshot = false;

        if (lowerName.endsWith('.pdf')) {
          category = 'pdf';
        } else if (lowerName.contains('screenshot') ||
            lowerName.contains('ekran') ||
            path.contains('Screenshots')) {
          category = 'ekran';
          isScreenshot = true;
        }

        int size = 0;
        DateTime modified = DateTime.now();
        try {
          size = file.lengthSync();
          modified = file.lastModifiedSync();
        } catch (_) {}

        final indexedFile = IndexedFile(
          id: _uuid.v5(Uuid.NAMESPACE_URL, path),
          name: name,
          path: path,
          category: category,
          size: size,
          ocrText: '',
          isScreenshot: isScreenshot,
          indexedAt: DateTime.now(),
          createdAt: modified,
          thumbnailColorIndex: i % 6,
        );

        discoveredFiles.add(indexedFile);
        await DatabaseService.instance.insertFile(indexedFile);

        if (onProgress != null) {
          onProgress(i + 1, batch.length);
        }
      }

      // Trigger asynchronous background OCR on first 15 images
      _triggerBackgroundOcr(discoveredFiles.take(15).toList());

    } catch (e) {
      debugPrint('Device scan error: $e');
    } finally {
      _isScanning = false;
    }

    return discoveredFiles;
  }

  void _triggerBackgroundOcr(List<IndexedFile> files) {
    Future.microtask(() async {
      for (final file in files) {
        if (file.category == 'fotograf' || file.category == 'ekran') {
          try {
            final text = await OcrService.instance.recognizeText(file.path);
            if (text.isNotEmpty) {
              final updated = file.copyWith(ocrText: text);
              await DatabaseService.instance.updateFile(updated);
            }
          } catch (_) {}
        }
      }
    });
  }
}
