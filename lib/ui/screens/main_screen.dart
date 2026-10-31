import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = const [
      SearchScreen(),
      LibraryScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: appProvider.currentTabIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1F1F24) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: appProvider.currentTabIndex,
          onTap: (index) {
            appProvider.setTabIndex(index);
          },
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
          selectedItemColor: isDark ? Colors.white : Colors.black,
          unselectedItemColor: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.search, size: 24),
              ),
              label: 'Ara',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.grid_view_rounded, size: 24),
              ),
              label: 'Kitaplık',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.wb_sunny_outlined, size: 24),
              ),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
