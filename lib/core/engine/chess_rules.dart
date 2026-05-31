import '../chess/chess_board.dart';

class ChessRules {
  static List<String> getLegalMoves(ChessBoard board, String square) {
    final piece = board.pieces[square];
    if (piece == null) return [];
    if (piece.color != board.turn) return [];

    final pseudoLegal = _getPseudoLegalMoves(board, square);
    final legal = <String>[];

    for (final target in pseudoLegal) {
      final newBoard = _applyMove(board, square, target);
      if (newBoard != null && !isKingInCheck(newBoard, piece.color)) {
        legal.add(target);
      }
    }
    return legal;
  }

  static List<String> getAllLegalMovesForColor(
      ChessBoard board, PieceColor color) {
    final result = <String>[];
    final normalizedBoard = board.copyWith(turn: color);
    for (final entry in normalizedBoard.pieces.entries) {
      if (entry.value.color == color) {
        result.addAll(getLegalMoves(normalizedBoard, entry.key));
      }
    }
    return result;
  }

  static List<String> getLegalMoveUcis(ChessBoard board) {
    final result = <String>[];
    final entries = board.pieces.entries
        .where((entry) => entry.value.color == board.turn)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      final targets = getLegalMoves(board, entry.key)..sort();
      for (final target in targets) {
        if (_isPromotionMove(entry.value, target)) {
          for (final suffix in const ['q', 'r', 'b', 'n']) {
            result.add('${entry.key}$target$suffix');
          }
        } else {
          result.add('${entry.key}$target');
        }
      }
    }

