class IndexedFile {
  final String id;
  final String name;
  final String path;
  final String category; // 'ekran', 'fotograf', 'pdf', 'ses', 'belge', 'diger'
  final int size; // bytes
  final String ocrText;
  final bool isScreenshot;
  final DateTime indexedAt;
  final DateTime createdAt;
  final int thumbnailColorIndex;

  IndexedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.category,
    required this.size,
    required this.ocrText,
    this.isScreenshot = false,
    required this.indexedAt,
    required this.createdAt,
    this.thumbnailColorIndex = 0,
  });

  String get categoryDisplay {
    switch (category) {
      case 'ekran':
        return 'Ekran görüntüsü';
      case 'fotograf':
        return 'Fotoğraf';
      case 'pdf':
        return 'PDF';
      case 'ses':
        return 'Müzik / Ses';
      case 'belge':
        return 'Belge';
      default:
        return 'Dosya';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'category': category,
      'size': size,
      'ocrText': ocrText,
      'isScreenshot': isScreenshot ? 1 : 0,
      'indexedAt': indexedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'thumbnailColorIndex': thumbnailColorIndex,
    };
  }

  factory IndexedFile.fromMap(Map<String, dynamic> map) {
    return IndexedFile(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      category: map['category'] as String,
      size: map['size'] as int,
      ocrText: (map['ocrText'] as String?) ?? '',
      isScreenshot: (map['isScreenshot'] as int? ?? 0) == 1,
      indexedAt: DateTime.tryParse(map['indexedAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      thumbnailColorIndex: map['thumbnailColorIndex'] as int? ?? 0,
    );
  }

  IndexedFile copyWith({
    String? id,
    String? name,
    String? path,
    String? category,
    int? size,
    String? ocrText,
    bool? isScreenshot,
    DateTime? indexedAt,
    DateTime? createdAt,
    int? thumbnailColorIndex,
  }) {
    return IndexedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      category: category ?? this.category,
      size: size ?? this.size,
      ocrText: ocrText ?? this.ocrText,
      isScreenshot: isScreenshot ?? this.isScreenshot,
      indexedAt: indexedAt ?? this.indexedAt,
      createdAt: createdAt ?? this.createdAt,
      thumbnailColorIndex: thumbnailColorIndex ?? this.thumbnailColorIndex,
    );
  }
}
