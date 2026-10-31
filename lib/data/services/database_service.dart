import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/indexed_file.dart';
import '../models/search_history_item.dart';
import '../models/search_result.dart';
import '../../core/utils/turkish_search_helper.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // If running on desktop, initialize sqflite_common_ffi
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDirectory.path, 'bulbeni_index.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE indexed_files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        category TEXT NOT NULL,
        size INTEGER NOT NULL,
        ocrText TEXT,
        isScreenshot INTEGER DEFAULT 0,
        indexedAt TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        thumbnailColorIndex INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        timestamp TEXT NOT NULL
      )
    ''');

    // Populate initial rich demo data to match the UI screenshots out of the box
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // Initial search history matching the screenshots
    final initialSearches = [
      'restoran adresi',
      'IBAN',
      'wifi şifresi',
    ];

    for (var query in initialSearches) {
      await db.insert('search_history', {
        'query': query,
        'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
      });
    }

    // Initial indexed documents and screenshots matching the screenshots exactly
    final initialFiles = [
      IndexedFile(
        id: 'seed-1',
        name: 'Restoran menüsü',
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Restoran_Menusu.png',
        category: 'ekran',
        size: 2450000,
        ocrText: 'Somerville Steakhouse Somerville\'de akşam restoran menüsü, şarap listesi, antrikot 420 TL, kuver 50 TL, tatlılar ve içecekler menüsü',
        isScreenshot: true,
        indexedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        thumbnailColorIndex: 0, // Red
      ),
      IndexedFile(
        id: 'seed-2',
        name: 'Restoran adresi',
        path: '/storage/emulated/0/DCIM/Camera/IMG_Restoran_Adres.jpg',
        category: 'fotograf',
        size: 3820000,
        ocrText: 'High Street 14 · Restoran rezervasyon: Cuma 20:00 masa no 7, otopark mevcut, vale hizmeti vardır',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        thumbnailColorIndex: 1, // Steel Slate
      ),
      IndexedFile(
        id: 'seed-3',
        name: 'Rezervasyon onayı',
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Rezervasyon.png',
        category: 'ekran',
        size: 1980000,
        ocrText: 'Masa 4 kişilik, restoran onay kodu BK-2291, saat 19:30 Kadıköy şubesi, rezervasyon teyit edildi',
        isScreenshot: true,
        indexedAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        thumbnailColorIndex: 2, // Taupe
      ),
      IndexedFile(
        id: 'seed-4',
        name: 'Fiş',
        path: '/storage/emulated/0/DCIM/Camera/IMG_Restoran_Fis.jpg',
        category: 'fotograf',
        size: 2150000,
        ocrText: 'Restoran hesabı toplam 842,50 TL KDV dahil, Nakit ödeme, Teşekkür ederiz tekrar bekleriz',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 14)),
        thumbnailColorIndex: 4, // Dark Khaki
      ),
      IndexedFile(
        id: 'seed-5',
        name: 'Ev İnterneti Wifi Şifresi',
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Wifi.png',
        category: 'ekran',
        size: 1420000,
        ocrText: 'Modem Kablonet_5G Wifi şifresi: SuperGucluSifre2026! IP: 192.168.1.1 admin arayüzü',
        isScreenshot: true,
        indexedAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 14)),
        thumbnailColorIndex: 3,
      ),
      IndexedFile(
        id: 'seed-6',
        name: 'Kira Sözleşmesi & IBAN',
        path: '/storage/emulated/0/Documents/Kira_IBAN_Bilgisi.pdf',
        category: 'pdf',
        size: 5120000,
        ocrText: 'Ev sahibi IBAN: TR33 0006 1005 1982 0012 3456 78 Alıcı: Ahmet Yılmaz Kira Bedeli her ayın 15\'inde ödenecektir',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 21)),
        createdAt: now.subtract(const Duration(days: 21)),
        thumbnailColorIndex: 1,
      ),
      IndexedFile(
        id: 'seed-7',
        name: 'Araç Bakım Faturası',
        path: '/storage/emulated/0/DCIM/Camera/IMG_Arac_Bakim.jpg',
        category: 'fotograf',
        size: 4300000,
        ocrText: 'Yetkili Servis Periyodik bakım, motor yağı değişimi, filtreler, fren balataları kontrolü yapıldı toplam 4.800 TL',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 30)),
        createdAt: now.subtract(const Duration(days: 30)),
        thumbnailColorIndex: 0,
      ),
      IndexedFile(
        id: 'seed-8',
        name: 'Pasaport ve Vize Çıktısı',
        path: '/storage/emulated/0/Documents/Vize_Basvuru_Formu.pdf',
        category: 'pdf',
        size: 3200000,
        ocrText: 'Schengen Vize Başvuru Formu, Giriş Tarihi: 15.06.2026, Çok girişli, Seyahat Sigortası eklenmiştir',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 35)),
        createdAt: now.subtract(const Duration(days: 35)),
        thumbnailColorIndex: 5,
      ),
      IndexedFile(
        id: 'seed-9',
        name: 'E-Devlet İkametgah Belgesi',
        path: '/storage/emulated/0/Documents/Ikametgah_Belgesi.pdf',
        category: 'pdf',
        size: 1100000,
        ocrText: 'Türkiye Cumhuriyeti Nüfus ve Vatandaşlık İşleri Yerleşim Yeri ve Diğer Adres Belgesi Barkod No: 88492019',
        isScreenshot: false,
        indexedAt: now.subtract(const Duration(days: 60)),
        createdAt: now.subtract(const Duration(days: 60)),
        thumbnailColorIndex: 3,
      ),
    ];

    for (var file in initialFiles) {
      await db.insert('indexed_files', file.toMap());
    }
  }

  // --- Indexed Files Operations ---

  Future<void> insertFile(IndexedFile file) async {
    final db = await database;
    await db.insert(
      'indexed_files',
      file.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFile(IndexedFile file) async {
    final db = await database;
    await db.update(
      'indexed_files',
      file.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }

  Future<void> deleteFile(String id) async {
    final db = await database;
    await db.delete(
      'indexed_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<IndexedFile?> getFileById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'indexed_files',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return IndexedFile.fromMap(maps.first);
    }
    return null;
  }

  Future<List<IndexedFile>> getAllFiles({String? categoryFilter, String? sortBy}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'tum') {
      whereClause = 'category = ?';
      whereArgs = [categoryFilter];
    }

    String orderBy = 'createdAt DESC';
    if (sortBy == 'tarih_asc') {
      orderBy = 'createdAt ASC';
    } else if (sortBy == 'boyut') {
      orderBy = 'size DESC';
    } else if (sortBy == 'ad') {
      orderBy = 'name ASC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'indexed_files',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) => IndexedFile.fromMap(maps[i]));
  }

  Future<List<SearchResult>> searchFiles({
    required String query,
    String? categoryFilter,
    String sortBy = 'alakali', // 'alakali', 'tarih', 'boyut'
  }) async {
    final files = await getAllFiles(categoryFilter: categoryFilter);
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return files.map((f) => SearchResult(
        file: f,
        matchedExcerpt: f.ocrText.isNotEmpty 
            ? TurkishSearchHelper.extractExcerpt(f.ocrText, '')
            : f.name,
        relevanceScore: 0,
        matchedField: 'name',
      )).toList();
    }

    final List<SearchResult> results = [];

    for (final file in files) {
      final nameMatches = TurkishSearchHelper.containsMatch(file.name, trimmedQuery);
      final ocrMatches = TurkishSearchHelper.containsMatch(file.ocrText, trimmedQuery);

      if (nameMatches || ocrMatches) {
        final score = TurkishSearchHelper.calculateRelevance(
          title: file.name,
          ocrText: file.ocrText,
          query: trimmedQuery,
          category: file.category,
        );

        String excerpt;
        String field;

        if (ocrMatches && file.ocrText.isNotEmpty) {
          excerpt = TurkishSearchHelper.extractExcerpt(file.ocrText, trimmedQuery);
          field = 'ocr';
        } else {
          excerpt = file.name;
          field = 'name';
        }

        results.add(SearchResult(
          file: file,
          matchedExcerpt: excerpt,
          relevanceScore: score,
          matchedField: field,
        ));
      }
    }

    // Sort results
    if (sortBy == 'alakali') {
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    } else if (sortBy == 'tarih') {
      results.sort((a, b) => b.file.createdAt.compareTo(a.file.createdAt));
    } else if (sortBy == 'boyut') {
      results.sort((a, b) => b.file.size.compareTo(a.file.size));
    }

    return results;
  }

  Future<int> getIndexedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM indexed_files');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalStorageBytes() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(size) as total FROM indexed_files');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAllIndexedFiles() async {
    final db = await database;
    await db.delete('indexed_files');
  }

  // --- Search History Operations ---

  Future<List<SearchHistoryItem>> getRecentSearches({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => SearchHistoryItem.fromMap(maps[i]));
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final db = await database;
    await db.insert(
      'search_history',
      {
        'query': trimmed,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSearchQuery(String query) async {
    final db = await database;
    await db.delete(
      'search_history',
      where: 'query = ?',
      whereArgs: [query],
    );
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // --- Export / Import ---

  Future<String> exportDatabaseJson() async {
    final files = await getAllFiles();
    final list = files.map((f) => f.toMap()).toList();
    return jsonEncode({
      'app': 'BulBeni',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': list.length,
      'items': list,
    });
  }

  Future<int> importDatabaseJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final items = decoded['items'] as List<dynamic>;
      int imported = 0;
      for (var item in items) {
        final map = item as Map<String, dynamic>;
        await insertFile(IndexedFile.fromMap(map));
        imported++;
      }
      return imported;
    } catch (e) {
      debugPrint('Import error: $e');
      return 0;
    }
  }
}
