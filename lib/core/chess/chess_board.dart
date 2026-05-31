import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_system.dart';

enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  final String fenChar;

  const ChessPiece({
    required this.type,
    required this.color,
    required this.fenChar,
  });

  static ChessPiece? fromFenChar(String char) {
    if (char.isEmpty) return null;
    final color =
        char == char.toUpperCase() ? PieceColor.white : PieceColor.black;
    switch (char.toLowerCase()) {
      case 'p':
        return ChessPiece(type: PieceType.pawn, color: color, fenChar: char);
      case 'n':
        return ChessPiece(type: PieceType.knight, color: color, fenChar: char);
      case 'b':
        return ChessPiece(type: PieceType.bishop, color: color, fenChar: char);
      case 'r':
        return ChessPiece(type: PieceType.rook, color: color, fenChar: char);
      case 'q':
        return ChessPiece(type: PieceType.queen, color: color, fenChar: char);
      case 'k':
        return ChessPiece(type: PieceType.king, color: color, fenChar: char);
      default:
        return null;
    }
  }
}

class ChessPieceAssets {
  static const String basePath = 'assets/pieces/cburnett_bsd/svg';

  const ChessPieceAssets._();

  static String assetFor(ChessPiece piece) {
    return assetForFenChar(piece.fenChar);
  }

  static String assetForFenChar(String fenChar) {
    switch (fenChar) {
      case 'K':
        return '$basePath/wK.svg';
      case 'Q':
        return '$basePath/wQ.svg';
      case 'R':
        return '$basePath/wR.svg';
      case 'B':
        return '$basePath/wB.svg';
      case 'N':
        return '$basePath/wN.svg';
      case 'P':
        return '$basePath/wP.svg';
      case 'k':
        return '$basePath/bK.svg';
      case 'q':
        return '$basePath/bQ.svg';
      case 'r':
        return '$basePath/bR.svg';
      case 'b':
        return '$basePath/bB.svg';
      case 'n':
        return '$basePath/bN.svg';
      case 'p':
        return '$basePath/bP.svg';
      default:
        throw ArgumentError.value(fenChar, 'fenChar', 'Unknown chess piece');
    }
  }

  static String semanticsLabelFor(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'White' : 'Black';
    final type = switch (piece.type) {
      PieceType.pawn => 'pawn',
      PieceType.knight => 'knight',
      PieceType.bishop => 'bishop',
      PieceType.rook => 'rook',
      PieceType.queen => 'queen',
      PieceType.king => 'king',
    };
    return '$color $type';
  }
}

class ChessBoard {
  static const String standardStartingFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  final Map<String, ChessPiece> pieces;
  final PieceColor turn;
  final bool whiteCanCastleKingSide;
  final bool whiteCanCastleQueenSide;
  final bool blackCanCastleKingSide;
  final bool blackCanCastleQueenSide;
  final String? enPassantTarget;
  final int halfMoveClock;
  final int fullMoveNumber;

  const ChessBoard({
    required this.pieces,
    this.turn = PieceColor.white,
    this.whiteCanCastleKingSide = true,
    this.whiteCanCastleQueenSide = true,
    this.blackCanCastleKingSide = true,
    this.blackCanCastleQueenSide = true,
    this.enPassantTarget,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
  });

  factory ChessBoard.fromFen(String fen) => _parseFen(fen);

  factory ChessBoard.starting() => ChessBoard.fromFen(standardStartingFen);

  static ChessBoard? tryFromFen(String fen) {
    try {
      return ChessBoard.fromFen(fen);
    } on FormatException {
      return null;
    }
  }

  static bool isValidFen(String fen) => tryFromFen(fen) != null;

