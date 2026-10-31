import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../widgets/squircle_icon.dart';
import '../settings/privacy_dialog.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back & Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      context.read<AppProvider>().completeOnboarding();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28282C) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3E3E44) : const Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3E3E44) : const Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 44), // balance
                ],
              ),
              const SizedBox(height: 28),

              // Shield Squircle Icon
              const SquircleIcon(
                icon: Icons.verified_user_outlined,
                size: 64,
                iconSize: 32,
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Hatırladığını\nsaniyeler içinde bul.',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Subtitle
              Text(
                'BulBeni, ekran görüntülerindeki ve fotoğraflardaki yazıları cihazında okur ve aranabilir hâle getirir.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 32),

              const Divider(color: Color(0xFF222226), height: 1),
              const SizedBox(height: 24),

              // Feature 1
              _buildFeatureItem(
                icon: Icons.lock_outline,
                title: 'Tamamen cihaz içinde',
                subtitle: 'Hesap, sunucu veya bulut yok. Hiçbir şey yüklenmez.',
                isDark: isDark,
              ),
              const SizedBox(height: 22),

              // Feature 2
              _buildFeatureItem(
                icon: Icons.photo_size_select_actual_outlined,
                title: 'Yalnızca seçtiklerin',
                subtitle: 'Android\'in fotoğraf seçicisiyle istediklerini ekle.',
                isDark: isDark,
              ),
              const SizedBox(height: 22),

              // Feature 3
              _buildFeatureItem(
                icon: Icons.security_outlined,
                title: 'İzin, gerektiğinde',
                subtitle: 'Fotoğraf erişimini ancak içe aktarırken isteriz.',
                isDark: isDark,
              ),

              const Spacer(),

              // CTA Button: > Başla
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AppProvider>().completeOnboarding();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_right, size: 22),
                      SizedBox(width: 4),
                      Text(
                        'Başla',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy text link
              Center(
                child: TextButton(
                  onPressed: () {
                    showPrivacyDialog(context);
                  },
                  child: Text(
                    'Gizlilik ayrıntılarını gör',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SquircleIcon(
          icon: icon,
          size: 44,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
