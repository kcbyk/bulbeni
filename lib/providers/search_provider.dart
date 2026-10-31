import 'package:flutter/material.dart';
import '../data/models/search_history_item.dart';
import '../data/models/search_result.dart';
import '../data/services/database_service.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';
  String _selectedCategory = 'tum'; // 'tum', 'ekran', 'fotograf', 'pdf'
  String _sortBy = 'alakali'; // 'alakali', 'tarih', 'boyut'
  List<SearchResult> _searchResults = [];
  List<SearchHistoryItem> _recentSearches = [];
  bool _isLoading = false;

  String get query => _query;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  List<SearchResult> get searchResults => _searchResults;
  List<SearchHistoryItem> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;

  SearchProvider() {
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    _recentSearches = await DatabaseService.instance.getRecentSearches();
    notifyListeners();
  }

  void setQuery(String newQuery) {
    _query = newQuery;
    if (_query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
    } else {
      executeSearch(_query);
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    if (_query.trim().isNotEmpty) {
      executeSearch(_query);
    } else {
      notifyListeners();
    }
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    if (_query.trim().isNotEmpty) {
      executeSearch(_query);
    } else {
      notifyListeners();
    }
  }

  Future<void> executeSearch(String searchQuery) async {
    _query = searchQuery;
    if (searchQuery.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Perform database search
    final filter = _selectedCategory == 'tum' ? null : _selectedCategory;
    _searchResults = await DatabaseService.instance.searchFiles(
      query: searchQuery,
      categoryFilter: filter,
      sortBy: _sortBy,
    );

    // Save to history
    await DatabaseService.instance.addSearchQuery(searchQuery);
    await loadRecentSearches();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecentSearch(String itemQuery) async {
    await DatabaseService.instance.deleteSearchQuery(itemQuery);
    await loadRecentSearches();
  }

  Future<void> clearSearchHistory() async {
    await DatabaseService.instance.clearSearchHistory();
    _recentSearches = [];
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    _searchResults = [];
    notifyListeners();
  }
}
