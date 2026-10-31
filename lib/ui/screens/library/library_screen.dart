import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/library_provider.dart';
import '../../widgets/filter_chips_bar.dart';
import 'file_detail_sheet.dart';
import '../viewer/full_screen_photo_viewer.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<FilterChipItem> _filters = const [
    FilterChipItem(key: 'tum', label: 'Tümü'),
    FilterChipItem(key: 'fotograf', label: 'Fotoğraf'),
    FilterChipItem(key: 'ekran', label: 'Ekran'),
    FilterChipItem(key: 'pdf', label: 'PDF'),
  ];

  void _showSortMenu(BuildContext context) {
    final libraryProvider = context.read<LibraryProvider>();
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
                  title: const Text('En yeni (Tarih)'),
                  trailing: libraryProvider.sortBy == 'tarih_desc' ? const Icon(Icons.check) : null,
                  onTap: () {
                    libraryProvider.setSortBy('tarih_desc');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('En eski (Tarih)'),
                  trailing: libraryProvider.sortBy == 'tarih_asc' ? const Icon(Icons.check) : null,
                  onTap: () {
                    libraryProvider.setSortBy('tarih_asc');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Boyuta göre'),
                  trailing: libraryProvider.sortBy == 'boyut' ? const Icon(Icons.check) : null,
                  onTap: () {
                    libraryProvider.setSortBy('boyut');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('İsme göre'),
                  trailing: libraryProvider.sortBy == 'ad' ? const Icon(Icons.check) : null,
                  onTap: () {
                    libraryProvider.setSortBy('ad');
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
    final libraryProvider = context.watch<LibraryProvider>();
    final appProvider = context.watch<AppProvider>();
    final files = libraryProvider.files;

    final numberFormat = NumberFormat('#,###', 'tr_TR');
    final formattedFileCount = numberFormat.format(files.isNotEmpty ? files.length : appProvider.indexedCount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await appProvider.scanDevice();
            await libraryProvider.loadFiles();
          },
          color: AppColors.electricBlue,
          backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header
                Text(
                  'KİTAPLIK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),

                // Big Title
                Text(
                  '$formattedFileCount dosya',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 18),

                // Permission warning if not granted
                if (!appProvider.hasPermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1B20) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.electricBlue, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cihazdaki fotoğrafların listelenmesi için erişim izni gereklidir.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => appProvider.requestStoragePermissions(),
                          child: const Text('İzin Ver'),
                        ),
                      ],
                    ),
                  ),

                // Filter Chips
                FilterChipsBar(
                  items: _filters,
                  selectedKey: libraryProvider.selectedCategory,
                  onSelected: (cat) {
                    libraryProvider.setCategory(cat);
                  },
                ),
                const SizedBox(height: 20),

                // Subtitle & Sort Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bu ay · ${files.length} dosya',
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
                              'Tarih',
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
                const SizedBox(height: 16),

                // Media Grid (3 Columns)
                if (files.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: isDark ? const Color(0xFF3E3E44) : const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cihazda dosya bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Aşağı kaydırarak cihazı yeniden tarayabilirsiniz.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final fileExists = File(file.path).existsSync();

                      return InkWell(
                        onTap: () {
                          final isPhoto = file.category == 'fotograf' || file.category == 'ekran';
                          if (isPhoto && fileExists) {
                            // Collect all visible image files for swipe navigation
                            final imageFiles = files
                                .where((f) =>
                                    f.category == 'fotograf' || f.category == 'ekran')
                                .toList();
                            final galleryIndex = imageFiles.indexWhere((f) => f.id == file.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenPhotoViewer(
                                  file: file,
                                  gallery: imageFiles,
                                  initialIndex: galleryIndex >= 0 ? galleryIndex : 0,
                                ),
                              ),
                            );
                          } else {
                            showFileDetailSheet(context, file);
                          }
                        },
                        onLongPress: () {
                          // Long press directly shares the file
                          libraryProvider.shareFile(file.path, file.name);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Actual Image or Fallback Color Squircle
                              fileExists && (file.category == 'fotograf' || file.category == 'ekran')
                                  ? Image.file(
                                      File(file.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppColors.getThumbnailColor(file.thumbnailColorIndex),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.getThumbnailColor(file.thumbnailColorIndex),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        file.category == 'pdf'
                                            ? Icons.picture_as_pdf_outlined
                                            : Icons.insert_drive_file_outlined,
                                        color: Colors.white.withValues(alpha: 0.6),
                                        size: 32,
                                      ),
                                    ),

                              // Bottom dark gradient overlay
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Duration/Date Badge at bottom-left
                              Positioned(
                                left: 7,
                                bottom: 6,
                                child: Text(
                                  DateFormatter.formatShortBadge(file.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
