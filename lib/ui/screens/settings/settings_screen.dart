import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../widgets/squircle_icon.dart';
import '../storage/storage_analysis_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeSelector(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161619) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('Sistem'),
                trailing: settingsProvider.themeMode == ThemeMode.system ? const Icon(Icons.check) : null,
                onTap: () {
                  settingsProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Koyu'),
                trailing: settingsProvider.themeMode == ThemeMode.dark ? const Icon(Icons.check) : null,
                onTap: () {
                  settingsProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Açık'),
                trailing: settingsProvider.themeMode == ThemeMode.light ? const Icon(Icons.check) : null,
                onTap: () {
                  settingsProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteLocalIndex(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yerel Dizini Sil?'),
          content: const Text('Tüm OCR ve indeks verileri kalıcı olarak silinecektir. Cihazınızdaki orijinal dosyalar etkilenmez.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<SettingsProvider>().clearLocalIndex();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm indeks başarıyla temizlendi.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
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
    final settingsProvider = context.watch<SettingsProvider>();

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
              // Header
              Text(
                'AYARLAR',
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
                'Gizlilik sende.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131316) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Text(
                  'Yalnızca seçtiğin görseller indekslenir. WhatsApp veya diğer uygulama verileri taranmaz; hiçbir şey cihazından çıkmaz.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFFB0B0B8) : const Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Setting 1: Dizinlemeyi duraklat
              _buildSettingTile(
                context: context,
                icon: Icons.add,
                title: 'Dizinlemeyi duraklat',
                subtitle: 'Yeni dosyalar işlenmez',
                trailing: Switch.adaptive(
                  value: settingsProvider.pauseIndexing,
                  activeColor: isDark ? Colors.white : Colors.black,
                  onChanged: (val) {
                    settingsProvider.setPauseIndexing(val);
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Setting 2: Yeni ekran görüntülerini ekle
              _buildSettingTile(
                context: context,
                icon: Icons.refresh_rounded,
                title: 'Yeni ekran görüntülerini ekle',
                subtitle: 'İzin verdiğin albümlerden',
                trailing: Switch.adaptive(
                  value: settingsProvider.autoAddScreenshots,
                  activeColor: isDark ? Colors.white : Colors.black,
                  onChanged: (val) {
                    settingsProvider.setAutoAddScreenshots(val);
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Setting 3: Depolama & Analysis
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StorageAnalysisScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context: context,
                        icon: Icons.download_rounded,
                        title: 'Depolama',
                        subtitle: 'Dizin boyutu ${settingsProvider.formattedStorage}',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? const Color(0xFF6B6B72) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Storage mini progress bar
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(
                                height: 4,
                                width: double.infinity,
                                color: isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.22,
                                child: Container(
                                  height: 4,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Setting 4: Tema
              InkWell(
                onTap: () => _showThemeSelector(context),
                borderRadius: BorderRadius.circular(16),
                child: _buildSettingTile(
                  context: context,
                  icon: Icons.light_mode_outlined,
                  title: 'Tema',
                  subtitle: 'Sistem · Koyu · Açık',
                  trailing: Text(
                    settingsProvider.themeModeDisplay,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Setting 5: Dizini dışa aktar
              InkWell(
                onTap: () async {
                  await settingsProvider.exportIndex();
                },
                borderRadius: BorderRadius.circular(16),
                child: _buildSettingTile(
                  context: context,
                  icon: Icons.upload_outlined,
                  title: 'Dizini dışa aktar',
                  subtitle: 'JSON dosyası olarak kaydet',
                  trailing: const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 18),

              // Setting 6: Yerel dizini sil
              InkWell(
                onTap: () => _confirmDeleteLocalIndex(context),
                borderRadius: BorderRadius.circular(16),
                child: _buildSettingTile(
                  context: context,
                  icon: Icons.delete_outline_rounded,
                  title: 'Yerel dizini sil',
                  subtitle: 'Tüm OCR verilerini kalıcı olarak siler',
                  trailing: const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SquircleIcon(
          icon: icon,
          size: 46,
          iconSize: 22,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
