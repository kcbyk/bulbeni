import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../data/models/indexed_file.dart';
import '../../../providers/library_provider.dart';

void showFileDetailSheet(BuildContext context, IndexedFile file) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final color = AppColors.getThumbnailColor(file.thumbnailColorIndex);

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF141417) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    isScrollControlled: true,
    builder: (context) {
      final fileExists = File(file.path).existsSync();

      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333338) : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Preview Box - Tapping it also opens the file
                GestureDetector(
                  onTap: () {
                    context.read<LibraryProvider>().openFile(file.path);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: fileExists && (file.category == 'fotograf' || file.category == 'ekran')
                        ? Image.file(
                            File(file.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 54,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              file.category == 'pdf'
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.insert_drive_file_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Category
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${file.categoryDisplay} · ${FileSizeFormatter.format(file.size)} · ${DateFormatter.formatFull(file.createdAt)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons Row: Open, Share, Delete
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<LibraryProvider>().openFile(file.path);
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Dosyayı Aç'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C2C30) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        color: isDark ? Colors.white : Colors.black,
                        onPressed: () {
                          context.read<LibraryProvider>().shareFile(file.path, file.name);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C2C30) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.redAccent,
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.read<LibraryProvider>().deleteFile(file.id);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // OCR Text Section
                if (file.ocrText.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OKUNAN METİN (OCR)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: file.ocrText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Metin panoya kopyalandı!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 14, color: isDark ? Colors.white70 : Colors.black87),
                            const SizedBox(width: 4),
                            Text(
                              'Kopyala',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF28282C) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      file.ocrText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // File Path info
                Text(
                  'DOSYA YOLU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  file.path,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
