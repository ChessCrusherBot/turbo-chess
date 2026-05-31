import '../../../core/chess/chess_board.dart';
import '../../../core/models/play_mode.dart';

class PlayComputerGameRecord {
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final PieceColor userColor;
  final PieceColor engineColor;
  final String result;
  final String resultText;
  final String resultReason;
  final String? winner;
  final String timeControlLabel;
  final bool noTimeControl;
  final String engineProfileName;
  final int engineDepth;
  final int engineSkill;
  final int engineMoveTimeMs;
  final String startingFen;
  final String finalFen;
  final int moveCount;
  final List<MoveRecord> moves;

  const PlayComputerGameRecord({
    this.schemaVersion = currentSchemaVersion,
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.userColor,
    required this.engineColor,
    required this.result,
    required this.resultText,
    required this.resultReason,
    required this.winner,
    required this.timeControlLabel,
    required this.noTimeControl,
    required this.engineProfileName,
    required this.engineDepth,
    required this.engineSkill,
    required this.engineMoveTimeMs,
    required this.startingFen,
    required this.finalFen,
    required this.moveCount,
    required this.moves,
  });

  bool get isDraw => winner == null;

  bool get userWon =>
      winner == (userColor == PieceColor.white ? 'White' : 'Black');

  String get userColorLabel =>
      userColor == PieceColor.white ? 'White' : 'Black';

  String get engineColorLabel =>
      engineColor == PieceColor.white ? 'White' : 'Black';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schemaVersion': schemaVersion,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'userColor': userColor.name,
      'engineColor': engineColor.name,
      'result': result,
      'resultText': resultText,
      'resultReason': resultReason,
      'winner': winner,
      'timeControlLabel': timeControlLabel,
      'noTimeControl': noTimeControl,
      'engineProfileName': engineProfileName,
      'engineDepth': engineDepth,
      'engineSkill': engineSkill,
      'engineMoveTimeMs': engineMoveTimeMs,
      'startingFen': startingFen,
      'finalFen': finalFen,
      'moveCount': moveCount,
      'moves': moves.map((move) => move.toMap()).toList(),
    };
  }

  factory PlayComputerGameRecord.fromJson(Map<String, dynamic> json) {
    final movesRaw = json['moves'];
    final parsedMoves = <MoveRecord>[];
    if (movesRaw is List) {
      for (final item in movesRaw) {
        if (item is Map) {
          parsedMoves.add(MoveRecord.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return PlayComputerGameRecord(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      id: json['id']?.toString() ?? '',
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userColor: _colorFromJson(json['userColor']?.toString()),
      engineColor: _colorFromJson(
        json['engineColor']?.toString(),
        fallback: PieceColor.black,
      ),
      result: json['result']?.toString() ?? 'draw',
      resultText: json['resultText']?.toString() ?? 'Game over.',
      resultReason: json['resultReason']?.toString() ?? 'Game over',
      winner: json['winner']?.toString(),
      timeControlLabel:
          json['timeControlLabel']?.toString() ?? 'No Time Control',
      noTimeControl: json['noTimeControl'] == true,
      engineProfileName: json['engineProfileName']?.toString() ?? 'Engine',
      engineDepth: (json['engineDepth'] as num?)?.toInt() ?? 0,
      engineSkill: (json['engineSkill'] as num?)?.toInt() ?? 0,
      engineMoveTimeMs: (json['engineMoveTimeMs'] as num?)?.toInt() ?? 0,
      startingFen: json['startingFen']?.toString() ?? '',
      finalFen: json['finalFen']?.toString() ?? '',
      moveCount: (json['moveCount'] as num?)?.toInt() ?? parsedMoves.length,
      moves: parsedMoves,
    );
  }

  static String resultCodeFor(GameEndResult result, PieceColor userColor) {
    final reason = result.reason.toLowerCase();
    if (result.winner == null) {
      if (reason.contains('stalemate')) return 'stalemate';
      return 'draw';
    }
    final userWon =
        result.winner == (userColor == PieceColor.white ? 'White' : 'Black');
    if (reason.contains('timeout')) {
      return userWon ? 'user_timeout_win' : 'timeout';
    }
    if (reason.contains('resignation')) return userWon ? 'user_win' : 'resign';
    if (reason.contains('checkmate')) {
      return userWon ? 'user_checkmate_win' : 'engine_checkmate_win';
    }
    return userWon ? 'user_win' : 'engine_win';
  }

  static PieceColor _colorFromJson(
    String? raw, {
    PieceColor fallback = PieceColor.white,
  }) {
    switch (raw?.toLowerCase()) {
      case 'black':
        return PieceColor.black;
      case 'white':
        return PieceColor.white;
      default:
        return fallback;
    }
  }
}
