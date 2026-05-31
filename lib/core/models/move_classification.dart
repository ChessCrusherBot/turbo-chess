import 'package:flutter/material.dart';

import '../chess/chess_board.dart';

enum MoveQuality {
  brilliant,
  best,
  excellent,
  strong,
  good,
  inaccuracy,
  mistake,
  blunder,
  missedWin,
  missedDraw,
  defensiveResource,
  criticalMove,
}

class MoveEvaluation {
  final String moveUci;
  final String moveSan;
  final int evalBefore;
  final int evalAfter;
  final int bestEval;
  final int centipawnLoss;
  final double evalLoss;
  final String bestMove;
  final String bestMoveUci;
  final MoveQuality quality;
  final String classification;
  final bool isUserMove;
  final String explanation;

  const MoveEvaluation({
    required this.moveUci,
    required this.moveSan,
    required this.evalBefore,
    required this.evalAfter,
    this.bestEval = 0,
    required this.centipawnLoss,
    this.evalLoss = 0,
    required this.bestMove,
    this.bestMoveUci = '',
    required this.quality,
    this.classification = '',
    required this.isUserMove,
    this.explanation = '',
  });

  int get evaluationSwing => evalAfter - evalBefore;

  String get classificationLabel => classification.isNotEmpty
      ? classification
      : MoveClassifier.displayName(quality);

  Map<String, dynamic> toMap() => {
        'moveUci': moveUci,
        'moveSan': moveSan,
        'evalBefore': evalBefore,
        'evalAfter': evalAfter,
        'bestEval': bestEval,
        'centipawnLoss': centipawnLoss,
        'evalLoss': evalLoss,
        'bestMove': bestMove,
        'bestMoveUci': bestMoveUci,
        'quality': quality.name,
        'classification': classificationLabel,
        'isUserMove': isUserMove,
        'explanation': explanation,
      };

  factory MoveEvaluation.fromMap(Map<String, dynamic> map) {
    final quality = MoveClassifier.fromStorageValue(
      map['quality']?.toString() ?? map['classification']?.toString(),
    );
    final centipawnLoss = (map['centipawnLoss'] as num?)?.toInt() ?? 0;
    return MoveEvaluation(
      moveUci: map['moveUci']?.toString() ?? '',
      moveSan: map['moveSan']?.toString() ?? '',
      evalBefore: (map['evalBefore'] as num?)?.toInt() ?? 0,
      evalAfter: (map['evalAfter'] as num?)?.toInt() ?? 0,
      bestEval: (map['bestEval'] as num?)?.toInt() ?? 0,
      centipawnLoss: centipawnLoss,
      evalLoss: (map['evalLoss'] as num?)?.toDouble() ?? centipawnLoss / 100.0,
      bestMove: map['bestMove']?.toString() ?? '',
      bestMoveUci: map['bestMoveUci']?.toString() ?? '',
      quality: quality ?? MoveQuality.good,
      classification: map['classification']?.toString() ?? '',
      isUserMove: map['isUserMove'] == true,
      explanation: map['explanation']?.toString() ?? '',
    );
  }
}

class MoveClassifier {
  static String classifyMove(double evalLoss, bool isSacrifice) {
    if (evalLoss <= 0.2 && isSacrifice) return 'Brilliant';
    if (evalLoss <= 0.2) return 'Best';
    if (evalLoss <= 0.5) return 'Excellent';
    if (evalLoss <= 1.0) return 'Good';
    if (evalLoss <= 2.0) return 'Inaccuracy';
    if (evalLoss <= 4.0) return 'Mistake';
    return 'Blunder';
  }

  static bool isSacrifice(ChessBoard before, ChessBoard after) {
    final mover = before.turn;
    return materialValue(after, color: mover) <
        materialValue(before, color: mover);
  }

  static int materialValue(ChessBoard board, {PieceColor? color}) {
    var total = 0;
    for (final piece in board.pieces.values) {
      if (color != null && piece.color != color) continue;
      total += _pieceValue(piece.type);
    }
    return total;
  }

  static MoveQuality classify(int centipawnLoss, bool isBestMove) {
    if (isBestMove) return MoveQuality.best;
    return qualityForClassification(
      classifyMove(centipawnLoss / 100.0, false),
    );
  }

