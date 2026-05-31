import '../chess/chess_board.dart';
import '../models/move_classification.dart';
import '../engine/san_converter.dart';

/// Play mode models for user vs engine from any drill position.
class MoveRecord {
  final String move; // UCI format, e.g. "e2e4"
  final String fenBefore; // FEN before this move was played
  final String fenAfter; // FEN after this move was played
  final bool isUser; // True if the user played this move
  final int moveNumber; // Full move number from the board before the move
  final PieceColor sideToMoveBefore;
  final PieceColor sideToMoveAfter;
  final String moveSan;
  final String bestMove;
  final String bestMoveUci;
  final int? evalBefore;
  final int? evalAfter;
  final int? bestEval;
  final int? centipawnLoss;
  final double? evalLoss;
  final MoveQuality? quality;
  final String classification;
  final String explanation;

  const MoveRecord({
    required this.move,
    required this.fenBefore,
    required this.isUser,
    this.fenAfter = '',
    this.moveNumber = 0,
    this.sideToMoveBefore = PieceColor.white,
    this.sideToMoveAfter = PieceColor.black,
    this.moveSan = '',
    this.bestMove = '',
    this.bestMoveUci = '',
    this.evalBefore,
    this.evalAfter,
    this.bestEval,
    this.centipawnLoss,
    this.evalLoss,
    this.quality,
    this.classification = '',
    this.explanation = '',
  });

  MoveRecord copyWith({
    String? move,
    String? fenBefore,
    String? fenAfter,
    bool? isUser,
    int? moveNumber,
    PieceColor? sideToMoveBefore,
    PieceColor? sideToMoveAfter,
    String? moveSan,
    String? bestMove,
    String? bestMoveUci,
    int? evalBefore,
    bool clearEvalBefore = false,
    int? evalAfter,
    bool clearEvalAfter = false,
    int? bestEval,
    bool clearBestEval = false,
    int? centipawnLoss,
    bool clearCentipawnLoss = false,
    double? evalLoss,
    bool clearEvalLoss = false,
    MoveQuality? quality,
    bool clearQuality = false,
    String? classification,
    String? explanation,
  }) {
    return MoveRecord(
      move: move ?? this.move,
      fenBefore: fenBefore ?? this.fenBefore,
      fenAfter: fenAfter ?? this.fenAfter,
      isUser: isUser ?? this.isUser,
      moveNumber: moveNumber ?? this.moveNumber,
      sideToMoveBefore: sideToMoveBefore ?? this.sideToMoveBefore,
      sideToMoveAfter: sideToMoveAfter ?? this.sideToMoveAfter,
      moveSan: moveSan ?? this.moveSan,
      bestMove: bestMove ?? this.bestMove,
      bestMoveUci: bestMoveUci ?? this.bestMoveUci,
      evalBefore: clearEvalBefore ? null : evalBefore ?? this.evalBefore,
      evalAfter: clearEvalAfter ? null : evalAfter ?? this.evalAfter,
      bestEval: clearBestEval ? null : bestEval ?? this.bestEval,
      centipawnLoss:
          clearCentipawnLoss ? null : centipawnLoss ?? this.centipawnLoss,
      evalLoss: clearEvalLoss ? null : evalLoss ?? this.evalLoss,
      quality: clearQuality ? null : quality ?? this.quality,
      classification: classification ?? this.classification,
      explanation: explanation ?? this.explanation,
    );
  }

  bool get hasAnalysis =>
      quality != null && evalBefore != null && evalAfter != null;

  /// Returns a display string like "1. e4" or "1... e5".
  String toDisplayString(int fallbackMoveNumber) {
    final notation = moveSan.isNotEmpty
        ? moveSan
        : move.length >= 4
            ? _safeSan(move, fenBefore)
            : move;
    final displayedMoveNumber =
        moveNumber > 0 ? moveNumber : fallbackMoveNumber;
    if (isUser) return '$displayedMoveNumber. $notation';
    return '$displayedMoveNumber... $notation';
  }

  MoveRecord withEvaluation(MoveEvaluation evaluation) {
    return copyWith(
      moveSan: evaluation.moveSan,
      bestMove: evaluation.bestMove,
      bestMoveUci: evaluation.bestMoveUci,
      evalBefore: evaluation.evalBefore,
      evalAfter: evaluation.evalAfter,
      bestEval: evaluation.bestEval,
      centipawnLoss: evaluation.centipawnLoss,
      evalLoss: evaluation.evalLoss,
      quality: evaluation.quality,
      classification: evaluation.classificationLabel,
      explanation: evaluation.explanation,
    );
  }