    return result;
  }

  static ChessBoard? applyUciMove(ChessBoard board, String uci) {
    if (uci.length < 4) return null;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promotion = uci.length > 4 ? uci[4].toLowerCase() : null;
    return applyMove(board, from, to, promotion: promotion);
  }

  static bool isKingInCheck(ChessBoard board, PieceColor color) {
    final kingSquare = findKingSquare(board, color);
    if (kingSquare == null) return false;
    return _isSquareAttackedBy(board, kingSquare, _opposite(color));
  }

  static bool isCheckmate(ChessBoard board, PieceColor color) {
    if (!isKingInCheck(board, color)) return false;
    return _hasNoLegalMoves(board, color);
  }

  static bool isStalemate(ChessBoard board, PieceColor color) {
    if (isKingInCheck(board, color)) return false;
    return _hasNoLegalMoves(board, color);
  }

  static bool isInsufficientMaterial(ChessBoard board) {
    final whites = <PieceType>[];
    final blacks = <PieceType>[];
    for (final piece in board.pieces.values) {
      if (piece.color == PieceColor.white) {
        whites.add(piece.type);
      } else {
        blacks.add(piece.type);
      }
    }

    if (whites.length == 1 && blacks.length == 1) return true;
    if (whites.length == 1 && blacks.length == 2) {
      if (blacks.contains(PieceType.bishop) ||
          blacks.contains(PieceType.knight)) {
        return true;
      }
    }
    if (blacks.length == 1 && whites.length == 2) {
      if (whites.contains(PieceType.bishop) ||
          whites.contains(PieceType.knight)) {
        return true;
      }
    }
    if (whites.length == 2 &&
        blacks.length == 2 &&
        whites.contains(PieceType.bishop) &&
        blacks.contains(PieceType.bishop)) {
      return true;
    }
    return false;
  }

  static ChessBoard? applyMove(
    ChessBoard board,
    String from,
    String to, {
    String? promotion,
  }) {
    final piece = board.pieces[from];
    if (piece == null || piece.color != board.turn) return null;
    if (!getLegalMoves(board, from).contains(to)) return null;
    final normalizedPromotion = promotion?.toLowerCase();
    if (normalizedPromotion != null &&
        !const ['q', 'r', 'b', 'n'].contains(normalizedPromotion)) {
      return null;
    }
    return _applyMove(board, from, to, promotion: normalizedPromotion);
  }

  static String? findKingSquare(ChessBoard board, PieceColor color) {
    for (final entry in board.pieces.entries) {
      if (entry.value.type == PieceType.king && entry.value.color == color) {
        return entry.key;
      }
    }
    return null;
  }

  static bool _hasNoLegalMoves(ChessBoard board, PieceColor color) {
    final normalizedBoard = board.copyWith(turn: color);
    for (final entry in normalizedBoard.pieces.entries) {
      if (entry.value.color == color &&
          getLegalMoves(normalizedBoard, entry.key).isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  static PieceColor _opposite(PieceColor color) =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;

  static bool _isPromotionMove(ChessPiece piece, String target) {
    if (piece.type != PieceType.pawn) return false;
    final targetRank = int.tryParse(target[1]) ?? 0;
    return (piece.color == PieceColor.white && targetRank == 8) ||
        (piece.color == PieceColor.black && targetRank == 1);
  }

  static List<String> _getPseudoLegalMoves(ChessBoard board, String square) {
    final piece = board.pieces[square];
    if (piece == null) return [];
    final (file, rank) = _parseSquare(square);
    switch (piece.type) {
      case PieceType.pawn:
        return _pawnMoves(board, file, rank, piece.color);
      case PieceType.knight:
        return _knightMoves(board, file, rank, piece.color);
      case PieceType.bishop:
        return _slidingMoves(board, file, rank, piece.color, _bishopDirs);
      case PieceType.rook:
        return _slidingMoves(board, file, rank, piece.color, _rookDirs);
      case PieceType.queen:
        return _slidingMoves(board, file, rank, piece.color, _queenDirs);
      case PieceType.king:
        return _kingMoves(board, file, rank, piece.color);
    }
  }

  static List<String> _getAttackSquares(ChessBoard board, String square) {
    final piece = board.pieces[square];
    if (piece == null) return [];
    final (file, rank) = _parseSquare(square);
    switch (piece.type) {
      case PieceType.pawn:
        return _pawnAttackSquares(file, rank, piece.color);
      case PieceType.knight:
        return _knightMoves(board, file, rank, piece.color);
      case PieceType.bishop:
        return _slidingMoves(board, file, rank, piece.color, _bishopDirs);
      case PieceType.rook:
        return _slidingMoves(board, file, rank, piece.color, _rookDirs);
      case PieceType.queen:
        return _slidingMoves(board, file, rank, piece.color, _queenDirs);
      case PieceType.king:
        return _kingAttackSquares(board, file, rank, piece.color);
    }
  }

  static const List<(int, int)> _bishopDirs = [
    (-1, -1),
    (-1, 1),
    (1, -1),
    (1, 1),
  ];
  static const List<(int, int)> _rookDirs = [
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
  ];
  static const List<(int, int)> _queenDirs = [
    (-1, -1),
    (-1, 1),
    (1, -1),
    (1, 1),
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
  ];

  static List<String> _pawnMoves(
      ChessBoard board, int file, int rank, PieceColor color) {
    final moves = <String>[];
    final direction = color == PieceColor.white ? 1 : -1;
    final startRank = color == PieceColor.white ? 2 : 7;

    final oneAhead = rank + direction;
    if (_inBounds(file, oneAhead)) {
      final square = _toSquare(file, oneAhead);
      if (!board.pieces.containsKey(square)) {
        moves.add(square);
        if (rank == startRank) {
          final twoAhead = rank + (2 * direction);
          if (_inBounds(file, twoAhead)) {
            final jumpSquare = _toSquare(file, twoAhead);
            if (!board.pieces.containsKey(jumpSquare)) {
              moves.add(jumpSquare);
            }
          }
        }
      }
    }

    for (final deltaFile in const [-1, 1]) {
      final nextFile = file + deltaFile;
      final nextRank = rank + direction;
      if (!_inBounds(nextFile, nextRank)) continue;
      final targetSquare = _toSquare(nextFile, nextRank);
      final targetPiece = board.pieces[targetSquare];
      if (targetPiece != null && targetPiece.color != color) {
        moves.add(targetSquare);
      }
      final enPassantRank = color == PieceColor.white ? 5 : 4;
      if (rank == enPassantRank && board.enPassantTarget == targetSquare) {
        moves.add(targetSquare);
      }
    }
    return moves;
  }

  static List<String> _pawnAttackSquares(int file, int rank, PieceColor color) {
    final attacks = <String>[];
    final direction = color == PieceColor.white ? 1 : -1;
    for (final deltaFile in const [-1, 1]) {
      final nextFile = file + deltaFile;
      final nextRank = rank + direction;
      if (_inBounds(nextFile, nextRank)) {
        attacks.add(_toSquare(nextFile, nextRank));
      }
    }
    return attacks;
  }

  static List<String> _knightMoves(
      ChessBoard board, int file, int rank, PieceColor color) {
    final moves = <String>[];
    const offsets = [
      (-2, -1),
      (-2, 1),
      (-1, -2),
      (-1, 2),
      (1, -2),
      (1, 2),
      (2, -1),
      (2, 1),
    ];
    for (final (deltaFile, deltaRank) in offsets) {
      final nextFile = file + deltaFile;
      final nextRank = rank + deltaRank;
      if (!_inBounds(nextFile, nextRank)) continue;
      final square = _toSquare(nextFile, nextRank);
      final target = board.pieces[square];
      if (target == null || target.color != color) {
        moves.add(square);
      }
    }
    return moves;
  }

  static List<String> _slidingMoves(
    ChessBoard board,
    int file,
    int rank,
    PieceColor color,
    List<(int, int)> directions,
  ) {
    final moves = <String>[];
    for (final (deltaFile, deltaRank) in directions) {
      var nextFile = file + deltaFile;
      var nextRank = rank + deltaRank;
      while (_inBounds(nextFile, nextRank)) {
        final square = _toSquare(nextFile, nextRank);
        final target = board.pieces[square];
        if (target == null) {
          moves.add(square);
        } else {
          if (target.color != color) {
            moves.add(square);
          }
          break;
        }
        nextFile += deltaFile;
        nextRank += deltaRank;
      }
    }
    return moves;
  }

  static List<String> _kingMoves(
      ChessBoard board, int file, int rank, PieceColor color) {
    final moves = _kingAttackSquares(board, file, rank, color);
    final backRank = color == PieceColor.white ? 1 : 8;
    final opponent = _opposite(color);

    if (rank == backRank && file == 5) {
      final kingSideCastle = color == PieceColor.white
          ? board.whiteCanCastleKingSide
          : board.blackCanCastleKingSide;
      if (kingSideCastle) {
        final fSquare = _toSquare(6, backRank);
        final gSquare = _toSquare(7, backRank);
        final kingSquare = _toSquare(5, backRank);
        if (!board.pieces.containsKey(fSquare) &&
            !board.pieces.containsKey(gSquare) &&
            !_isSquareAttackedBy(board, kingSquare, opponent) &&
            !_isSquareAttackedBy(board, fSquare, opponent) &&
            !_isSquareAttackedBy(board, gSquare, opponent)) {
          moves.add(gSquare);
        }
      }

      final queenSideCastle = color == PieceColor.white
          ? board.whiteCanCastleQueenSide
          : board.blackCanCastleQueenSide;
      if (queenSideCastle) {
        final dSquare = _toSquare(4, backRank);
        final cSquare = _toSquare(3, backRank);
        final bSquare = _toSquare(2, backRank);
        final kingSquare = _toSquare(5, backRank);
        if (!board.pieces.containsKey(dSquare) &&
            !board.pieces.containsKey(cSquare) &&
            !board.pieces.containsKey(bSquare) &&
            !_isSquareAttackedBy(board, kingSquare, opponent) &&
            !_isSquareAttackedBy(board, dSquare, opponent) &&
            !_isSquareAttackedBy(board, cSquare, opponent)) {
          moves.add(cSquare);
        }
      }
    }

    return moves;
  }

  static List<String> _kingAttackSquares(
      ChessBoard board, int file, int rank, PieceColor color) {
    final moves = <String>[];
    for (final (deltaFile, deltaRank) in _queenDirs) {
      final nextFile = file + deltaFile;
      final nextRank = rank + deltaRank;
      if (!_inBounds(nextFile, nextRank)) continue;
      final square = _toSquare(nextFile, nextRank);
      final target = board.pieces[square];
      if (target == null || target.color != color) {
        moves.add(square);
      }
    }
    return moves;
  }

  static bool _isSquareAttackedBy(
      ChessBoard board, String square, PieceColor attacker) {
    for (final entry in board.pieces.entries) {
      if (entry.value.color != attacker) continue;
      if (_getAttackSquares(board, entry.key).contains(square)) {
        return true;
      }
    }
    return false;
  }

  static ChessBoard? _applyMove(
    ChessBoard board,
    String from,
    String to, {
    String? promotion,
  }) {
    final piece = board.pieces[from];
    if (piece == null) return null;

    final newPieces = Map<String, ChessPiece>.from(board.pieces);
    final (fromFile, fromRank) = _parseSquare(from);
    final (toFile, toRank) = _parseSquare(to);

    var whiteCastleKingSide = board.whiteCanCastleKingSide;
    var whiteCastleQueenSide = board.whiteCanCastleQueenSide;
    var blackCastleKingSide = board.blackCanCastleKingSide;
    var blackCastleQueenSide = board.blackCanCastleQueenSide;
    String? newEnPassant;

    final targetPiece = newPieces[to];
    final isCapture = targetPiece != null ||
        (piece.type == PieceType.pawn && to == board.enPassantTarget);

    newPieces.remove(from);

    if (targetPiece != null) {
      if (to == 'a1') whiteCastleQueenSide = false;
      if (to == 'h1') whiteCastleKingSide = false;
      if (to == 'a8') blackCastleQueenSide = false;
      if (to == 'h8') blackCastleKingSide = false;
    }

    if (piece.type == PieceType.king) {
      final deltaFile = toFile - fromFile;
      if (deltaFile == 2) {
        final rook = newPieces.remove(_toSquare(8, fromRank));
        if (rook != null) newPieces[_toSquare(6, fromRank)] = rook;
      } else if (deltaFile == -2) {
        final rook = newPieces.remove(_toSquare(1, fromRank));
        if (rook != null) newPieces[_toSquare(4, fromRank)] = rook;
      }
      if (piece.color == PieceColor.white) {
        whiteCastleKingSide = false;
        whiteCastleQueenSide = false;
      } else {
        blackCastleKingSide = false;
        blackCastleQueenSide = false;
      }
    }

    if (piece.type == PieceType.rook) {
      if (from == 'a1') whiteCastleQueenSide = false;
      if (from == 'h1') whiteCastleKingSide = false;
      if (from == 'a8') blackCastleQueenSide = false;
      if (from == 'h8') blackCastleKingSide = false;
    }

    if (piece.type == PieceType.pawn && to == board.enPassantTarget) {
      final capturedRank =
          piece.color == PieceColor.white ? toRank - 1 : toRank + 1;
      newPieces.remove(_toSquare(toFile, capturedRank));
    }

    if (piece.type == PieceType.pawn && (toRank - fromRank).abs() == 2) {
      newEnPassant = _toSquare(fromFile, (fromRank + toRank) ~/ 2);
    }

    var movedPiece = piece;
    if (piece.type == PieceType.pawn) {
      final promotionRank = piece.color == PieceColor.white ? 8 : 1;
      if (toRank == promotionRank) {
        PieceType promotionType = PieceType.queen;
        switch (promotion) {
          case 'r':
            promotionType = PieceType.rook;
            break;
          case 'b':
            promotionType = PieceType.bishop;
            break;
          case 'n':
            promotionType = PieceType.knight;
            break;
          default:
            promotionType = PieceType.queen;
        }
        movedPiece = ChessPiece(
          type: promotionType,
          color: piece.color,
          fenChar: _promotionFenChar(promotionType, piece.color),
        );
      }
    }

    newPieces[to] = movedPiece;

    return board.copyWith(
      pieces: newPieces,
      turn: _opposite(piece.color),
      whiteCanCastleKingSide: whiteCastleKingSide,
      whiteCanCastleQueenSide: whiteCastleQueenSide,
      blackCanCastleKingSide: blackCastleKingSide,
      blackCanCastleQueenSide: blackCastleQueenSide,
      enPassantTarget: newEnPassant,
      clearEnPassantTarget: newEnPassant == null,
      halfMoveClock: piece.type == PieceType.pawn || isCapture
          ? 0
          : board.halfMoveClock + 1,
      fullMoveNumber: piece.color == PieceColor.black
          ? board.fullMoveNumber + 1
          : board.fullMoveNumber,
    );
  }

  static String _promotionFenChar(PieceType type, PieceColor color) {
    final base = switch (type) {
      PieceType.pawn => 'p',
      PieceType.knight => 'n',
      PieceType.bishop => 'b',
      PieceType.rook => 'r',
      PieceType.queen => 'q',
      PieceType.king => 'k',
    };
    return color == PieceColor.white ? base.toUpperCase() : base;
  }

  static bool _inBounds(int file, int rank) =>
      file >= 1 && file <= 8 && rank >= 1 && rank <= 8;

  static String _toSquare(int file, int rank) =>
      '${String.fromCharCode(96 + file)}$rank';

  static (int, int) _parseSquare(String square) {
    final file = square.codeUnitAt(0) - 96;
    final rank = int.tryParse(square[1]) ?? 1;
    return (file, rank);
  }
}
