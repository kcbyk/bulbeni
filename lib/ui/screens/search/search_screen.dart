import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/search_provider.dart';
import '../../widgets/indexing_progress_card.dart';
import '../../widgets/filter_chips_bar.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<FilterChipItem> _categoryFilters = const [
    FilterChipItem(key: 'tum', label: 'Tümü'),
    FilterChipItem(key: 'fotograf', label: 'Fotoğraflar'),
    FilterChipItem(key: 'ekran', label: 'Ekran görüntüleri'),
    FilterChipItem(key: 'pdf', label: 'PDF\'ler'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    context.read<SearchProvider>().executeSearch(query.trim());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(initialQuery: query.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchProvider = context.watch<SearchProvider>();
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Category Header
              Text(
                'BULBENİ · AKILLI ARAMA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                'Ne arıyorsun?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // Permission Request Banner (if permission not yet granted)
              if (!appProvider.hasPermission)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1B20) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.electricBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.electricBlue, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cihaz Dosyalarına Erişim İzni',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cihazdaki fotoğrafları ve belgeleri aramak için izin verin.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await appProvider.requestStoragePermissions();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text('İzin Ver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Search Input Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131316) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearchSubmitted,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Örneğin: Geçen hafta kaydettiğim restoran...',
                    hintStyle: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                      child: Icon(
                        Icons.search,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Filter Chips
              FilterChipsBar(
                items: _categoryFilters,
                selectedKey: searchProvider.selectedCategory,
                onSelected: (cat) {
                  searchProvider.setCategory(cat);
                },
              ),
              const SizedBox(height: 24),

              // Indexing Progress Card
              IndexingProgressCard(
                indexedCount: appProvider.indexedCount,
                progressPercent: appProvider.progress,
                remainingCount: appProvider.remainingCount,
                isIndexing: appProvider.isIndexing,
                onTap: () {
                  appProvider.scanDevice();
                },
              ),
              const SizedBox(height: 32),

              // "SON ARAMALAR" Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SON ARAMALAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                  if (searchProvider.recentSearches.isNotEmpty)
                    InkWell(
                      onTap: () {
                        searchProvider.clearSearchHistory();
                      },
                      child: Text(
                        'Temizle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Searches List (Dynamic, real user searches)
              if (searchProvider.recentSearches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Arama geçmişi henüz boş.\nYaptığınız aramalar burada listelenecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF6B6B70) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                )
              else
                ...searchProvider.recentSearches.map((item) {
                  return Dismissible(
                    key: Key('search_${item.query}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      searchProvider.deleteRecentSearch(item.query);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                    child: InkWell(
                      onTap: () {
                        _searchController.text = item.query;
                        _onSearchSubmitted(item.query);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 22,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.query,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: isDark ? const Color(0xFF55555C) : const Color(0xFFB0B0B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