  static ChessBoard _parseFen(String fen) {
    final normalized = fen.trim();
    if (normalized.isEmpty) {
      throw const FormatException('FEN is empty.');
    }

    final tokens = normalized.split(RegExp(r'\s+'));
    if (tokens.length != 6) {
      throw FormatException('FEN must contain 6 fields.', fen);
    }

    final piecePlacement = tokens[0];
    final activeColor = tokens[1];
    final castling = tokens[2];
    final enPassant = tokens[3];
    final halfMove = int.tryParse(tokens[4]);
    final fullMove = int.tryParse(tokens[5]);

    if (activeColor != 'w' && activeColor != 'b') {
      throw FormatException('FEN side to move must be w or b.', fen);
    }
    if (!_isValidCastlingField(castling)) {
      throw FormatException('FEN castling field is invalid.', fen);
    }
    if (!_isValidEnPassantField(enPassant)) {
      throw FormatException('FEN en passant field is invalid.', fen);
    }
    if (halfMove == null || halfMove < 0) {
      throw FormatException('FEN halfmove clock is invalid.', fen);
    }
    if (fullMove == null || fullMove < 1) {
      throw FormatException('FEN fullmove number is invalid.', fen);
    }

    final rows = piecePlacement.split('/');
    if (rows.length != 8) {
      throw FormatException('FEN board must contain 8 ranks.', fen);
    }

    final pieces = <String, ChessPiece>{};
    var whiteKings = 0;
    var blackKings = 0;
    for (int row = 0; row < 8; row++) {
      var file = 0;
      var previousWasDigit = false;
      for (final char in rows[row].split('')) {
        final digit = int.tryParse(char);
        if (digit != null) {
          if (digit < 1 || digit > 8 || previousWasDigit) {
            throw FormatException('FEN rank has invalid empty squares.', fen);
          }
          file += digit;
          previousWasDigit = true;
          continue;
        }

        previousWasDigit = false;
        final piece = ChessPiece.fromFenChar(char);
        if (piece == null || file > 7) {
          throw FormatException('FEN contains an invalid piece.', fen);
        }
        final square =
            '${String.fromCharCode('a'.codeUnitAt(0) + file)}${8 - row}';
        pieces[square] = piece;
        if (piece.type == PieceType.king) {
          if (piece.color == PieceColor.white) {
            whiteKings++;
          } else {
            blackKings++;
          }
        }
        file++;
      }
      if (file != 8) {
        throw FormatException('FEN rank does not contain 8 files.', fen);
      }
    }

    if (whiteKings != 1 || blackKings != 1) {
      throw FormatException(
          'FEN must contain one white and one black king.', fen);
    }
    _validateCastlingPieces(castling, pieces, fen);

    return ChessBoard(
      pieces: pieces,
      turn: activeColor == 'b' ? PieceColor.black : PieceColor.white,
      whiteCanCastleKingSide: castling.contains('K'),
      whiteCanCastleQueenSide: castling.contains('Q'),
      blackCanCastleKingSide: castling.contains('k'),
      blackCanCastleQueenSide: castling.contains('q'),
      enPassantTarget: enPassant == '-' ? null : enPassant,
      halfMoveClock: halfMove,
      fullMoveNumber: fullMove,
    );
  }

  static bool _isValidCastlingField(String castling) {
    if (castling == '-') return true;
    if (castling.isEmpty || castling.length > 4) return false;
    const order = 'KQkq';
    var lastIndex = -1;
    for (final char in castling.split('')) {
      final index = order.indexOf(char);
      if (index <= lastIndex) return false;
      lastIndex = index;
    }
    return true;
  }

  static bool _isValidEnPassantField(String enPassant) {
    if (enPassant == '-') return true;
    if (enPassant.length != 2) return false;
    final file = enPassant.codeUnitAt(0);
    final rank = enPassant[1];
    return file >= 'a'.codeUnitAt(0) &&
        file <= 'h'.codeUnitAt(0) &&
        (rank == '3' || rank == '6');
  }

  static void _validateCastlingPieces(
    String castling,
    Map<String, ChessPiece> pieces,
    String fen,
  ) {
    if (castling.contains('K')) {
      _requireCastlingPiece(
          pieces, 'e1', PieceType.king, PieceColor.white, fen);
      _requireCastlingPiece(
          pieces, 'h1', PieceType.rook, PieceColor.white, fen);
    }
    if (castling.contains('Q')) {
      _requireCastlingPiece(
          pieces, 'e1', PieceType.king, PieceColor.white, fen);
      _requireCastlingPiece(
          pieces, 'a1', PieceType.rook, PieceColor.white, fen);
    }
    if (castling.contains('k')) {
      _requireCastlingPiece(
          pieces, 'e8', PieceType.king, PieceColor.black, fen);
      _requireCastlingPiece(
          pieces, 'h8', PieceType.rook, PieceColor.black, fen);
    }
    if (castling.contains('q')) {
      _requireCastlingPiece(
          pieces, 'e8', PieceType.king, PieceColor.black, fen);
      _requireCastlingPiece(
          pieces, 'a8', PieceType.rook, PieceColor.black, fen);
    }
  }

