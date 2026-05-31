class ChessBookmark {
  final String id;
  final String fen;
  final String sourceType;
  final String? module;
  final int? positionIndex;
  final String title;
  final String? difficulty;
  final DateTime savedAt;

  const ChessBookmark({
    required this.id,
    required this.fen,
    required this.sourceType,
    this.module,
    this.positionIndex,
    required this.title,
    this.difficulty,
    required this.savedAt,
  });

  String get duplicateKey {
    if (positionIndex != null && module != null) {
      return '$sourceType|$module|$positionIndex|$fen';
    }
    return '$sourceType|$fen';
  }

  ChessBookmark copyWith({
    String? id,
    String? fen,
    String? sourceType,
    String? module,
    bool clearModule = false,
    int? positionIndex,
    bool clearPositionIndex = false,
    String? title,
    String? difficulty,
    bool clearDifficulty = false,
    DateTime? savedAt,
  }) {
    return ChessBookmark(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      sourceType: sourceType ?? this.sourceType,
      module: clearModule ? null : module ?? this.module,
      positionIndex:
          clearPositionIndex ? null : positionIndex ?? this.positionIndex,
      title: title ?? this.title,
      difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fen': fen,
      'sourceType': sourceType,
      'module': module,
      'positionIndex': positionIndex,
      'title': title,
      'difficulty': difficulty,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory ChessBookmark.fromJson(Map<String, dynamic> json) {
    return ChessBookmark(
      id: json['id']?.toString() ?? '',
      fen: json['fen']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'custom',
      module: json['module']?.toString(),
      positionIndex: (json['positionIndex'] as num?)?.toInt(),
      title: json['title']?.toString() ?? 'Saved position',
      difficulty: json['difficulty']?.toString(),
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
