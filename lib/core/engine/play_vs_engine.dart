import 'dart:async';
import '../chess/chess_board.dart';
import '../engine/chess_rules.dart';
import '../engine/engine_power_profile.dart';
import '../engine/engine_manager.dart';
import '../engine/san_converter.dart';
import '../models/play_mode.dart';

typedef EngineMoveProvider = Future<String?> Function(
  String fen,
  EnginePowerProfile profile,
  EngineSearchConfig? config,
);

enum PlayState {
  idle,
  userTurn,
  engineThinking,
  gameOver,
}

/// Manages a single drill game against the engine.
class PlayVsEngine {
  final String startingFen;
  final PieceColor userColor;
  EnginePowerProfile engineProfile;
  EngineSearchConfig? engineConfig;
  final EngineMoveProvider? engineMoveProvider;

  ChessBoard _board;
  PlayState _state = PlayState.idle;
  final List<MoveRecord> _moves = [];
  final Map<String, int> _positionHistory = {};
  GameEndResult? _result;
  bool _engineError = false;
  bool _active = true;
  bool _forceEngineMoveRequested = false;
  int _engineMoveToken = 0;
  Completer<void>? _forceEngineMoveCompleter;

  void Function(ChessBoard, PlayState)? onBoardUpdate;
  void Function(GameEndResult)? onGameOver;
  void Function(String moveUci)? onMoveMade;

  PlayVsEngine({
    required this.startingFen,
    this.userColor = PieceColor.white,
    this.engineProfile = EnginePowerProfile.strong,
    this.engineConfig,
    this.engineMoveProvider,
  }) : _board = ChessBoard.fromFen(startingFen);

  PlayVsEngine.restored({
    required this.startingFen,
    required String currentFen,
    required List<MoveRecord> moves,
    this.userColor = PieceColor.white,
    this.engineProfile = EnginePowerProfile.strong,
    this.engineConfig,
    this.engineMoveProvider,
  }) : _board = ChessBoard.fromFen(currentFen) {
    _moves.addAll(moves);
    for (final move in _moves) {
      if (move.fenBefore.isNotEmpty) _recordFen(move.fenBefore);
      if (move.fenAfter.isNotEmpty) _recordFen(move.fenAfter);
    }
    if (_positionHistory.isEmpty) _recordPosition();
    _state = _board.turn == userColor
        ? PlayState.userTurn
        : PlayState.engineThinking;
  }

  ChessBoard get board => _board;
  PlayState get state => _state;
  List<MoveRecord> get moves => List.unmodifiable(_moves);
  GameEndResult? get result => _result;
  bool get isGameOver => _state == PlayState.gameOver;
  bool get engineError => _engineError;
  String get initialFen => startingFen;

  void setEngineProfile(EnginePowerProfile profile) {
    engineProfile = profile;
  }

  void setEngineConfig(EngineSearchConfig? config) {
    engineConfig = config;
  }

  void reset() {
    if (!_active) return;
    _board = ChessBoard.fromFen(startingFen);
    _state = PlayState.idle;
    _moves.clear();
    _positionHistory.clear();
    _result = null;
    _engineError = false;
    onBoardUpdate?.call(_board, _state);
  }

  /// Start the game. If engine goes first (user is Black), triggers engine move.
  void start() {
    if (!_active) return;
    _recordPosition();
    final end = _checkGameEnd();
    if (end != null) {
      _state = PlayState.gameOver;
      _result = end;
      onBoardUpdate?.call(_board, _state);
      onGameOver?.call(end);
      return;
    }

    _state = _board.turn == userColor
        ? PlayState.userTurn
        : PlayState.engineThinking;
    onBoardUpdate?.call(_board, _state);
    if (_state == PlayState.engineThinking) {
      _engineMove();
    }
  }

  void resumeRestored() {
    if (!_active) return;
    final end = _checkGameEnd();
    if (end != null) {
      _state = PlayState.gameOver;
      _result = end;
      onBoardUpdate?.call(_board, _state);
      onGameOver?.call(end);
      return;
    }
    _state = _board.turn == userColor
        ? PlayState.userTurn
        : PlayState.engineThinking;
    onBoardUpdate?.call(_board, _state);
    if (_state == PlayState.engineThinking) {
      _engineMove();
    }
  }