  static MoveQuality qualityForClassification(String classification) {
    switch (_normalize(classification)) {
      case 'brilliant':
        return MoveQuality.brilliant;
      case 'best':
      case 'bestmove':
        return MoveQuality.best;
      case 'excellent':
      case 'strong':
      case 'strongmove':
        return MoveQuality.excellent;
      case 'good':
      case 'goodmove':
        return MoveQuality.good;
      case 'inaccuracy':
        return MoveQuality.inaccuracy;
      case 'mistake':
        return MoveQuality.mistake;
      case 'blunder':
        return MoveQuality.blunder;
      default:
        return MoveQuality.good;
    }
  }

  static String displayName(MoveQuality q) {
    switch (q) {
      case MoveQuality.brilliant:
        return 'Brilliant';
      case MoveQuality.best:
        return 'Best';
      case MoveQuality.excellent:
      case MoveQuality.strong:
        return 'Excellent';
      case MoveQuality.good:
        return 'Good';
      case MoveQuality.inaccuracy:
        return 'Inaccuracy';
      case MoveQuality.mistake:
        return 'Mistake';
      case MoveQuality.blunder:
        return 'Blunder';
      case MoveQuality.missedWin:
        return 'Missed Win';
      case MoveQuality.missedDraw:
        return 'Missed Draw';
      case MoveQuality.defensiveResource:
        return 'Defensive Resource';
      case MoveQuality.criticalMove:
        return 'Critical Move';
    }
  }

  static MoveQuality? fromStorageValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = _normalize(raw);
    for (final quality in MoveQuality.values) {
      if (_normalize(quality.name) == normalized) {
        return quality;
      }
    }

    switch (normalized) {
      case 'brilliant':
        return MoveQuality.brilliant;
      case 'best':
      case 'bestmove':
        return MoveQuality.best;
      case 'excellent':
      case 'strong':
      case 'strongmove':
        return MoveQuality.excellent;
      case 'good':
      case 'goodmove':
        return MoveQuality.good;
      case 'inaccuracy':
        return MoveQuality.inaccuracy;
      case 'mistake':
        return MoveQuality.mistake;
      case 'blunder':
        return MoveQuality.blunder;
      case 'missedwin':
        return MoveQuality.missedWin;
      case 'misseddraw':
        return MoveQuality.missedDraw;
      case 'defensiveresource':
        return MoveQuality.defensiveResource;
      case 'criticalmove':
        return MoveQuality.criticalMove;
      default:
        return null;
    }
  }

  static String glyph(MoveQuality q) {
    switch (q) {
      case MoveQuality.brilliant:
        return '!!';
      case MoveQuality.best:
        return '*';
      case MoveQuality.excellent:
      case MoveQuality.strong:
        return '!';
      case MoveQuality.good:
        return '+';
      case MoveQuality.inaccuracy:
        return '?!';
      case MoveQuality.mistake:
        return '?';
      case MoveQuality.blunder:
        return '??';
      case MoveQuality.missedWin:
        return 'W';
      case MoveQuality.missedDraw:
        return 'D';
      case MoveQuality.defensiveResource:
        return 'R';
      case MoveQuality.criticalMove:
        return 'C';
    }
  }

  static String emoji(MoveQuality q) => glyph(q);

  static Color colorFor(MoveQuality q) {
    switch (q) {
      case MoveQuality.brilliant:
        return const Color(0xFF00E5C0);
      case MoveQuality.best:
        return Colors.green;
      case MoveQuality.excellent:
      case MoveQuality.strong:
        return Colors.lightGreen;
      case MoveQuality.good:
        return Colors.greenAccent;
      case MoveQuality.inaccuracy:
        return Colors.yellow;
      case MoveQuality.mistake:
        return Colors.orange;
      case MoveQuality.blunder:
        return Colors.red;
      case MoveQuality.missedWin:
        return const Color(0xFFEAB308);
      case MoveQuality.missedDraw:
        return const Color(0xFF38BDF8);
      case MoveQuality.defensiveResource:
        return const Color(0xFF14B8A6);
      case MoveQuality.criticalMove:
        return const Color(0xFFA78BFA);
    }
  }

  static double calculateAccuracy(List<MoveEvaluation> evals) {
    if (evals.isEmpty) return 100.0;
    final userEvals = evals.where((e) => e.isUserMove).toList();
    if (userEvals.isEmpty) return 100.0;
    final avgLoss = userEvals
            .map((e) => e.evalLoss > 0 ? e.evalLoss * 100 : e.centipawnLoss)
            .reduce((a, b) => a + b) /
        userEvals.length;
    return (100.0 - (avgLoss / 10.0)).clamp(0.0, 100.0);
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  static int _pieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 0;
    }
  }
}
