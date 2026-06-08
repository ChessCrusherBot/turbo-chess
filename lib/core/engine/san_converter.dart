import '../chess/chess_board.dart';
import '../engine/chess_rules.dart';

class SanConverter {
  static String uciToSan(String uci, ChessBoard board) {
    if (uci.length < 4) return uci;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final prom = uci.length > 4 ? uci[4] : null;
    final piece = board.pieces[from];
    if (piece == null) return uci.substring(2, 4);

    if (piece.type == PieceType.king) {
      final fromFile = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final toFile = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
      if ((toFile - fromFile).abs() == 2) {
        return _withCheckSuffix(
            toFile > fromFile ? 'O-O' : 'O-O-O', board, uci);
      }
    }

    if (piece.type == PieceType.pawn) {
      final isCapture = from[0] != to[0];
      final base = isCapture ? '${from[0]}x$to' : to;
      if (prom != null) {
        return _withCheckSuffix('$base=${prom.toUpperCase()}', board, uci);
      }
      return _withCheckSuffix(base, board, uci);
    }

    final pieceChar = _pieceChar(piece.type);
    final isCapture = board.pieces.containsKey(to);
    final disambig = _getDisambig(board, from, to, piece);
    return _withCheckSuffix(
      '$pieceChar$disambig${isCapture ? 'x' : ''}$to',
      board,
      uci,
    );
  }

  static String _withCheckSuffix(String san, ChessBoard board, String uci) {
    final after = ChessRules.applyUciMove(board, uci);
    if (after == null) return san;
    final checkedColor = after.turn;
    if (ChessRules.isCheckmate(after, checkedColor)) return '$san#';
    if (ChessRules.isKingInCheck(after, checkedColor)) return '$san+';
    return san;
  }

  static String _getDisambig(
      ChessBoard board, String from, String to, ChessPiece piece) {
    final sameType = board.pieces.entries
        .where((e) =>
            e.key != from &&
            e.value.type == piece.type &&
            e.value.color == piece.color)
        .toList();
    if (sameType.isEmpty) return '';

    final canReachTo = sameType.where((e) {
      final legal = ChessRules.getLegalMoves(board, e.key);
      return legal.contains(to);
    }).toList();
    if (canReachTo.isEmpty) return '';

    final sameFile = canReachTo.any((e) => e.key[0] == from[0]);
    final sameRank = canReachTo.any((e) => e.key[1] == from[1]);
    if (sameFile && sameRank) return from;
    if (sameFile) return from[1];
    return from[0];
  }

  static String _pieceChar(PieceType type) {
    switch (type) {
      case PieceType.knight:
        return 'N';
      case PieceType.bishop:
        return 'B';
      case PieceType.rook:
        return 'R';
      case PieceType.queen:
        return 'Q';
      case PieceType.king:
        return 'K';
      default:
        return '';
    }
  }
}