  static void _requireCastlingPiece(
    Map<String, ChessPiece> pieces,
    String square,
    PieceType type,
    PieceColor color,
    String fen,
  ) {
    final piece = pieces[square];
    if (piece?.type != type || piece?.color != color) {
      throw FormatException('FEN castling rights do not match pieces.', fen);
    }
  }

  ChessBoard copyWith({
    Map<String, ChessPiece>? pieces,
    PieceColor? turn,
    bool? whiteCanCastleKingSide,
    bool? whiteCanCastleQueenSide,
    bool? blackCanCastleKingSide,
    bool? blackCanCastleQueenSide,
    String? enPassantTarget,
    bool clearEnPassantTarget = false,
    int? halfMoveClock,
    int? fullMoveNumber,
  }) {
    return ChessBoard(
      pieces: pieces ?? this.pieces,
      turn: turn ?? this.turn,
      whiteCanCastleKingSide:
          whiteCanCastleKingSide ?? this.whiteCanCastleKingSide,
      whiteCanCastleQueenSide:
          whiteCanCastleQueenSide ?? this.whiteCanCastleQueenSide,
      blackCanCastleKingSide:
          blackCanCastleKingSide ?? this.blackCanCastleKingSide,
      blackCanCastleQueenSide:
          blackCanCastleQueenSide ?? this.blackCanCastleQueenSide,
      enPassantTarget:
          clearEnPassantTarget ? null : enPassantTarget ?? this.enPassantTarget,
      halfMoveClock: halfMoveClock ?? this.halfMoveClock,
      fullMoveNumber: fullMoveNumber ?? this.fullMoveNumber,
    );
  }

  ChessPiece? getPiece(String square) => pieces[square];

  List<List<ChessPiece?>> to2DArray() {
    final board = List<List<ChessPiece?>>.generate(
      8,
      (_) => List<ChessPiece?>.filled(8, null),
    );
    for (final entry in pieces.entries) {
      final file = entry.key.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final rank = 8 - int.parse(entry.key[1]);
      board[rank][file] = entry.value;
    }
    return board;
  }

  String toFen() {
    final buffer = StringBuffer();
    for (int rank = 8; rank >= 1; rank--) {
      int empty = 0;
      for (int file = 0; file < 8; file++) {
        final square = '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';
        final piece = pieces[square];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          buffer.write(piece.fenChar);
        }
      }
      if (empty > 0) buffer.write(empty);
      if (rank > 1) buffer.write('/');
    }

    final castlingBuffer = StringBuffer();
    if (whiteCanCastleKingSide) castlingBuffer.write('K');
    if (whiteCanCastleQueenSide) castlingBuffer.write('Q');
    if (blackCanCastleKingSide) castlingBuffer.write('k');
    if (blackCanCastleQueenSide) castlingBuffer.write('q');
    final castlingRights =
        castlingBuffer.isEmpty ? '-' : castlingBuffer.toString();

    return '${buffer.toString()} ${turn == PieceColor.white ? 'w' : 'b'} '
        '$castlingRights ${enPassantTarget ?? '-'} $halfMoveClock $fullMoveNumber';
  }
}

class ChessMove {
  final String from;
  final String to;
  final PieceType? promotion;

  const ChessMove({required this.from, required this.to, this.promotion});

  String get notation =>
      '$from$to${promotion != null ? _promotionChar(promotion!) : ''}';

  static String _promotionChar(PieceType pieceType) {
    switch (pieceType) {
      case PieceType.knight:
        return 'n';
      case PieceType.bishop:
        return 'b';
      case PieceType.rook:
        return 'r';
      case PieceType.queen:
        return 'q';
      default:
        return '';
    }
  }
}

