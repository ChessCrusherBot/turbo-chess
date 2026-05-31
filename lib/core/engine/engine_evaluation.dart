import '../chess/chess_board.dart';

class EngineEvaluation {
  static const int mateBase = 100000;
  static const int mateThreshold = 90000;

  const EngineEvaluation._();

  static int encodeMate(int mateIn) {
    if (mateIn == 0) return mateBase;
    final distance = mateIn.abs().clamp(1, 999).toInt();
    final encoded = mateBase - distance;
    return mateIn > 0 ? encoded : -encoded;
  }

  static bool isMateScore(int centipawns) => centipawns.abs() >= mateThreshold;

  static int mateDistance(int centipawns) {
    if (!isMateScore(centipawns)) return 0;
    return (mateBase - centipawns.abs()).clamp(1, 999);
  }

  /// Converts a Stockfish/fallback side-to-move score to white-positive.
  static int toWhitePerspective(int score, PieceColor sideToMove) {
    return sideToMove == PieceColor.white ? score : -score;
  }

  static String formatWhiteScore(int? centipawns) {
    if (centipawns == null) return '0.0';
    if (isMateScore(centipawns)) {
      final sign = centipawns > 0 ? '+' : '-';
      return '${sign}M${mateDistance(centipawns)}';
    }
    final pawns = centipawns / 100.0;
    if (pawns > -0.05 && pawns < 0.05) return '0.0';
    return '${pawns > 0 ? '+' : ''}${pawns.toStringAsFixed(1)}';
  }

  /// Returns the visual share for White in a white-positive evaluation bar.
  static double whiteShare(int? centipawns) {
    if (centipawns == null) return 0.5;
    if (isMateScore(centipawns)) return centipawns > 0 ? 0.97 : 0.03;
    final clamped = centipawns.clamp(-1000, 1000).toDouble();
    return ((clamped + 1000) / 2000).clamp(0.05, 0.95).toDouble();
  }
}