  /// Called when the user taps a destination square after selecting a piece.
  /// [from] and [to] are algebraic squares like "e2", "e4".
  /// [promotion] is 'q', 'r', 'b', or 'n' if pawn promotion.
  Future<bool> userMove(String from, String to, {String? promotion}) async {
    if (!_active) return false;
    if (_state != PlayState.userTurn) return false;
    final legal = ChessRules.getLegalMoves(_board, from);
    if (!legal.contains(to)) return false;

    final uci = '$from$to${promotion ?? ''}';
    final boardBefore = _board;
    final fenBefore = boardBefore.toFen();
    final newBoard = ChessRules.applyUciMove(boardBefore, uci);
    if (newBoard == null) return false;

    _board = newBoard;
    _moves.add(
      MoveRecord(
        move: uci,
        fenBefore: fenBefore,
        fenAfter: newBoard.toFen(),
        isUser: true,
        moveNumber: boardBefore.fullMoveNumber,
        sideToMoveBefore: boardBefore.turn,
        sideToMoveAfter: newBoard.turn,
        moveSan: SanConverter.uciToSan(uci, boardBefore),
      ),
    );
    _recordPosition();
    onMoveMade?.call(uci);

    final end = _checkGameEnd();
    if (end != null) {
      _state = PlayState.gameOver;
      _result = end;
      onBoardUpdate?.call(_board, _state);
      onGameOver?.call(end);
      return true;
    }

    _state = PlayState.engineThinking;
    onBoardUpdate?.call(_board, _state);
    await _engineMove();
    return true;
  }

  Future<void> _engineMove() async {
    final token = ++_engineMoveToken;
    final forceCompleter = Completer<void>();
    _forceEngineMoveCompleter = forceCompleter;
    if (_forceEngineMoveRequested) {
      forceCompleter.complete();
    }

    try {
      final fen = _board.toFen();
      final profile = engineProfile;
      final config = engineConfig;
      final searchFuture =
          _getEngineMove(fen, profile, config).catchError((Object _) => null);
      final searchResult = await Future.any<Object?>([
        searchFuture,
        forceCompleter.future.then<Object?>(
          (_) => const _ForcedEngineMove(),
        ),
      ]);
      if (!_active || token != _engineMoveToken || isGameOver) return;

      var bestMove = searchResult is _ForcedEngineMove
          ? _fallbackLegalMove(_board)
          : searchResult as String?;

      if (bestMove == null || isGameOver) {
        final end = _checkGameEnd();
        if (end != null) {
          _state = PlayState.gameOver;
          _result = end;
          onBoardUpdate?.call(_board, _state);
          onGameOver?.call(end);
          return;
        }
        _engineError = true;
        _state = PlayState.userTurn;
        onBoardUpdate?.call(_board, _state);
        return;
      }

      final boardBefore = _board;
      final fenBefore = boardBefore.toFen();
      var newBoard = ChessRules.applyUciMove(boardBefore, bestMove);
      if (newBoard == null) {
        bestMove = _fallbackLegalMove(boardBefore);
        if (bestMove == null) {
          final end = _checkGameEnd();
          if (end != null) {
            _state = PlayState.gameOver;
            _result = end;
            onBoardUpdate?.call(_board, _state);
            onGameOver?.call(end);
            return;
          }
          _engineError = true;
          _state = PlayState.userTurn;
          onBoardUpdate?.call(_board, _state);
          return;
        }
        newBoard = ChessRules.applyUciMove(boardBefore, bestMove);
        if (newBoard == null) {
          _engineError = true;
          _state = PlayState.userTurn;
          onBoardUpdate?.call(_board, _state);
          return;
        }
      }

      _board = newBoard;
      _moves.add(
        MoveRecord(
          move: bestMove,
          fenBefore: fenBefore,
          fenAfter: newBoard.toFen(),
          isUser: false,
          moveNumber: boardBefore.fullMoveNumber,
          sideToMoveBefore: boardBefore.turn,
          sideToMoveAfter: newBoard.turn,
          moveSan: SanConverter.uciToSan(bestMove, boardBefore),
        ),
      );
      _recordPosition();
      onMoveMade?.call(bestMove);

      final end = _checkGameEnd();
      if (end != null) {
        _state = PlayState.gameOver;
        _result = end;
        onBoardUpdate?.call(_board, _state);
        onGameOver?.call(end);
        return;
      }

      _state = PlayState.userTurn;
      onBoardUpdate?.call(_board, _state);
    } catch (_) {
      if (!_active) return;
      _engineError = true;
      _state = PlayState.userTurn;
      onBoardUpdate?.call(_board, _state);
    } finally {
      if (identical(_forceEngineMoveCompleter, forceCompleter)) {
        _forceEngineMoveCompleter = null;
        _forceEngineMoveRequested = false;
      }
    }
  }

