// Core models for Turbo Chess — Offline First

export 'move_classification.dart';
export 'play_mode.dart';

class ChessDrill {
  final String id;
  final String fen;
  final String sideToMove;
  final String task;
  final String bestMove;
  final String bestMoveUci;
  final List<String> alternativeMoves;
  final String hint;
  final String explanation;
  final String conceptTag;
  final int difficulty;

  const ChessDrill({
    required this.id,
    required this.fen,
    required this.sideToMove,
    required this.task,
    required this.bestMove,
    required this.bestMoveUci,
    this.alternativeMoves = const [],
    required this.hint,
    required this.explanation,
    required this.conceptTag,
    required this.difficulty,
  });

  ChessDrill copyWith({
    String? id,
    String? fen,
    String? sideToMove,
    String? task,
    String? bestMove,
    String? bestMoveUci,
    List<String>? alternativeMoves,
    String? hint,
    String? explanation,
    String? conceptTag,
    int? difficulty,
  }) {
    return ChessDrill(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      sideToMove: sideToMove ?? this.sideToMove,
      task: task ?? this.task,
      bestMove: bestMove ?? this.bestMove,
      bestMoveUci: bestMoveUci ?? this.bestMoveUci,
      alternativeMoves: alternativeMoves ?? this.alternativeMoves,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
      conceptTag: conceptTag ?? this.conceptTag,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class OpeningTopic {
  final String id;
  final String label;
  final String icon;
  final String? color;
  final List<String> subtopics;
  final Map<String, List<ChessDrill>> drillsBySubtopic;

  const OpeningTopic({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    required this.subtopics,
    this.drillsBySubtopic = const {},
  });

  int get totalDrills =>
      drillsBySubtopic.values.fold(0, (sum, list) => sum + list.length);

  List<ChessDrill> getDrillsForSubtopic(String subtopic) =>
      drillsBySubtopic[subtopic] ?? [];
}
