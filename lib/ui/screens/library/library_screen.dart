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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<FilterChipItem> _filters = const [
    FilterChipItem(key: 'tum', label: 'Tümü'),
    FilterChipItem(key: 'ekran', label: 'Ekran'),
    FilterChipItem(key: 'fotograf', label: 'Fotoğraf'),
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

  void _confirmClearLibrary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Dizini Temizle?'),
          content: const Text('Tüm indekslenen dosyalar listeden kaldırılacaktır. Orijinal dosyalarınız silinmez.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final files = context.read<LibraryProvider>().files;
                for (var f in files) {
                  await context.read<LibraryProvider>().deleteFile(f.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Temizle'),
            ),
          ],
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
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                            'Kitaplıkta dosya bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fotoğraf ekleyerek başlayabilirsiniz.',
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
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final color = AppColors.getThumbnailColor(file.thumbnailColorIndex);
                        final fileExists = File(file.path).existsSync();

                        return InkWell(
                          onTap: () {
                            showFileDetailSheet(context, file);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Thumbnail Image or Color Squircle
                                fileExists && (file.category == 'fotograf' || file.category == 'ekran')
                                    ? Image.file(
                                        File(file.path),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: color,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          file.category == 'pdf'
                                              ? Icons.picture_as_pdf_outlined
                                              : Icons.image_outlined,
                                          color: Colors.white.withOpacity(0.35),
                                          size: 36,
                                        ),
                                      ),

                                // Subtle dark gradient overlay at bottom
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Duration/Date Badge at bottom-left ("3 gün", "5 gün", "1 hf", "2 ay", etc.)
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: Text(
                                    DateFormatter.formatShortBadge(file.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
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

                  const SizedBox(height: 100), // Space for bottom floating bar
                ],
              ),
            ),

            // Bottom Action Pill Bar matching screenshot 2:
            // "↻ Dizini yenile" (left pill) and Trash can button (right circle)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await appProvider.refreshIndex();
                        if (context.mounted) {
                          await libraryProvider.loadFiles();
                        }
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131316) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dizini yenile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _confirmClearLibrary(context),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131316) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 22,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
