import '../chess/chess_board.dart';
import '../engine/chess_rules.dart';
import '../models/play_mode.dart';
import 'turbo_sound_service.dart';

TurboSoundEvent soundEventForCompletedMove({
  required ChessBoard boardAfter,
  required MoveRecord move,
}) {
  if (ChessRules.isCheckmate(boardAfter, boardAfter.turn)) {
    return TurboSoundEvent.checkmate;
  }
  if (ChessRules.isKingInCheck(boardAfter, boardAfter.turn)) {
    return TurboSoundEvent.check;
  }
  if (moveRecordWasCapture(move)) {
    return TurboSoundEvent.capture;
  }
  return TurboSoundEvent.move;
}

bool moveRecordWasCapture(MoveRecord move) {
  if (move.moveSan.contains('x')) return true;
  if (move.move.length < 4) return false;
  final before = ChessBoard.tryFromFen(move.fenBefore);
  return before?.pieces[move.move.substring(2, 4)] != null;
}