  MoveEvaluation? toEvaluation() {
    if (!hasAnalysis) return null;
    return MoveEvaluation(
      moveUci: move,
      moveSan: moveSan.isNotEmpty ? moveSan : _safeSan(move, fenBefore),
      evalBefore: evalBefore ?? 0,
      evalAfter: evalAfter ?? 0,
      bestEval: bestEval ?? 0,
      centipawnLoss: centipawnLoss ?? 0,
      evalLoss: evalLoss ?? ((centipawnLoss ?? 0) / 100.0),
      bestMove: bestMove,
      bestMoveUci: bestMoveUci,
      quality: quality ?? MoveQuality.good,
      classification: classification,
      isUserMove: isUser,
      explanation: explanation,
    );
  }

  Map<String, dynamic> toMap() => {
        'move': move,
        'fenBefore': fenBefore,
        'fenAfter': fenAfter,
        'isUser': isUser,
        'moveNumber': moveNumber,
        'sideToMoveBefore': sideToMoveBefore.name,
        'sideToMoveAfter': sideToMoveAfter.name,
        'moveSan': moveSan,
        'bestMove': bestMove,
        'bestMoveUci': bestMoveUci,
        'evalBefore': evalBefore,
        'evalAfter': evalAfter,
        'bestEval': bestEval,
        'centipawnLoss': centipawnLoss,
        'evalLoss': evalLoss,
        'classification': classification.isNotEmpty
            ? classification
            : quality == null
                ? null
                : MoveClassifier.displayName(quality!),
        'classificationLabel':
            quality == null ? null : MoveClassifier.displayName(quality!),
        'explanation': explanation,
      };

  factory MoveRecord.fromMap(Map<String, dynamic> map) {
    final quality = MoveClassifier.fromStorageValue(
      map['classification']?.toString() ??
          map['classificationLabel']?.toString() ??
          map['quality']?.toString(),
    );
    return MoveRecord(
      move: map['move']?.toString() ?? '',
      fenBefore: map['fenBefore']?.toString() ?? '',
      fenAfter: map['fenAfter']?.toString() ?? '',
      isUser: map['isUser'] == true,
      moveNumber: (map['moveNumber'] as num?)?.toInt() ?? 0,
      sideToMoveBefore: _colorFromStorage(
        map['sideToMoveBefore']?.toString(),
        fallback: PieceColor.white,
      ),
      sideToMoveAfter: _colorFromStorage(
        map['sideToMoveAfter']?.toString(),
        fallback: PieceColor.black,
      ),
      moveSan: map['moveSan']?.toString() ?? '',
      bestMove: map['bestMove']?.toString() ?? '',
      bestMoveUci: map['bestMoveUci']?.toString() ?? '',
      evalBefore: (map['evalBefore'] as num?)?.toInt(),
      evalAfter: (map['evalAfter'] as num?)?.toInt(),
      bestEval: (map['bestEval'] as num?)?.toInt(),
      centipawnLoss: (map['centipawnLoss'] as num?)?.toInt(),
      evalLoss: (map['evalLoss'] as num?)?.toDouble(),
      quality: quality,
      classification: map['classificationLabel']?.toString() ??
          map['classification']?.toString() ??
          '',
      explanation: map['explanation']?.toString() ?? '',
    );
  }

  static PieceColor _colorFromStorage(
    String? raw, {
    required PieceColor fallback,
  }) {
    if (raw == null) return fallback;
    switch (raw.toLowerCase()) {
      case 'white':
        return PieceColor.white;
      case 'black':
        return PieceColor.black;
      default:
        return fallback;
    }
  }

  static String _safeSan(String move, String fenBefore) {
    final board = ChessBoard.tryFromFen(fenBefore);
    if (board == null) return move;
    return SanConverter.uciToSan(move, board);
  }
}

class GameEndResult {
  final String reason; // "Checkmate", "Stalemate", "Resignation", etc.
  final String? winner; // "White", "Black", or null for draw
  final String message; // Human-readable result description

  const GameEndResult({
    required this.reason,
    required this.winner,
    required this.message,
  });

  bool get isDraw => winner == null;
}
