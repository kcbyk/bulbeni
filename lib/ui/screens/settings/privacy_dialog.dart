import 'package:flutter/material.dart';

void showPrivacyDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF141417) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: isDark ? Colors.white : Colors.black,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  'BulBeni Gizlilik Taahhüdü',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '1. %100 Cihaz İçi Çalışma:\nTüm optik karakter tanıma (OCR) ve indeksleme işlemleri doğrudan telefonunuzun işlemcisinde (Google ML Kit ile) çalışır. Hiçbir görsel veya metin herhangi bir sunucuya yüklenmez.\n\n'
              '2. Veri Güvenliği ve İzinler:\nUygulama yalnızca sizin seçtiğiniz fotoğraflara erişir. Kişisel WhatsApp mesajlarınız, sistem dosyalarınız veya gizli albümleriniz izinsiz taranmaz.\n\n'
              '3. Çevrimdışı ve Şeffaf:\nArama ve indeksleme internet bağlantısı olmadan eksiksiz çalışır. Dilediğiniz an Ayarlar menüsünden tüm yerel veri tabanını tek tıkla silebilirsiniz.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? const Color(0xFFB0B0B8) : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text('Anladım', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
