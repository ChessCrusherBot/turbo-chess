import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chess/chess_board.dart';
import '../models/move_classification.dart';
import 'chess_rules.dart';
import 'engine_evaluation.dart';
import 'engine_power_profile.dart';
import 'engine_health_report.dart';
import 'stockfish_engine.dart';

class EngineManager {
  static final EngineManager _instance = EngineManager._internal();
  factory EngineManager() => _instance;
  EngineManager._internal();

  static const String _engineAvailableKey = 'stockfish_available';

  StockfishEngine? _engine;
  bool _initialized = false;
  bool _usingFallback = false;
  EngineHealthReport? _lastHealthReport;

  bool get isInitialized => _initialized;
  bool get isUsingFallback => _usingFallback;
  bool get hasRealEngine => !_usingFallback && (_engine?.isReady ?? false);
  StockfishEngine? get engine => _engine;
  EngineHealthReport? get lastHealthReport => _lastHealthReport;

  Future<bool> initialize({bool force = false}) async {
    if (_initialized && !force) return !_usingFallback;

    final prefs = await SharedPreferences.getInstance();
    if (force) {
      await shutdown();
    }

    try {
      _engine ??= StockfishEngine();
      final ok = await _engine!.initialize(force: force);
      if (ok) {
        _initialized = true;
        _usingFallback = false;
        await prefs.setBool(_engineAvailableKey, true);
        return true;
      }
      _initialized = true;
      _usingFallback = true;
      await prefs.remove(_engineAvailableKey);
      return false;
    } catch (e) {
      debugPrint('Engine initialize error: $e');
      _initialized = true;
      _usingFallback = true;
      await prefs.remove(_engineAvailableKey);
      return false;
    }
  }