class ChessBoardWidget extends StatefulWidget {
  final ChessBoard board;
  final double size;
  final void Function(String square)? onTapSquare;
  final String? selectedSquare;
  final List<String>? legalMoves;
  final Color lightSquare;
  final Color darkSquare;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? suggestedMoveFrom;
  final String? suggestedMoveTo;
  final String? checkSquare;
  final bool flipped;
  final List<String>? extraHighlightedSquares;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.size = 320,
    this.onTapSquare,
    this.selectedSquare,
    this.legalMoves,
    this.lightSquare = const Color(0xFFE6D8BD),
    this.darkSquare = const Color(0xFF5E7C66),
    this.lastMoveFrom,
    this.lastMoveTo,
    this.suggestedMoveFrom,
    this.suggestedMoveTo,
    this.checkSquare,
    this.flipped = false,
    this.extraHighlightedSquares,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  static const List<String> _files = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
  ];

  String? _animatingFrom;
  String? _animatingTo;
  ChessPiece? _animatingPiece;
  late AnimationController _moveController;
  Animation<Offset>? _moveAnimation;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: DesignSystem.durationNormal,
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMoveFrom == null ||
        widget.lastMoveTo == null ||
        (widget.lastMoveFrom == oldWidget.lastMoveFrom &&
            widget.lastMoveTo == oldWidget.lastMoveTo)) {
      return;
    }

    final movingPiece = oldWidget.board.pieces[widget.lastMoveFrom!];
    if (movingPiece == null) return;

    _animatingFrom = widget.lastMoveFrom;
    _animatingTo = widget.lastMoveTo;
    _animatingPiece = movingPiece;
    _moveAnimation = Tween<Offset>(
      begin: _visualPosition(_animatingFrom!),
      end: _visualPosition(_animatingTo!),
    ).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic),
    );
    _moveController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _animatingFrom = null;
        _animatingTo = null;
        _animatingPiece = null;
        _moveAnimation = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final outerSize = constraints.biggest.shortestSide;
          final framePadding = math.max(6.0, outerSize * 0.015);
          final boardSize = outerSize - (framePadding * 2);
          final squareSize = boardSize / 8;
          final extraHighlights =
              widget.extraHighlightedSquares ?? const <String>[];
          final legalMoves = widget.legalMoves ?? const <String>[];
          final animating = _moveController.isAnimating &&
              _animatingPiece != null &&
              _moveAnimation != null;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2117),
                  Color(0xFF111414),
                ],
              ),
              border: Border.all(color: const Color(0xFF5B4930)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  offset: const Offset(0, 14),
                  blurRadius: 26,
                ),
                BoxShadow(
                  color: const Color(0xFFE5C77C).withAlpha(18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(framePadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: boardSize,
                  child: AnimatedBuilder(
                    animation: _moveController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          for (int row = 0; row < 8; row++)
                            for (int col = 0; col < 8; col++)
                              _buildSquare(
                                row: row,
                                col: col,
                                squareSize: squareSize,
                                legalMoves: legalMoves,
                                extraHighlights: extraHighlights,
                                hidePieceSquare:
                                    animating ? _animatingTo : null,
                              ),
                          IgnorePointer(
                            child: _buildBoardCoordinates(squareSize),
                          ),
                          if (animating) _buildAnimatedPiece(squareSize),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSquare({
    required int row,
    required int col,
    required double squareSize,
    required List<String> legalMoves,
    required List<String> extraHighlights,
    required String? hidePieceSquare,
  }) {
    final square = _squareForVisual(row, col);
    final piece =
        square == hidePieceSquare ? null : widget.board.pieces[square];
    final isLight = (row + col).isEven;
    final isSelected = widget.selectedSquare == square;
    final isLastMove =
        square == widget.lastMoveFrom || square == widget.lastMoveTo;
    final isSuggestedMove =
        square == widget.suggestedMoveFrom || square == widget.suggestedMoveTo;
    final isExtraHighlighted = extraHighlights.contains(square);
    final isCheck = widget.checkSquare == square;
    final isLegalMove = legalMoves.contains(square);
    final isEnPassantSquare = widget.board.enPassantTarget == square;
    final baseColor = isLight ? widget.lightSquare : widget.darkSquare;

    return Positioned(
      left: col * squareSize,
      top: row * squareSize,
      width: squareSize,
      height: squareSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTapSquare?.call(square),
        child: DecoratedBox(
          decoration: BoxDecoration(color: baseColor),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLastMove)
                Container(
                  color: const Color(0xFFFFD166).withAlpha(104),
                ),
              if (isExtraHighlighted)
                Container(
                  margin: EdgeInsets.all(squareSize * 0.05),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(squareSize * 0.08),
                    border: Border.all(
                      color: const Color(0xFFFFD166).withAlpha(210),
                      width: math.max(2, squareSize * 0.035),
                    ),
                    color: const Color(0xFFFFD166).withAlpha(42),
                  ),
                ),
              if (isSuggestedMove)
                Container(
                  margin: EdgeInsets.all(squareSize * 0.08),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(squareSize * 0.1),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withAlpha(236),
                      width: math.max(2, squareSize * 0.045),
                    ),
                    color: const Color(0xFF38BDF8).withAlpha(54),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withAlpha(62),
                        blurRadius: squareSize * 0.08,
                      ),
                    ],
                  ),
                ),
              if (isEnPassantSquare)
                Container(color: const Color(0xFF4B7EA4).withAlpha(58)),
              if (isSelected)
                Container(
                  margin: EdgeInsets.all(squareSize * 0.06),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(squareSize * 0.08),
                    border: Border.all(
                      color: const Color(0xFFFFE08A),
                      width: math.max(2, squareSize * 0.04),
                    ),
                    color: const Color(0xFFFFD66B).withAlpha(48),
                  ),
                ),
              if (isCheck)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFB83A32).withAlpha(178),
                        const Color(0x00E95353),
                      ],
                    ),
                  ),
                ),
              if (isLegalMove && piece == null)
                Container(
                  width: squareSize * 0.2,
                  height: squareSize * 0.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF172018).withAlpha(128),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withAlpha(34),
                        blurRadius: squareSize * 0.03,
                      ),
                    ],
                  ),
                ),
              if (isLegalMove && piece != null)
                Container(
                  width: squareSize * 0.78,
                  height: squareSize * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFE08A).withAlpha(220),
                      width: math.max(2, squareSize * 0.038),
                    ),
                    color: Colors.black.withAlpha(22),
                  ),
                ),
              if (piece != null)
                Transform.scale(
                  scale: isSelected ? 1.05 : 1,
                  child: _PieceWidget(
                    piece: piece,
                    fontSize: squareSize * 0.84,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPiece(double squareSize) {
    final offset = _moveAnimation!.value;
    return Positioned(
      left: offset.dx * squareSize,
      top: offset.dy * squareSize,
      width: squareSize,
      height: squareSize,
      child: IgnorePointer(
        child: Center(
          child: _PieceWidget(
            piece: _animatingPiece!,
            fontSize: squareSize * 0.84,
          ),
        ),
      ),
    );
  }

  Widget _buildBoardCoordinates(double squareSize) {
    final ranks = widget.flipped
        ? const ['1', '2', '3', '4', '5', '6', '7', '8']
        : const ['8', '7', '6', '5', '4', '3', '2', '1'];
    final files = widget.flipped ? _files.reversed.toList() : _files;

    return Stack(
      children: [
        for (int row = 0; row < 8; row++)
          Positioned(
            left: 4,
            top: row * squareSize + 3,
            child: Text(
              ranks[row],
              style: _coordinateStyle((row + 0).isEven),
            ),
          ),
        for (int col = 0; col < 8; col++)
          Positioned(
            left: col * squareSize + squareSize - 12,
            top: squareSize * 8 - 16,
            child: Text(
              files[col],
              style: _coordinateStyle((7 + col).isEven),
            ),
          ),
      ],
    );
  }

  TextStyle _coordinateStyle(bool lightSquare) {
    return TextStyle(
      color: lightSquare
          ? const Color(0xFF3A473B).withAlpha(170)
          : const Color(0xFFF4E7C9).withAlpha(218),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      height: 1,
      shadows: [
        Shadow(
          color: Colors.black.withAlpha(lightSquare ? 0 : 80),
          blurRadius: 2,
        ),
      ],
    );
  }

  String _squareForVisual(int row, int col) {
    if (!widget.flipped) {
      final fileChar = String.fromCharCode('a'.codeUnitAt(0) + col);
      final rank = 8 - row;
      return '$fileChar$rank';
    }
    final fileChar = String.fromCharCode('h'.codeUnitAt(0) - col);
    final rank = row + 1;
    return '$fileChar$rank';
  }

  Offset _visualPosition(String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(square[1]) ?? 1;
    if (!widget.flipped) {
      return Offset(file.toDouble(), (8 - rank).toDouble());
    }
    return Offset((7 - file).toDouble(), (rank - 1).toDouble());
  }
}

class _PieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double fontSize;

  const _PieceWidget({
    required this.piece,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: fontSize,
      child: RepaintBoundary(
        child: SvgPicture.asset(
          ChessPieceAssets.assetFor(piece),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          semanticsLabel: ChessPieceAssets.semanticsLabelFor(piece),
          excludeFromSemantics: false,
        ),
      ),
    );
  }
}
