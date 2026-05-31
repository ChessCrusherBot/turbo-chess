import '../chess/chess_board.dart';
import '../models/play_mode.dart';

class PositionCompletionRules {
  const PositionCompletionRules._();

  static bool isUserCheckmateWin({
    required GameEndResult result,
    required PieceColor userColor,
  }) {
    if (result.reason != 'Checkmate') return false;
    final userWinner = userColor == PieceColor.white ? 'White' : 'Black';
    return result.winner == userWinner;
  }
}
