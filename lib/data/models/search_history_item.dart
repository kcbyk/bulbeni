class SearchHistoryItem {
  final int? id;
  final String query;
  final DateTime timestamp;

  SearchHistoryItem({
    this.id,
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] as int?,
      query: map['query'] as String,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