  Future<String?> getBestMove(
    String fen, {
    EnginePowerProfile profile = EnginePowerProfile.strong,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_usingFallback && _engine != null) {
        final stockfishMove =
            await _engine!.getBestMoveWithProfile(fen, profile);
        final legalStockfishMove = _legalizeEngineMove(fen, stockfishMove);
        if (legalStockfishMove != null) return legalStockfishMove;
      }
      return _getFallbackBestMove(fen);
    } catch (e) {
      debugPrint('Engine getBestMove error: $e');
      return _getFallbackBestMove(fen);
    }
  }

  Future<String?> getBestMoveWithConfig(
    String fen,
    EngineSearchConfig config,
  ) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_usingFallback && _engine != null) {
        final stockfishMove = await _engine!.getBestMoveWithConfig(fen, config);
        final legalStockfishMove = _legalizeEngineMove(fen, stockfishMove);
        if (legalStockfishMove != null) return legalStockfishMove;
      }
      return _getFallbackBestMove(fen);
    } catch (e) {
      debugPrint('Engine getBestMoveWithConfig error: $e');
      return _getFallbackBestMove(fen);
    }
  }

  Future<int?> getEvaluation(String fen, {int depth = 15}) async {
    final board = ChessBoard.tryFromFen(fen);
    if (board == null) return null;
    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_usingFallback && _engine != null) {
        final evaluation = await _engine!.getEvaluationScore(fen, depth);
        if (evaluation != null) {
          return EngineEvaluation.toWhitePerspective(evaluation, board.turn);
        }
      }
      return EngineEvaluation.toWhitePerspective(
        _evaluateBoard(board),
        board.turn,
      );
    } catch (e) {
      debugPrint('Engine getEvaluation error: $e');
      return EngineEvaluation.toWhitePerspective(
          _evaluateBoard(board), board.turn);
    }
  }

  Future<List<MoveEvaluation>> analyzeGame(
    List<String> fensAfterEachMove,
    List<bool> isUserMove,
  ) async {
    try {
      if (fensAfterEachMove.isEmpty || isUserMove.isEmpty) return [];
      if (!_initialized) {
        await initialize();
      }

      final results = <MoveEvaluation>[];
      final moveCount = fensAfterEachMove.length < isUserMove.length
          ? fensAfterEachMove.length
          : isUserMove.length;
      final rawEvals = <int>[];

      for (int i = 0; i < moveCount; i++) {
        rawEvals.add(await getEvaluation(fensAfterEachMove[i], depth: 18) ?? 0);
      }

      for (int i = 0; i < moveCount; i++) {
        final evalAfter = rawEvals[i];
        final evalBefore = i == 0 ? evalAfter : -rawEvals[i - 1];
        final evalAfterFromMoverPerspective = -evalAfter;
        final cpLoss =
            (evalBefore - evalAfterFromMoverPerspective).clamp(0, 9999).toInt();
        final bestMove = await getBestMove(
              fensAfterEachMove[i],
              profile: EnginePowerProfile.master,
            ) ??
            '';
        final quality =
            MoveClassifier.classify(cpLoss, cpLoss == 0 && bestMove.isNotEmpty);

        results.add(
          MoveEvaluation(
            moveUci: '',
            moveSan: '',
            evalBefore: evalBefore,
            evalAfter: evalAfter,
            centipawnLoss: cpLoss,
            bestMove: bestMove,
            quality: quality,
            isUserMove: isUserMove[i],
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('Engine analyzeGame error: $e');
      return [];
    }
  }

  Future<void> shutdown() async {
    try {
      await _engine?.shutdown();
    } catch (_) {}
    _initialized = false;
    _usingFallback = false;
    _engine = null;
  }

  Future<EngineHealthReport> runHealthCheck({bool forceRestart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _engine ??= StockfishEngine();

    try {
      final report = await _engine!.runHealthCheck(
        forceRestart: forceRestart || !_initialized,
      );
      _lastHealthReport = report;
      _initialized = true;
      _usingFallback = report.usingFallback;
      if (_usingFallback) {
        await prefs.remove(_engineAvailableKey);
      } else {
        await prefs.setBool(_engineAvailableKey, true);
      }
      return report;
    } catch (e) {
      debugPrint('Engine health check error: $e');
      _usingFallback = true;
      _initialized = true;
      await prefs.remove(_engineAvailableKey);
      final report = EngineHealthReport(
        checkedAt: DateTime.now(),
        usingFallback: true,
        binaryExists: false,
        processStarted: false,
        uciHandshakeOk: false,
        readyOk: false,
        bestMoveOk: false,
        evaluationOk: false,
        error: 'Stockfish health check failed: $e',
      );
      _lastHealthReport = report;
      return report;
    }
  }

  Future<void> resetEngineFlag() async {
    await shutdown();
    _lastHealthReport = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_engineAvailableKey);
  }

  String? _legalizeEngineMove(String fen, String? move) {
    if (move == null || move.length < 4 || move == '0000') return null;
    final normalized =
        move.substring(0, move.length >= 5 ? 5 : 4).toLowerCase();
    final board = ChessBoard.tryFromFen(fen);
    if (board == null) return null;
    final legalMoves = ChessRules.getLegalMoveUcis(board);
    if (legalMoves.contains(normalized)) return normalized;
    return null;
  }

  String? _getFallbackBestMove(String fen) {
    final board = ChessBoard.tryFromFen(fen);
    if (board == null) return null;
    final legalMoves = ChessRules.getLegalMoveUcis(board)..sort();
    if (legalMoves.isEmpty) return null;

    var bestMove = legalMoves.first;
    var bestScore = -10000000;
    for (final move in legalMoves) {
      final newBoard = ChessRules.applyUciMove(board, move);
      if (newBoard == null) continue;
      final score = _scoreMove(board, newBoard, move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  int _scoreMove(ChessBoard before, ChessBoard after, String move) {
    final mover = before.turn;
    var score = -_evaluateBoard(after);

    if (ChessRules.isCheckmate(after, after.turn)) score += 1000000;
    if (ChessRules.isStalemate(after, after.turn)) score -= 300;
    if (ChessRules.isInsufficientMaterial(after)) score -= 100;

    final from = move.substring(0, 2);
    final to = move.substring(2, 4);
    final movingPiece = before.pieces[from];
    final capturedPiece = before.pieces[to];
    if (capturedPiece != null) {
      score += (_pieceValue(capturedPiece.type) * 1.2).round();
    } else if (movingPiece?.type == PieceType.pawn &&
        before.enPassantTarget == to) {
      score += _pieceValue(PieceType.pawn);
    }

    if (move.length > 4) {
      score +=
          _pieceValue(_promotionType(move[4])) - _pieceValue(PieceType.pawn);
    }
    if (ChessRules.isKingInCheck(after, after.turn)) score += 45;
    if (_isCenterSquare(to)) {
      score += movingPiece?.type == PieceType.pawn ? 10 : 16;
    }
    if (movingPiece?.type == PieceType.knight ||
        movingPiece?.type == PieceType.bishop) {
      final fromRank = int.tryParse(from[1]) ?? 0;
      if ((mover == PieceColor.white && fromRank == 1) ||
          (mover == PieceColor.black && fromRank == 8)) {
        score += 12;
      }
    }
    return score;
  }

  int _evaluateBoard(ChessBoard board) {
    if (ChessRules.isCheckmate(board, board.turn)) return -1000000;
    if (ChessRules.isStalemate(board, board.turn) ||
        ChessRules.isInsufficientMaterial(board)) {
      return 0;
    }

    var whiteScore = 0;
    var blackScore = 0;
    for (final entry in board.pieces.entries) {
      final piece = entry.value;
      var value = _pieceValue(piece.type);
      if (_isCenterSquare(entry.key)) {
        value += piece.type == PieceType.pawn ? 8 : 12;
      }
      if (piece.color == PieceColor.white) {
        whiteScore += value;
      } else {
        blackScore += value;
      }
    }

    final material = whiteScore - blackScore;
    final perspective = board.turn == PieceColor.white ? material : -material;
    final mobility = ChessRules.getLegalMoveUcis(board).length;
    return perspective + mobility;
  }

  int _pieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 100;
      case PieceType.knight:
        return 320;
      case PieceType.bishop:
        return 330;
      case PieceType.rook:
        return 500;
      case PieceType.queen:
        return 900;
      case PieceType.king:
        return 0;
    }
  }

  PieceType _promotionType(String suffix) {
    switch (suffix.toLowerCase()) {
      case 'r':
        return PieceType.rook;
      case 'b':
        return PieceType.bishop;
      case 'n':
        return PieceType.knight;
      default:
        return PieceType.queen;
    }
  }

  bool _isCenterSquare(String square) =>
      square == 'd4' || square == 'e4' || square == 'd5' || square == 'e5';
}
