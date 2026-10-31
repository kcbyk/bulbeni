import '../models/indexed_file.dart';
import 'database_service.dart';

class CategoryStorageInfo {
  final String categoryName;
  final String categoryKey;
  final int totalBytes;
  final int fileCount;
  final double percentage;

  CategoryStorageInfo({
    required this.categoryName,
    required this.categoryKey,
    required this.totalBytes,
    required this.fileCount,
    required this.percentage,
  });
}

class StorageAnalysisData {
  final int totalUsedBytes;
  final int estimatedTotalDeviceBytes;
  final int freeDeviceBytes;
  final List<CategoryStorageInfo> categoryBreakdown;
  final List<IndexedFile> largestFiles;
  final List<IndexedFile> potentialDuplicates;

  StorageAnalysisData({
    required this.totalUsedBytes,
    required this.estimatedTotalDeviceBytes,
    required this.freeDeviceBytes,
    required this.categoryBreakdown,
    required this.largestFiles,
    required this.potentialDuplicates,
  });
}

class StorageAnalysisService {
  static final StorageAnalysisService instance = StorageAnalysisService._internal();
  StorageAnalysisService._internal();

  Future<StorageAnalysisData> analyzeStorage() async {
    final allFiles = await DatabaseService.instance.getAllFiles();

    int totalUsed = 0;
    final Map<String, int> categoryBytes = {
      'ekran': 0,
      'fotograf': 0,
      'pdf': 0,
      'ses': 0,
      'belge': 0,
      'diger': 0,
    };
    final Map<String, int> categoryCounts = {
      'ekran': 0,
      'fotograf': 0,
      'pdf': 0,
      'ses': 0,
      'belge': 0,
      'diger': 0,
    };

    for (var f in allFiles) {
      totalUsed += f.size;
      final cat = categoryBytes.containsKey(f.category) ? f.category : 'diger';
      categoryBytes[cat] = (categoryBytes[cat] ?? 0) + f.size;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final List<CategoryStorageInfo> breakdown = [];
    final safeTotal = totalUsed > 0 ? totalUsed : 1;

    categoryBytes.forEach((key, bytes) {
      String name;
      switch (key) {
        case 'ekran':
          name = 'Ekran Görüntüleri';
          break;
        case 'fotograf':
          name = 'Fotoğraflar';
          break;
        case 'pdf':
          name = 'PDF Belgeleri';
          break;
        case 'ses':
          name = 'Müzik ve Ses';
          break;
        case 'belge':
          name = 'Belgeler';
          break;
        default:
          name = 'Diğer Dosyalar';
      }

      breakdown.add(CategoryStorageInfo(
        categoryName: name,
        categoryKey: key,
        totalBytes: bytes,
        fileCount: categoryCounts[key] ?? 0,
        percentage: (bytes / safeTotal) * 100,
      ));
    });

    // Sort largest files
    final sortedByBytes = List<IndexedFile>.from(allFiles)
      ..sort((a, b) => b.size.compareTo(a.size));
    final largestFiles = sortedByBytes.take(5).toList();

    // Find duplicates (matching name or size)
    final Map<String, IndexedFile> seen = {};
    final List<IndexedFile> duplicates = [];
    for (var f in allFiles) {
      final key = '${f.name}_${f.size}';
      if (seen.containsKey(key)) {
        duplicates.add(f);
      } else {
        seen[key] = f;
      }
    }

    // Default 128 GB phone storage baseline
    const totalDevice = 128 * 1024 * 1024 * 1024;
    final freeSpace = (totalDevice - (totalUsed * 10)).clamp(0, totalDevice);

    return StorageAnalysisData(
      totalUsedBytes: totalUsed,
      estimatedTotalDeviceBytes: totalDevice,
      freeDeviceBytes: freeSpace,
      categoryBreakdown: breakdown,
      largestFiles: largestFiles,
      potentialDuplicates: duplicates,
    );
  }
}