  Future<String?> _getEngineMove(
    String fen,
    EnginePowerProfile profile,
    EngineSearchConfig? config,
  ) {
    final provider = engineMoveProvider;
    if (provider != null) {
      return provider(fen, profile, config);
    }
    if (config == null) {
      return EngineManager().getBestMove(fen, profile: profile);
    }
    return EngineManager().getBestMoveWithConfig(fen, config);
  }

  String? _fallbackLegalMove(ChessBoard board) {
    final legalMoves = ChessRules.getLegalMoveUcis(board)..sort();
    if (legalMoves.isEmpty) return null;
    return legalMoves.first;
  }

  void requestImmediateEngineMove() {
    if (!_active || _state != PlayState.engineThinking || isGameOver) return;
    _forceEngineMoveRequested = true;
    final completer = _forceEngineMoveCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  GameEndResult? _checkGameEnd() {
    final currentTurn = _board.turn;

    if (ChessRules.isCheckmate(_board, currentTurn)) {
      final winner = currentTurn == PieceColor.white ? 'Black' : 'White';
      return GameEndResult(
        reason: 'Checkmate',
        winner: winner,
        message: '$winner wins by checkmate!',
      );
    }
    if (ChessRules.isStalemate(_board, currentTurn)) {
      return const GameEndResult(
          reason: 'Stalemate', winner: null, message: 'Draw by stalemate.');
    }
    if (ChessRules.isInsufficientMaterial(_board)) {
      return const GameEndResult(
        reason: 'Insufficient Material',
        winner: null,
        message: 'Draw - insufficient material.',
      );
    }
    if (_board.halfMoveClock >= 100) {
      return const GameEndResult(
          reason: '50-Move Rule',
          winner: null,
          message: 'Draw by 50-move rule.');
    }
    final fenKey = _board.toFen().split(' ').take(4).join(' ');
    if ((_positionHistory[fenKey] ?? 0) >= 3) {
      return const GameEndResult(
        reason: 'Threefold Repetition',
        winner: null,
        message: 'Draw by repetition.',
      );
    }
    return null;
  }

  void _recordPosition() {
    _recordFen(_board.toFen());
  }

  void _recordFen(String fen) {
    final fenKey = _board.toFen().split(' ').take(4).join(' ');
    final rawKey = fen.split(' ').take(4).join(' ');
    final key = rawKey.isEmpty ? fenKey : rawKey;
    _positionHistory[key] = (_positionHistory[key] ?? 0) + 1;
  }

  /// Resign the game. User forfeits.
  void resign() {
    if (!_active) return;
    if (isGameOver) return;
    _engineMoveToken++;
    final forceCompleter = _forceEngineMoveCompleter;
    if (forceCompleter != null && !forceCompleter.isCompleted) {
      forceCompleter.complete();
    }
    final winner = userColor == PieceColor.white ? 'Black' : 'White';
    _state = PlayState.gameOver;
    _result = GameEndResult(
        reason: 'Resignation', winner: winner, message: 'You resigned.');
    onBoardUpdate?.call(_board, _state);
    onGameOver?.call(_result!);
  }

  List<String> getLegalMovesFrom(String square) {
    if (!_active) return [];
    if (_state != PlayState.userTurn) return [];
    final piece = _board.pieces[square];
    if (piece == null || piece.color != userColor) return [];
    return ChessRules.getLegalMoves(_board, square);
  }

  void dispose() {
    _active = false;
    unawaited(EngineManager().shutdown());
  }
}

class _ForcedEngineMove {
  const _ForcedEngineMove();
}
