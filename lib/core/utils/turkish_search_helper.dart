class TurkishSearchHelper {
  /// Converts string to lowercase respecting Turkish characters
  static String toTurkishLower(String text) {
    return text
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
  }

  /// Converts string to uppercase respecting Turkish characters
  static String toTurkishUpper(String text) {
    return text
        .replaceAll('ı', 'I')
        .replaceAll('i', 'İ')
        .toUpperCase();
  }

  /// Normalizes Turkish diacritics to basic Latin characters for relaxed matching
  /// e.g. "Fotoğraf" -> "fotograf", "Şarap" -> "sarap", "Çiçek" -> "cicek"
  static String normalize(String text) {
    String lower = toTurkishLower(text);
    return lower
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  /// Checks if [source] contains [query] using relaxed Turkish matching
  static bool containsMatch(String source, String query) {
    if (query.trim().isEmpty) return true;
    final normalizedSource = normalize(source);
    final normalizedQuery = normalize(query.trim());
    return normalizedSource.contains(normalizedQuery);
  }

  /// Finds match ranges (start, end) of query in source text for highlighting
  static List<MatchRange> findMatches(String source, String query) {
    final List<MatchRange> matches = [];
    if (query.trim().isEmpty || source.isEmpty) return matches;

    final normSource = normalize(source);
    final normQuery = normalize(query.trim());

    int startIndex = 0;
    while (startIndex < normSource.length) {
      final found = normSource.indexOf(normQuery, startIndex);
      if (found == -1) break;
      final end = found + normQuery.length;
      matches.add(MatchRange(start: found, end: end));
      startIndex = end;
    }

    return matches;
  }

  /// Extracts an excerpt around the match with the query highlighted
  static String extractExcerpt(String fullText, String query, {int maxLength = 100}) {
    if (fullText.isEmpty) return '';
    if (query.trim().isEmpty) {
      return fullText.length <= maxLength ? fullText : '${fullText.substring(0, maxLength)}...';
    }

    final normSource = normalize(fullText);
    final normQuery = normalize(query.trim());
    final index = normSource.indexOf(normQuery);

    if (index == -1) {
      return fullText.length <= maxLength ? fullText : '${fullText.substring(0, maxLength)}...';
    }

    int start = (index - 25).clamp(0, fullText.length);
    int end = (index + normQuery.length + 50).clamp(0, fullText.length);

    String prefix = start > 0 ? '...' : '';
    String suffix = end < fullText.length ? '...' : '';

    return '$prefix${fullText.substring(start, end).trim()}$suffix';
  }

  /// Calculates a relevance score for ordering search results
  static int calculateRelevance({
    required String title,
    required String ocrText,
    required String query,
    required String category,
  }) {
    if (query.trim().isEmpty) return 0;
    final normQuery = normalize(query.trim());
    final normTitle = normalize(title);

    int score = 0;

    // Exact title match gets highest score
    if (normTitle == normQuery) {
      score += 200;
    } else if (normTitle.startsWith(normQuery)) {
      score += 120;
    } else if (normTitle.contains(normQuery)) {
      score += 80;
    }

    // Occurrences in OCR text
    final ocrMatches = findMatches(ocrText, query);
    score += (ocrMatches.length * 15).clamp(0, 100);

    return score;
  }
}

class MatchRange {
  final int start;
  final int end;
  const MatchRange({required this.start, required this.end});
}
