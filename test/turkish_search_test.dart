import 'package:flutter_test/flutter_test.dart';
import 'package:bulbeni/core/utils/turkish_search_helper.dart';

void main() {
  group('TurkishSearchHelper Tests', () {
    test('Turkish character normalization works accurately', () {
      expect(TurkishSearchHelper.normalize('Şarap'), equals('sarap'));
      expect(TurkishSearchHelper.normalize('Restoran Menüsü'), equals('restoran menusu'));
      expect(TurkishSearchHelper.normalize('Fotoğraf'), equals('fotograf'));
      expect(TurkishSearchHelper.normalize('Çiçek İnceleme'), equals('cicek inceleme'));
      expect(TurkishSearchHelper.normalize('IŞIK'), equals('isik'));
    });

    test('Contains match with relaxed Turkish diacritics', () {
      expect(
        TurkishSearchHelper.containsMatch(
          'Somerville Steakhouse restoran menüsü, şarap listesi',
          'restoran',
        ),
        isTrue,
      );

      // Typing without Turkish diacritic 'sarap' matches 'şarap'
      expect(
        TurkishSearchHelper.containsMatch(
          'Somerville Steakhouse restoran menüsü, şarap listesi',
          'sarap',
        ),
        isTrue,
      );

      // Typing with uppercase 'ŞARAP' matches
      expect(
        TurkishSearchHelper.containsMatch(
          'Somerville Steakhouse restoran menüsü, şarap listesi',
          'ŞARAP',
        ),
        isTrue,
      );

      // Typing 'menu' matches 'menüsü'
      expect(
        TurkishSearchHelper.containsMatch(
          'Somerville Steakhouse restoran menüsü, şarap listesi',
          'menu',
        ),
        isTrue,
      );
    });

    test('Excerpt extraction highlights search context', () {
      const fullText = 'Somerville Steakhouse Somerville\'de akşam restoran menüsü, şarap listesi, kuver 50 TL';
      final excerpt = TurkishSearchHelper.extractExcerpt(fullText, 'restoran');
      expect(excerpt.toLowerCase().contains('restoran'), isTrue);
    });

    test('Relevance calculation ranks exact title higher than body match', () {
      final titleMatchScore = TurkishSearchHelper.calculateRelevance(
        title: 'Restoran',
        ocrText: 'Burada bir şey yok',
        query: 'restoran',
        category: 'ekran',
      );

      final bodyMatchScore = TurkishSearchHelper.calculateRelevance(
        title: 'Başka Bir Belge',
        ocrText: 'Burada restoran geçiyor',
        query: 'restoran',
        category: 'ekran',
      );

      expect(titleMatchScore, greaterThan(bodyMatchScore));
    });
  });
}
