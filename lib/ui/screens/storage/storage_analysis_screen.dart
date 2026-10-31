import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../data/models/indexed_file.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/storage_analysis_service.dart';
import '../library/file_detail_sheet.dart';

class StorageAnalysisScreen extends StatefulWidget {
  const StorageAnalysisScreen({super.key});

  @override
  State<StorageAnalysisScreen> createState() => _StorageAnalysisScreenState();
}

class _StorageAnalysisScreenState extends State<StorageAnalysisScreen> {
  StorageAnalysisData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final res = await StorageAnalysisService.instance.analyzeStorage();
    setState(() {
      _data = res;
      _isLoading = false;
    });
  }

  void _confirmDeleteFile(IndexedFile file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Dosyayı Kaldır?'),
          content: Text('${file.name} indeks ve depolama listesinden silinecek. Emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseService.instance.deleteFile(file.id);
                _loadAnalysis();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Depolama Analizi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141417) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanılan Alan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              FileSizeFormatter.format(_data?.totalUsedBytes ?? 0),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/ 128 GB',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Multi-color breakdown bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 8,
                            child: Row(
                              children: (_data?.categoryBreakdown ?? []).map((cat) {
                                final flex = (cat.percentage * 10).round().clamp(1, 100);
                                final color = AppColors.getThumbnailColor(cat.categoryName.hashCode);
                                return Expanded(
                                  flex: flex,
                                  child: Container(color: color),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown List
                  Text(
                    'KATEGORİLERE GÖRE DAĞILIM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_data?.categoryBreakdown ?? []).map((cat) {
                    final color = AppColors.getThumbnailColor(cat.categoryName.hashCode);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.categoryName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${cat.fileCount} dosya · ${FileSizeFormatter.format(cat.totalBytes)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 28),

                  // Largest Files Section
                  Text(
                    'EN BÜYÜK DOSYALAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_data?.largestFiles ?? []).map((file) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => showFileDetailSheet(context, file),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.getThumbnailColor(file.thumbnailColorIndex),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 22),
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${file.categoryDisplay} · ${FileSizeFormatter.format(file.size)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteFile(file),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
