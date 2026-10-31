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
        path TEXT NOT NULL UNIQUE,
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
    String sortBy = 'alakali',
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
      final ocrMatches = file.ocrText.isNotEmpty && TurkishSearchHelper.containsMatch(file.ocrText, trimmedQuery);
      final pathMatches = TurkishSearchHelper.containsMatch(file.path, trimmedQuery);

      if (nameMatches || ocrMatches || pathMatches) {
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
}
