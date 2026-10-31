import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
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

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+)
    var photosStatus = await Permission.photos.request();
    await Permission.videos.request();
    await Permission.audio.request();

    if (photosStatus.isGranted) {
      return true;
    }

    // Android 12 and below
    var storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    // Last resort: manage external storage
    if (await Permission.manageExternalStorage.isDenied) {
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;
    }

    return photosStatus.isGranted || storageStatus.isGranted;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final photos = await Permission.photos.isGranted;
    final storage = await Permission.storage.isGranted;
    final manage = await Permission.manageExternalStorage.isGranted;
    return photos || storage || manage;
  }

  /// Scans ALL device files in a background isolate to avoid ANR
  Future<void> scanDeviceFiles({
    void Function(int current, int total, String file)? onProgress,
    void Function(int totalFound)? onComplete,
  }) async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      // Step 1: Collect all file paths in background isolate
      final receivePort = ReceivePort();
      await Isolate.spawn(_collectFilesIsolate, receivePort.sendPort);

      final List<String> allPaths = [];
      await for (final message in receivePort) {
        if (message is List<String>) {
          allPaths.addAll(message);
        } else if (message == 'DONE') {
          receivePort.close();
          break;
        }
      }

      final total = allPaths.length;

      // Step 2: Insert into DB batch by batch (on main isolate but async)
      int count = 0;
      for (final path in allPaths) {
        final file = File(path);
        final name = path.split(Platform.pathSeparator).last;
        final lowerPath = path.toLowerCase();

        String category = 'fotograf';
        bool isScreenshot = false;

        if (lowerPath.endsWith('.pdf')) {
          category = 'pdf';
        } else if (lowerPath.endsWith('.mp3') ||
            lowerPath.endsWith('.m4a') ||
            lowerPath.endsWith('.aac') ||
            lowerPath.endsWith('.flac') ||
            lowerPath.endsWith('.wav') ||
            lowerPath.endsWith('.ogg')) {
          category = 'ses';
        } else if (lowerPath.contains('screenshot') ||
            lowerPath.contains('ekran') ||
            lowerPath.contains('screenshots')) {
          category = 'ekran';
          isScreenshot = true;
        }

        int size = 0;
        DateTime modified = DateTime.now();
        try {
          final stat = await file.stat();
          size = stat.size;
          modified = stat.modified;
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
          thumbnailColorIndex: count % 6,
        );

        await DatabaseService.instance.insertFile(indexedFile);
        count++;

        if (onProgress != null) {
          onProgress(count, total, name);
        }

        // Yield every 20 files to keep UI responsive
        if (count % 20 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      if (onComplete != null) {
        onComplete(count);
      }

      // Kick off background OCR for first 30 images only
      _backgroundOcrFirstBatch(allPaths.take(30).toList());

    } catch (e) {
      debugPrint('Device scan error: $e');
    } finally {
      _isScanning = false;
    }
  }

  static Future<void> _collectFilesIsolate(SendPort sendPort) async {
    const validExtensions = [
      '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif',
      '.pdf',
      '.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg',
      '.doc', '.docx', '.xls', '.xlsx', '.txt',
    ];

    const scanRoots = [
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Telegram',
    ];

    final List<String> found = [];

    for (final root in scanRoots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;

      try {
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is! File) continue;
          final lower = entity.path.toLowerCase();
          if (validExtensions.any((ext) => lower.endsWith(ext))) {
            found.add(entity.path);
          }
        }
      } catch (_) {}
    }

    // Sort by path (stable, fast)
    found.sort((a, b) {
      // Screenshots and camera first
      final aScore = a.contains('DCIM') || a.contains('Camera') ? 0
          : a.contains('Screenshots') ? 1
          : a.contains('Pictures') ? 2
          : 3;
      final bScore = b.contains('DCIM') || b.contains('Camera') ? 0
          : b.contains('Screenshots') ? 1
          : b.contains('Pictures') ? 2
          : 3;
      return aScore.compareTo(bScore);
    });

    // Send in chunks of 200
    for (int i = 0; i < found.length; i += 200) {
      final end = (i + 200).clamp(0, found.length);
      sendPort.send(found.sublist(i, end));
    }

    sendPort.send('DONE');
  }

  void _backgroundOcrFirstBatch(List<String> paths) {
    Future.microtask(() async {
      for (final path in paths) {
        final lower = path.toLowerCase();
        if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
            lower.endsWith('.png') || lower.endsWith('.webp')) {
          try {
            final text = await OcrService.instance.recognizeText(path);
            if (text.isNotEmpty) {
              final id = const Uuid().v5(Uuid.NAMESPACE_URL, path);
              final existing = await DatabaseService.instance.getFileById(id);
              if (existing != null) {
                await DatabaseService.instance.updateFile(
                    existing.copyWith(ocrText: text));
              }
            }
          } catch (_) {}
        }
      }
    });
  }
}
