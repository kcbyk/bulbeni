import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/search_provider.dart';
import '../../widgets/filter_chips_bar.dart';
import '../../widgets/highlighted_text.dart';
import '../library/file_detail_sheet.dart';
import '../viewer/full_screen_photo_viewer.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _controller;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(key: 'tum', label: 'Tümü'),
    FilterChipItem(key: 'ekran', label: 'Ekran'),
    FilterChipItem(key: 'fotograf', label: 'Fotoğraf'),
    FilterChipItem(key: 'pdf', label: 'PDF'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSortMenu(BuildContext context) {
    final searchProvider = context.read<SearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161619) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('En alakalı'),
                  trailing: searchProvider.sortBy == 'alakali' ? const Icon(Icons.check) : null,
                  onTap: () {
                    searchProvider.setSortBy('alakali');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Tarihe göre'),
                  trailing: searchProvider.sortBy == 'tarih' ? const Icon(Icons.check) : null,
                  onTap: () {
                    searchProvider.setSortBy('tarih');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Boyuta göre'),
                  trailing: searchProvider.sortBy == 'boyut' ? const Icon(Icons.check) : null,
                  onTap: () {
                    searchProvider.setSortBy('boyut');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchProvider = context.watch<SearchProvider>();
    final results = searchProvider.searchResults;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Back button + Search Input with Clear
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.chevron_left,
                        size: 30,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131316) : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onChanged: (val) {
                          searchProvider.setQuery(val);
                        },
                        onSubmitted: (val) {
                          searchProvider.executeSearch(val);
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14.0, right: 8.0),
                            child: Icon(
                              Icons.search,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                              size: 22,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 42),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    searchProvider.clearQuery();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: FilterChipsBar(
                items: _filters,
                selectedKey: searchProvider.selectedCategory,
                onSelected: (cat) {
                  searchProvider.setCategory(cat);
                },
              ),
            ),

            // Count & Sort Dropdown Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${results.length} sonuç',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showSortMenu(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Text(
                            searchProvider.sortBy == 'alakali'
                                ? 'En alakalı'
                                : searchProvider.sortBy == 'tarih'
                                    ? 'Tarihe göre'
                                    : 'Boyuta göre',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Search Results List
            Expanded(
              child: searchProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 54,
                                color: isDark ? const Color(0xFF44444A) : const Color(0xFFD1D5DB),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sonuç bulunamadı',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Farklı bir arama terimi deneyin.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          itemCount: results.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final file = result.file;
                            final color = AppColors.getThumbnailColor(file.thumbnailColorIndex);
                            final isPhoto = file.category == 'fotograf' || file.category == 'ekran';
                            final fileExists = File(file.path).existsSync();

                            return InkWell(
                              onTap: () {
                                if (isPhoto && fileExists) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenPhotoViewer(file: file),
                                    ),
                                  );
                                } else {
                                  showFileDetailSheet(context, file);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Real Thumbnail or Fallback
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: SizedBox(
                                      width: 74,
                                      height: 74,
                                      child: isPhoto && fileExists
                                          ? Image.file(
                                              File(file.path),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                    color: color,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      size: 30,
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              color: color,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                file.category == 'pdf'
                                                    ? Icons.picture_as_pdf_outlined
                                                    : Icons.insert_drive_file_outlined,
                                                color: Colors.white.withValues(alpha: 0.9),
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Details & Excerpt
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${file.categoryDisplay} · ${DateFormatter.formatRelative(file.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        HighlightedText(
                                          text: result.matchedExcerpt,
                                          query: searchProvider.query,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Chevron
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 22,
                                      color: isDark ? const Color(0xFF55555C) : const Color(0xFFB0B0B8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
