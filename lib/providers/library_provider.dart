import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/indexed_file.dart';
import '../data/services/database_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<IndexedFile> _files = [];
  String _selectedCategory = 'tum'; // 'tum', 'ekran', 'fotograf', 'pdf'
  String _sortBy = 'tarih_desc'; // 'tarih_desc', 'tarih_asc', 'boyut', 'ad'
  bool _isLoading = false;

  List<IndexedFile> get files => _files;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;

  LibraryProvider() {
    loadFiles();
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();

    final filter = _selectedCategory == 'tum' ? null : _selectedCategory;
    _files = await DatabaseService.instance.getAllFiles(
      categoryFilter: filter,
      sortBy: _sortBy,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadFiles();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    loadFiles();
  }

  Future<void> deleteFile(String id) async {
    await DatabaseService.instance.deleteFile(id);
    await loadFiles();
  }

  Future<void> openFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await OpenFilex.open(path);
      } else {
        debugPrint('File does not physically exist at: $path');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> shareFile(String path, String name) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(path)], text: 'BulBeni: $name');
      } else {
        await Share.share('BulBeni Dosyası: $name\nKonum: $path');
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}
