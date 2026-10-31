import 'indexed_file.dart';

class SearchResult {
  final IndexedFile file;
  final String matchedExcerpt;
  final int relevanceScore;
  final String matchedField; // 'name', 'ocr'

  SearchResult({
    required this.file,
    required this.matchedExcerpt,
    required this.relevanceScore,
    required this.matchedField,
  });
}
