import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ads/ad_free_service.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/audio/chess_sound_events.dart';
import '../../../core/audio/turbo_sound_service.dart';
import '../../../core/bookmarks/bookmark_store.dart';
import '../../../core/bookmarks/chess_bookmark.dart';
import '../../../core/chess/chess_board.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/chess_rules.dart';
import '../../../core/engine/engine_power_profile.dart';
import '../../../core/engine/play_vs_engine.dart';
import '../../../core/models/models.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_completion_rules.dart';
import '../../../core/positions/position_difficulty.dart';
import '../../../core/positions/position_fen_repository.dart';
import '../../../core/positions/position_progress_store.dart';
import '../../../core/ui/confirm_leave_dialog.dart';
import '../../../core/ui/confirm_resign_dialog.dart';
import '../../../core/ui/promotion_dialog.dart';
import '../../../core/ui_components.dart';
import '../data/active_drill_store.dart';

class DrillDetailBaseScreen extends StatefulWidget {
  final String screenTitle;
  final OpeningTopic topic;
  final String subtopic;
  final Color color;
  final int difficulty;
  final PositionCategory? positionCategory;
  final int? positionIndex;
  final int? totalPositions;
  final PositionFenRepository? positionRepository;
  final PositionProgressStore? positionProgressStore;
  final bool initialPositionCompleted;
  final AdFreeService? adFreeService;
  final EngineMoveProvider? engineMoveProvider;
  final ValueChanged<DrillDebugSnapshot>? debugOnStateChanged;
  final bool resumeActiveOnOpen;

  const DrillDetailBaseScreen({
    super.key,
    required this.screenTitle,
    required this.topic,
    required this.subtopic,
    required this.color,
    required this.difficulty,
    this.positionCategory,
    this.positionIndex,
    this.totalPositions,
    this.positionRepository,
    this.positionProgressStore,
    this.initialPositionCompleted = false,
    this.adFreeService,
    this.engineMoveProvider,
    this.debugOnStateChanged,
    this.resumeActiveOnOpen = false,
  });

  DrillDetailBaseScreen.position({
    super.key,
    required PositionCategory category,
    required int positionIndex,
    required String fen,
    required int totalPositions,
    required Color color,
    PositionFenRepository? positionRepository,
    PositionProgressStore? positionProgressStore,
    bool initialPositionCompleted = false,
    AdFreeService? adFreeService,
    EngineMoveProvider? engineMoveProvider,
    ValueChanged<DrillDebugSnapshot>? debugOnStateChanged,
    bool resumeActiveOnOpen = false,
  })  : screenTitle = category.title,
        topic = OpeningTopic(
          id: category.id,
          label: category.title,
          icon: category.id,
          subtopics: ['Position $positionIndex'],
          drillsBySubtopic: {
            'Position $positionIndex': [
              _buildPositionDrill(
                category: category,
                positionIndex: positionIndex,
                fen: fen,
              ),
            ],
          },
        ),
        subtopic = 'Position $positionIndex',
        color = color,
        difficulty = PositionDifficulty.forIndex(positionIndex).level,
        positionCategory = category,
        positionIndex = positionIndex,
        totalPositions = totalPositions,
        positionRepository = positionRepository,
        positionProgressStore = positionProgressStore,
        initialPositionCompleted = initialPositionCompleted,
        adFreeService = adFreeService,
        engineMoveProvider = engineMoveProvider,
        debugOnStateChanged = debugOnStateChanged,
        resumeActiveOnOpen = resumeActiveOnOpen;

  @override
  State<DrillDetailBaseScreen> createState() => _DrillDetailBaseScreenState();
}

ChessDrill _buildPositionDrill({
  required PositionCategory category,
  required int positionIndex,
  required String fen,
}) {
  final difficulty = PositionDifficulty.forIndex(positionIndex);
  return ChessDrill(
    id: '${category.id}_position_$positionIndex',
    fen: fen,
    sideToMove: 'Side to move',
    task: 'Checkmate the engine from this position.',
    bestMove: '',
    bestMoveUci: '',
    alternativeMoves: const [],
    hint: '',
    explanation: '',
    conceptTag: difficulty.label,
    difficulty: difficulty.level,
  );
}

class DrillDebugSnapshot {
  final int sessionId;
  final int gameToken;
  final PositionCategory? category;
  final int positionIndex;
  final String initialFen;
  final String currentFen;
  final int moveCount;
  final bool engineThinking;
  final bool isGameOver;

  const DrillDebugSnapshot({
    required this.sessionId,
    required this.gameToken,
    required this.category,
    required this.positionIndex,
    required this.initialFen,
    required this.currentFen,
    required this.moveCount,
    required this.engineThinking,
    required this.isGameOver,
  });
}

class _DrillDetailBaseScreenState extends State<DrillDetailBaseScreen>
    with WidgetsBindingObserver {
  static const Color _boardLight = Color(0xFFE6D8BD);
  static const Color _boardDark = Color(0xFF5E7C66);
  static const ActiveDrillStore _activeDrillStore = ActiveDrillStore();
  static int _nextSessionId = 0;

  final TurboSoundService _soundService = TurboSoundService.instance;
  final BookmarkStore _bookmarkStore = const BookmarkStore();
  late final int _drillSessionId;
  int _gameToken = 0;

  late List<ChessDrill> _drills;
  late ChessDrill _currentDrill;
  int _currentDrillIndex = 0;
  int _currentPositionIndex = 1;
  int _totalPositions = 1;
  EnginePowerProfile _engineProfile = EnginePowerProfile.strong;
  PositionFenRepository? _positionRepository;
  PositionProgressStore? _positionProgressStore;
  DateTime? _activeDrillStartedAt;
  DateTime? _lastActiveDrillSnapshotWriteAt;

  ChessBoard _playBoard = ChessBoard.starting();
  String _initialFen = ChessBoard.standardStartingFen;
  PieceColor _userColor = PieceColor.white;
  PlayVsEngine? _gameEngine;
  GameEndResult? _gameResult;
  String? _fenErrorMessage;
  List<ChessBookmark> _bookmarks = const [];
  ChessBookmark? _activeBookmark;
  bool _bookmarkBusy = false;

  String? _selectedSquare;
  List<String> _legalMoves = const [];
  String? _lastMoveFrom;
  String? _lastMoveTo;
  String? _checkSquare;
  List<String> _extraHighlights = const [];

  bool _boardFlipped = false;
  bool _engineThinking = false;
  bool _isGameOver = false;
  bool _resultDialogVisible = false;
  bool _leaveDialogVisible = false;
  bool _leavingDrill = false;
  bool _engineErrorVisible = false;
  bool _loadingNextPosition = false;
  bool _currentPositionCompleted = false;
  bool _activeDrillSnapshotPaused = false;
  bool _activeDrillWasRestored = false;

  bool get _isPositionMode => widget.positionCategory != null;
  bool get _hasActiveAttempt {
    return _gameEngine != null &&
        !_isGameOver &&
        !_resultDialogVisible &&
        !_leavingDrill &&
        _fenErrorMessage == null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeDrillSnapshotPaused = widget.resumeActiveOnOpen;
    _drillSessionId = ++_nextSessionId;
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _currentPositionIndex = _resolvedPositionIndex;
    _totalPositions = widget.totalPositions ?? 1;
    _currentPositionCompleted = widget.initialPositionCompleted;
    if (_isPositionMode) {
      _positionRepository =
          widget.positionRepository ?? PositionFenRepository();
      _positionProgressStore =
          widget.positionProgressStore ?? const PositionProgressStore();
      unawaited(_loadPositionProgress());
    }
    _drills = widget.topic.getDrillsForSubtopic(widget.subtopic);
    _currentDrill = _safeDrillAt(0).copyWith(difficulty: widget.difficulty);
    _loadMeta();
    unawaited(_loadBookmarks());
    _loadEngineProfile();
    _loadDrillAt(0, reason: 'initial open');
    if (widget.resumeActiveOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_restoreActiveDrillFromStore());
      });
    }
  }

  @override
  void didUpdateWidget(covariant DrillDetailBaseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeIdentityChanged = _didRouteIdentityChange(oldWidget);
    final fenChanged = _firstFen(oldWidget) != _firstFen(widget);

    _positionRepository = widget.positionRepository ??
        (_isPositionMode ? PositionFenRepository() : null);
    _positionProgressStore = widget.positionProgressStore ??
        (_isPositionMode ? const PositionProgressStore() : null);
    if (!routeIdentityChanged) {
      _totalPositions = widget.totalPositions ?? _totalPositions;
      _currentPositionCompleted =
          _currentPositionCompleted || widget.initialPositionCompleted;
      if (_currentDrill.difficulty != widget.difficulty) {
        _currentDrill = _currentDrill.copyWith(difficulty: widget.difficulty);
      }
      if (fenChanged) {
        _debugReload(
          reason: 'same-position FEN update from widget',
          allowed: false,
        );
      }
      if (_isPositionMode) {
        unawaited(_loadPositionProgress());
      }
      return;
    }

    _gameEngine?.dispose();
    _activeDrillSnapshotPaused = widget.resumeActiveOnOpen;
    _currentPositionIndex = _resolvedPositionIndex;
    _totalPositions = widget.totalPositions ?? 1;
    _currentPositionCompleted = widget.initialPositionCompleted;
    _drills = widget.topic.getDrillsForSubtopic(widget.subtopic);
    _currentDrill = _safeDrillAt(0).copyWith(difficulty: widget.difficulty);
    if (_isPositionMode) {
      unawaited(_loadPositionProgress());
    }
    _loadDrillAt(0, reason: 'route/source identity changed');
    if (widget.resumeActiveOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_restoreActiveDrillFromStore());
      });
    }
  }

  int get _resolvedPositionIndex {
    if (widget.positionCategory != null) {
      final positionIndex = widget.positionIndex;
      if (positionIndex == null) {
        throw StateError('Position drill opened without a position index.');
      }
      return positionIndex;
    }
    return widget.positionIndex ?? 1;
  }

  bool _didRouteIdentityChange(DrillDetailBaseScreen oldWidget) {
    return oldWidget.positionCategory != widget.positionCategory ||
        oldWidget.positionIndex != widget.positionIndex ||
        oldWidget.topic.id != widget.topic.id ||
        oldWidget.subtopic != widget.subtopic;
  }

  static String _firstFen(DrillDetailBaseScreen widget) {
    final drills = widget.topic.getDrillsForSubtopic(widget.subtopic);
    return drills.isEmpty ? '' : drills.first.fen;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveActiveDrillSnapshot(force: true));
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _gameEngine?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_saveActiveDrillSnapshot(force: true));
    }
  }

  Future<void> _loadPositionProgress() async {
    final category = widget.positionCategory;
    final store = _positionProgressStore;
    final positionIndex = _currentPositionIndex;
    if (category == null || store == null) return;

    final progress = await store.snapshot(category);
    if (!mounted ||
        category != widget.positionCategory ||
        positionIndex != _currentPositionIndex) {
      _debugLog('ignored stale progress snapshot');
      return;
    }
    setState(() {
      _currentPositionCompleted = progress.isCompleted(positionIndex);
    });
  }

  Future<void> _loadMeta() async {
    await _soundService.initialize();
  }

  Future<void> _loadEngineProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProfile = EnginePowerProfile.fromId(
      prefs.getString(EnginePowerProfile.preferencesKey),
    );
    if (!mounted) return;
    if (_activeDrillWasRestored) return;

    setState(() {
      _engineProfile = savedProfile;
    });
    _gameEngine?.setEngineProfile(savedProfile);
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _bookmarkStore.load();
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _activeBookmark = _findBookmarkForFen(_playBoard.toFen());
    });
  }

  ChessDrill _safeDrillAt(int index) {
    if (_drills.isNotEmpty) {
      final safeIndex = index.clamp(0, _drills.length - 1).toInt();
      return _drills[safeIndex];
    }

    return ChessDrill(
      id: '${widget.topic.id}_fallback',
      fen:
          'rn2kb1r/pp3ppp/1q2pn2/2pp1b2/2P5/1Q1PBNP1/PP2PPBP/RN2K2R w KQkq - 0 8',
      sideToMove: 'White',
      task: 'Play the position against the engine and convert the advantage.',
      bestMove: '',
      bestMoveUci: '',
      alternativeMoves: const [],
      hint: '',
      explanation:
          'This fallback keeps the live drill pipeline available if content is missing.',
      conceptTag: 'Live Drill',
      difficulty: widget.difficulty,
    );
  }

  void _loadDrillAt(int index, {required String reason}) {
    final safeIndex = index.clamp(0, math.max(_drills.length - 1, 0)) as int;
    final drill = _safeDrillAt(safeIndex).copyWith(
      difficulty: widget.difficulty,
    );

    _debugReload(reason: reason, allowed: true);
    _gameEngine?.dispose();
    _currentDrillIndex = safeIndex;
    _currentDrill = drill;
    final startingBoard = ChessBoard.tryFromFen(drill.fen);
    if (startingBoard == null) {
      _gameEngine?.dispose();
      _currentDrillIndex = safeIndex;
      _currentDrill = drill;
      _showFenError(
          'This drill position has an invalid FEN and cannot be opened.');
      return;
    }
    _configureNewGame(startingBoard, initialFen: drill.fen, reason: reason);

    if (mounted) {
      setState(() {});
    }

    final engine = _gameEngine;
    final gameToken = _gameToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentEngine(engine, gameToken)) return;
      engine?.start();
      unawaited(_saveActiveDrillSnapshot(force: true));
      _emitDebugSnapshot();
    });
  }

  void _configureNewGame(
    ChessBoard startingBoard, {
    required String initialFen,
    required String reason,
  }) {
    final gameToken = ++_gameToken;
    _initialFen = initialFen;
    _userColor = startingBoard.turn;
    _playBoard = startingBoard;
    _boardFlipped = _userColor == PieceColor.black;
    _selectedSquare = null;
    _legalMoves = const [];
    _lastMoveFrom = null;
    _lastMoveTo = null;
    _extraHighlights = const [];
    _checkSquare = _computeCheckSquare(startingBoard, playSound: false);
    _engineThinking = false;
    _isGameOver = false;
    _resultDialogVisible = false;
    _leaveDialogVisible = false;
    _leavingDrill = false;
    _engineErrorVisible = false;
    _fenErrorMessage = null;
    _activeBookmark = _findBookmarkForFen(startingBoard.toFen());
    _gameResult = null;

    final engine = PlayVsEngine(
      startingFen: initialFen,
      userColor: _userColor,
      engineProfile: _engineProfile,
      engineMoveProvider: widget.engineMoveProvider,
    );

    _attachEngineCallbacks(engine, gameToken);

    _gameEngine = engine;
    _activeDrillStartedAt = DateTime.now();
    _lastActiveDrillSnapshotWriteAt = null;
    _activeDrillWasRestored = false;
    _debugLog(
      'initialized game token=$gameToken reason=$reason '
      'category=${widget.positionCategory?.id ?? widget.topic.id} '
      'position=$_currentPositionIndex fen=${_fenFingerprint(initialFen)}',
    );
    _emitDebugSnapshot();
  }

  void _attachEngineCallbacks(PlayVsEngine engine, int gameToken) {
    engine.onBoardUpdate = (board, state) {
      if (!_isCurrentEngine(engine, gameToken)) return;
      setState(() {
        _playBoard = board;
        _engineThinking = state == PlayState.engineThinking;
        _isGameOver = state == PlayState.gameOver;
        _engineErrorVisible = engine.engineError;
        _checkSquare = _computeCheckSquare(board);
        _activeBookmark = _findBookmarkForFen(board.toFen());
      });
      _emitDebugSnapshot();
      unawaited(_saveActiveDrillSnapshot(force: true));
    };

    engine.onMoveMade = (moveUci) {
      if (!_isCurrentEngine(engine, gameToken) || moveUci.length < 4) {
        return;
      }
      setState(() {
        _lastMoveFrom = moveUci.substring(0, 2);
        _lastMoveTo = moveUci.substring(2, 4);
        _selectedSquare = null;
        _legalMoves = const [];
        _extraHighlights = const [];
        final movingPiece = _playBoard.pieces[_lastMoveFrom!];
        if (movingPiece?.type == PieceType.king &&
            (_lastMoveFrom!.codeUnitAt(0) - _lastMoveTo!.codeUnitAt(0)).abs() ==
                2) {
          _highlightCastlingMove(_lastMoveFrom!, _lastMoveTo!);
        }
      });
      _emitDebugSnapshot();
      unawaited(_saveActiveDrillSnapshot(force: true));
      _playSoundForLatestMove(engine);
    };

    engine.onGameOver = (result) {
      if (!_isCurrentEngine(engine, gameToken)) return;
      setState(() {
        _gameResult = result;
        _isGameOver = true;
        _engineThinking = false;
        _selectedSquare = null;
        _legalMoves = const [];
      });
      _soundService.playGameOver();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isCurrentEngine(engine, gameToken)) return;
        unawaited(_finishGameResult(result, engine, gameToken));
      });
    };
  }

  Future<void> _finishGameResult(
    GameEndResult result,
    PlayVsEngine engine,
    int gameToken,
  ) async {
    if (!_isCurrentEngine(engine, gameToken)) return;
    await _markPositionCompletedIfNeeded(result, engine, gameToken);
    if (!_isCurrentEngine(engine, gameToken)) return;
    await _activeDrillStore.clear();
    await _showPostGameResultDialog();
  }

  Future<void> _markPositionCompletedIfNeeded(
    GameEndResult result,
    PlayVsEngine engine,
    int gameToken,
  ) async {
    final category = widget.positionCategory;
    final store = _positionProgressStore;
    final positionIndex = _currentPositionIndex;
    if (category == null || store == null) return;
    if (!_userWonByCheckmate(result)) return;

    await store.markCompleted(category, positionIndex);
    final progress = await store.snapshot(category);
    if (!_isCurrentEngine(engine, gameToken) ||
        category != widget.positionCategory ||
        positionIndex != _currentPositionIndex) {
      _debugLog('ignored stale completion snapshot');
      return;
    }
    setState(() {
      _currentPositionCompleted = progress.isCompleted(positionIndex);
    });
  }

  Future<void> _restoreActiveDrillFromStore() async {
    final category = widget.positionCategory;
    if (category == null) {
      _activeDrillSnapshotPaused = false;
      return;
    }

    final snapshot = await _activeDrillStore.load();
    if (!mounted) return;
    if (snapshot == null ||
        snapshot.category != category ||
        snapshot.positionIndex != _currentPositionIndex) {
      _activeDrillSnapshotPaused = false;
      await _saveActiveDrillSnapshot(force: true);
      return;
    }

    _restoreActiveDrill(snapshot);
  }

  void _restoreActiveDrill(ActiveDrillSnapshot snapshot) {
    final board = ChessBoard.tryFromFen(snapshot.currentFen);
    if (board == null) {
      _activeDrillSnapshotPaused = false;
      unawaited(_activeDrillStore.clear());
      return;
    }

    _gameEngine?.dispose();
    final profile = EnginePowerProfile.fromId(snapshot.engineProfileId);
    final gameToken = ++_gameToken;
    final game = PlayVsEngine.restored(
      startingFen: snapshot.startingFen,
      currentFen: snapshot.currentFen,
      moves: snapshot.moves,
      userColor: snapshot.userColor,
      engineProfile: profile,
      engineMoveProvider: widget.engineMoveProvider,
    );
    _attachEngineCallbacks(game, gameToken);
    _activeDrillWasRestored = true;

    final lastMove = snapshot.moves.isEmpty ? null : snapshot.moves.last.move;
    setState(() {
      _gameEngine = game;
      _activeDrillStartedAt = snapshot.startedAt;
      _lastActiveDrillSnapshotWriteAt = null;
      _engineProfile = profile;
      _initialFen = snapshot.startingFen;
      _userColor = snapshot.userColor;
      _playBoard = board;
      _boardFlipped = snapshot.boardFlipped;
      _selectedSquare = null;
      _legalMoves = const [];
      _lastMoveFrom = lastMove == null || lastMove.length < 4
          ? null
          : lastMove.substring(0, 2);
      _lastMoveTo = lastMove == null || lastMove.length < 4
          ? null
          : lastMove.substring(2, 4);
      _extraHighlights = const [];
      _checkSquare = _computeCheckSquare(board, playSound: false);
      _engineThinking = game.state == PlayState.engineThinking;
      _isGameOver = false;
      _resultDialogVisible = false;
      _leaveDialogVisible = false;
      _leavingDrill = false;
      _engineErrorVisible = game.engineError;
      _fenErrorMessage = null;
      _activeBookmark = _findBookmarkForFen(board.toFen());
      _gameResult = null;
    });

    _activeDrillSnapshotPaused = false;
    _debugLog(
      'restored active drill token=$gameToken '
      'category=${snapshot.category.id} position=${snapshot.positionIndex}',
    );
    _emitDebugSnapshot();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentEngine(game, gameToken)) return;
      game.resumeRestored();
      unawaited(_saveActiveDrillSnapshot(force: true));
    });
  }

  Future<void> _saveActiveDrillSnapshot({bool force = false}) async {
    final category = widget.positionCategory;
    final engine = _gameEngine;
    if (category == null ||
        engine == null ||
        _activeDrillSnapshotPaused ||
        _fenErrorMessage != null ||
        _isGameOver ||
        engine.isGameOver) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastActiveDrillSnapshotWriteAt != null &&
        now.difference(_lastActiveDrillSnapshotWriteAt!) <
            const Duration(milliseconds: 900)) {
      return;
    }
    _lastActiveDrillSnapshotWriteAt = now;

    await _activeDrillStore.save(
      ActiveDrillSnapshot(
        startedAt: _activeDrillStartedAt ?? now,
        updatedAt: now,
        category: category,
        positionIndex: _currentPositionIndex,
        startingFen: _initialFen,
        currentFen: engine.board.toFen(),
        userColor: _userColor,
        engineProfileId: _engineProfile.id,
        boardFlipped: _boardFlipped,
        moves: engine.moves,
      ),
    );
  }

  bool _userWonByCheckmate(GameEndResult result) {
    return PositionCompletionRules.isUserCheckmateWin(
      result: result,
      userColor: _userColor,
    );
  }

  Future<void> _onTapPlaySquare(String square) async {
    final engine = _gameEngine;
    final gameToken = _gameToken;
    if (engine == null || _isGameOver || _engineThinking) return;
    if (!_isCurrentEngine(engine, gameToken)) return;

    if (_selectedSquare == null) {
      final legalMoves = engine.getLegalMovesFrom(square);
      if (legalMoves.isEmpty) return;
      setState(() {
        _selectedSquare = square;
        _legalMoves = legalMoves;
      });
      _soundService.playTap();
      return;
    }

    if (_legalMoves.contains(square)) {
      final from = _selectedSquare!;
      final piece = _playBoard.pieces[from];
      String? promotion;

      if (piece?.type == PieceType.pawn) {
        final toRank = int.tryParse(square[1]) ?? 0;
        final promotes = (piece!.color == PieceColor.white && toRank == 8) ||
            (piece.color == PieceColor.black && toRank == 1);
        if (promotes) {
          promotion = await PromotionDialog.show(context, piece.color);
          if (!_isCurrentEngine(engine, gameToken)) return;
          if (promotion == null) {
            setState(() {
              _selectedSquare = null;
              _legalMoves = const [];
            });
            return;
          }
        }
      }

      setState(() {
        _selectedSquare = null;
        _legalMoves = const [];
      });

      final accepted =
          await engine.userMove(from, square, promotion: promotion);
      if (!_isCurrentEngine(engine, gameToken)) return;
      if (!accepted) {
        _soundService.playWrong();
      }
      return;
    }

    final legalMoves = engine.getLegalMovesFrom(square);
    setState(() {
      _selectedSquare = legalMoves.isEmpty ? null : square;
      _legalMoves = legalMoves;
    });
  }

  Future<void> _resign() async {
    if (_isGameOver) return;
    final shouldResign = await ConfirmResignDialog.show(context);
    if (!mounted || !shouldResign) return;
    _gameEngine?.resign();
  }

  Future<void> _handleBackToTrainingRequested() async {
    if (!_hasActiveAttempt) {
      _backToTraining();
      return;
    }

    if (_leaveDialogVisible || _leavingDrill) return;
    _leaveDialogVisible = true;
    final isCompletedPosition = _isPositionMode && _currentPositionCompleted;
    final shouldLeave = await ConfirmLeaveDialog.show(
      context,
      title: isCompletedPosition ? 'Leave completed drill?' : 'Leave drill?',
      message: isCompletedPosition
          ? 'Your completion is already saved. Leaving will not change your progress.'
          : 'Your current attempt will stay available from Home. This position will not be marked complete unless you checkmate the engine.',
      cancelLabel: 'Cancel',
      confirmLabel: isCompletedPosition ? 'Leave' : 'Leave Drill',
      icon: Icons.exit_to_app_rounded,
    );
    _leaveDialogVisible = false;
    if (!mounted || !shouldLeave) return;
    _leaveActiveDrill();
  }

  void _leaveActiveDrill() {
    if (_leavingDrill) return;
    _leavingDrill = true;
    unawaited(_saveActiveDrillSnapshot(force: true));
    _gameEngine?.dispose();
    _backToTraining();
  }

  Future<void> _showEnginePowerSelector() async {
    final selected = await showModalBottomSheet<EnginePowerProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(116),
      isScrollControlled: false,
      builder: (sheetContext) {
        return _EnginePowerSheet(
          selectedProfile: _engineProfile,
          onSelected: (profile) => Navigator.of(sheetContext).pop(profile),
        );
      },
    );

    if (!mounted || selected == null) return;
    await _setEngineProfile(selected);
  }

  Future<void> _setEngineProfile(EnginePowerProfile profile) async {
    setState(() {
      _engineProfile = profile;
    });
    _gameEngine?.setEngineProfile(profile);
    unawaited(_saveActiveDrillSnapshot(force: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EnginePowerProfile.preferencesKey, profile.id);
    if (!mounted) return;

    if (profile.infoText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profile.infoText!),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  ChessBookmark? _findBookmarkForFen(String fen) {
    final candidate = _bookmarkCandidate(fen);
    for (final bookmark in _bookmarks) {
      if (bookmark.duplicateKey == candidate.duplicateKey) {
        return bookmark;
      }
    }
    return null;
  }

  ChessBookmark _bookmarkCandidate(String fen) {
    final category = widget.positionCategory;
    final difficulty = _isPositionMode
        ? PositionDifficulty.forIndex(_currentPositionIndex).label
        : 'Level ${_currentDrill.difficulty}';
    final sourceType = category?.id ?? 'custom';
    final title = _isPositionMode
        ? '${category?.shortTitle ?? widget.screenTitle} Position '
            '$_currentPositionIndex'
        : '${widget.screenTitle} - ${widget.subtopic}';

    return ChessBookmark(
      id: 'bookmark_${DateTime.now().microsecondsSinceEpoch}',
      fen: fen,
      sourceType: sourceType,
      module: category?.id ?? widget.topic.id,
      positionIndex: category == null ? null : _currentPositionIndex,
      title: title,
      difficulty: difficulty,
      savedAt: DateTime.now(),
    );
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkBusy || _fenErrorMessage != null) return;
    final fen = _playBoard.toFen();
    final candidate = _bookmarkCandidate(fen);
    setState(() {
      _bookmarkBusy = true;
    });

    try {
      final saved = await _bookmarkStore.toggle(candidate);
      final bookmarks = await _bookmarkStore.load();
      if (!mounted) return;
      setState(() {
        _bookmarks = bookmarks;
        _activeBookmark = saved ?? _findBookmarkForFen(fen);
        _bookmarkBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(saved == null ? 'Bookmark removed.' : 'Position saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookmarkBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This position could not be bookmarked.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPostGameResultDialog() async {
    if (_resultDialogVisible) return;
    final result = _gameResult;
    if (result == null) return;
    final positionCompleted = _isPositionMode && _userWonByCheckmate(result);

    _resultDialogVisible = true;
    final action = await showDialog<_PostGameAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PostGameResultDialog(
          result: result,
          userColor: _userColor,
          accentColor: widget.color,
          hasNextDrill: _canOpenNext,
          isPositionMode: _isPositionMode,
          isPositionCompleted: positionCompleted,
          onAction: (action) => Navigator.of(dialogContext).pop(action),
        );
      },
    );

    if (!mounted) return;
    _resultDialogVisible = false;

    switch (action) {
      case _PostGameAction.nextDrill:
        await _nextDrill();
      case _PostGameAction.retryDrill:
        _startCurrentDrillAgain();
      case _PostGameAction.backToTraining:
        _backToTraining();
      case _PostGameAction.back:
      case null:
        break;
    }
  }

  void _backToTraining() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil('/train', (route) => false);
  }

  void _startCurrentDrillAgain() {
    _debugReload(reason: 'user reset current drill', allowed: true);
    _gameEngine?.dispose();
    final resetFen =
        _currentDrill.fen.isNotEmpty ? _currentDrill.fen : _initialFen;
    final startingBoard = ChessBoard.tryFromFen(resetFen);
    if (startingBoard == null) {
      _showFenError(
          'This drill position has an invalid FEN and cannot be reset.');
      return;
    }
    _configureNewGame(
      startingBoard,
      initialFen: resetFen,
      reason: 'user reset current drill',
    );
    setState(() {});
    _gameEngine?.start();
    unawaited(_saveActiveDrillSnapshot(force: true));
    _emitDebugSnapshot();
  }

  Future<void> _confirmResetCurrentDrill() async {
    final shouldReset = await ConfirmLeaveDialog.show(
      context,
      title: 'Reset drill?',
      message: 'This will restart the current drill and clear this attempt.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Reset',
      icon: Icons.replay_rounded,
    );
    if (!mounted || !shouldReset) return;
    _startCurrentDrillAgain();
  }

  bool get _canOpenNext {
    if (_isPositionMode) {
      return _currentPositionIndex < _totalPositions;
    }
    return _currentDrillIndex < _drills.length - 1;
  }

  Future<void> _nextDrill() async {
    if (_isPositionMode) {
      await _nextPosition();
      return;
    }

    final nextIndex = _currentDrillIndex + 1;
    if (nextIndex >= _drills.length) {
      Navigator.pushReplacementNamed(
        context,
        '/train/session_summary',
        arguments: {
          'topicName': widget.topic.label,
        },
      );
      return;
    }

    _loadDrillAt(nextIndex, reason: 'user opened next drill');
  }

  Future<void> _nextPosition() async {
    final category = widget.positionCategory;
    final repository = _positionRepository;
    if (category == null || repository == null || _loadingNextPosition) return;

    if (!_canOpenNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Position not found.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DesignSystem.backgroundElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final nextPositionIndex = _currentPositionIndex + 1;
    if (nextPositionIndex > _totalPositions) return;

    setState(() {
      _loadingNextPosition = true;
    });

    try {
      final fen = await repository.loadFen(category, nextPositionIndex);
      final startingBoard = ChessBoard.tryFromFen(fen);
      if (startingBoard == null) {
        throw const FormatException('Next position FEN is invalid.');
      }
      if (!mounted) return;

      _debugReload(reason: 'user opened next position', allowed: true);
      _gameEngine?.dispose();
      setState(() {
        _loadingNextPosition = false;
      });
      await Navigator.pushReplacementNamed(
        context,
        '/train/position/drill',
        arguments: {
          'category': category.id,
          'positionIndex': nextPositionIndex,
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingNextPosition = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Next position could not be loaded.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DesignSystem.errorContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showFenError(String message) {
    debugPrint('Turbo Chess FEN error: $message');
    if (!mounted) return;
    setState(() {
      _fenErrorMessage = message;
      _selectedSquare = null;
      _legalMoves = const [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _extraHighlights = const [];
      _checkSquare = null;
      _engineThinking = false;
      _isGameOver = true;
      _engineErrorVisible = false;
    });
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(_handleBackToTrainingRequested());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _playSoundForLatestMove(PlayVsEngine engine) {
    final gameToken = _gameToken;
    Future.microtask(() {
      if (!_isCurrentEngine(engine, gameToken)) return;
      if (engine.isGameOver) return;
      final move = engine.moves.isEmpty ? null : engine.moves.last;
      if (move == null) return;
      _soundService.playEvent(
        soundEventForCompletedMove(boardAfter: engine.board, move: move),
      );
    });
  }

  String? _computeCheckSquare(ChessBoard board, {bool playSound = true}) {
    if (!ChessRules.isKingInCheck(board, board.turn)) return null;
    return ChessRules.findKingSquare(board, board.turn);
  }

  bool _isCurrentEngine(PlayVsEngine? engine, int gameToken) {
    if (!mounted || engine == null) return false;
    final current = identical(_gameEngine, engine) && _gameToken == gameToken;
    if (!current) {
      _debugLog(
        'ignored stale engine callback token=$gameToken current=$_gameToken',
      );
    }
    return current;
  }

  void _emitDebugSnapshot() {
    final callback = widget.debugOnStateChanged;
    if (callback == null) return;
    callback(
      DrillDebugSnapshot(
        sessionId: _drillSessionId,
        gameToken: _gameToken,
        category: widget.positionCategory,
        positionIndex: _currentPositionIndex,
        initialFen: _initialFen,
        currentFen: _playBoard.toFen(),
        moveCount: _gameEngine?.moves.length ?? 0,
        engineThinking: _engineThinking,
        isGameOver: _isGameOver,
      ),
    );
  }

  void _debugReload({required String reason, required bool allowed}) {
    _debugLog(
      '${allowed ? 'allowed' : 'blocked'} reload/reset reason=$reason '
      'moves=${_gameEngine?.moves.length ?? 0} '
      'fen=${_fenFingerprint(_initialFen)}',
    );
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint('Turbo Chess drill session $_drillSessionId: $message');
      return true;
    }());
  }

  static String _fenFingerprint(String fen) {
    return fen.hashCode.toUnsigned(32).toRadixString(16);
  }

  void _highlightCastlingMove(String kingFrom, String kingTo) {
    final rank = kingFrom[1];
    if (kingTo.startsWith('g')) {
      _extraHighlights = ['h$rank', 'f$rank'];
    } else if (kingTo.startsWith('c')) {
      _extraHighlights = ['a$rank', 'd$rank'];
    } else {
      _extraHighlights = const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_hasActiveAttempt,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleBackToTrainingRequested());
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: DesignSystem.backgroundBase,
          body: AdScreenFrame(
            showTopBanner: false,
            showBottomBanner: false,
            child: SafeArea(
              top: true,
              bottom: false,
              child: _fenErrorMessage != null
                  ? _buildFenErrorState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 980 ||
                            constraints.maxWidth > constraints.maxHeight * 1.15;
                        final horizontalPadding = isWide ? 20.0 : 10.0;
                        final contentWidth =
                            constraints.maxWidth - (horizontalPadding * 2);
                        final bottomInset =
                            MediaQuery.paddingOf(context).bottom;
                        final availableBoardHeight = constraints.maxHeight -
                            bottomInset -
                            (isWide ? 96 : 178);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            16 + bottomInset,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildDrillHeader(compact: true),
                                              const SizedBox(height: 12),
                                              _buildDrillControls(
                                                compact: true,
                                              ),
                                              if (_engineErrorVisible) ...[
                                                const SizedBox(height: 12),
                                                _buildEngineFallbackCard(),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 8,
                                          child: _buildBoardStage(
                                            availableWidth: contentWidth * 0.58,
                                            availableHeight:
                                                availableBoardHeight,
                                            wideLayout: true,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildDrillHeader(),
                                        const SizedBox(height: 8),
                                        _buildBoardStage(
                                          availableWidth: contentWidth,
                                          availableHeight: availableBoardHeight,
                                          wideLayout: false,
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDrillControls(),
                                        if (_engineErrorVisible) ...[
                                          const SizedBox(height: 10),
                                          _buildEngineFallbackCard(),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFenErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DesignSystem.error.withAlpha(90)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DesignSystem.errorLight,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Position unavailable',
                    style: TextStyle(
                      color: DesignSystem.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fenErrorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DesignSystem.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DialogActionButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Back to Training',
                    onPressed: _backToTraining,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrillHeader({bool compact = false}) {
    final title = _isPositionMode
        ? '${widget.positionCategory?.shortTitle ?? widget.screenTitle} '
            'Position $_currentPositionIndex'
        : widget.subtopic;
    final subtitle = widget.screenTitle;
    final statusLabel = _isGameOver
        ? (_gameResult?.reason ?? 'Game over')
        : _engineThinking
            ? 'Engine thinking'
            : '${_sideLabel(_playBoard.turn)} to move';
    final statusColor = _isGameOver
        ? DesignSystem.success
        : _engineThinking
            ? DesignSystem.primaryLight
            : widget.color;
    final statusIcon = _isGameOver
        ? Icons.done_all_rounded
        : _engineThinking
            ? Icons.memory_rounded
            : Icons.circle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeaderIconButton(
              label: 'Back to training',
              icon: Icons.arrow_back_rounded,
              onPressed: () => unawaited(_handleBackToTrainingRequested()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DesignSystem.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildStatusPill(
              label: statusLabel,
              color: statusColor,
              icon: statusIcon,
              child: _engineThinking && !_isGameOver
                  ? _ThinkingDotsText(
                      label: 'Engine thinking',
                      color: statusColor,
                    )
                  : null,
            ),
            _buildStatusPill(
              label: 'You are ${_sideLabel(_userColor)}',
              color: DesignSystem.secondary,
              icon: Icons.person_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoardStage({
    required double availableWidth,
    required double availableHeight,
    required bool wideLayout,
  }) {
    final boardSize = _boardDimensionFor(
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      wideLayout: wideLayout,
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Center(
            child: SizedBox.square(
              dimension: boardSize,
              child: RepaintBoundary(
                child: ChessBoardWidget(
                  board: _playBoard,
                  size: boardSize,
                  onTapSquare: (square) => unawaited(_onTapPlaySquare(square)),
                  selectedSquare: _selectedSquare,
                  legalMoves: _legalMoves,
                  lastMoveFrom: _lastMoveFrom,
                  lastMoveTo: _lastMoveTo,
                  checkSquare: _checkSquare,
                  flipped: _boardFlipped,
                  extraHighlightedSquares: _extraHighlights,
                  lightSquare: _boardLight,
                  darkSquare: _boardDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillControls({bool compact = false}) {
    return Semantics(
      label: 'Drill controls',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignSystem.backgroundRaised.withAlpha(238),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignSystem.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 10),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _EngineProfileButton(
                profile: _engineProfile,
                onPressed: _showEnginePowerSelector,
              ),
              _DrillControlButton(
                label: 'Reset',
                icon: Icons.replay_rounded,
                onPressed: () => unawaited(_confirmResetCurrentDrill()),
              ),
              _DrillControlButton(
                label: 'Flip',
                icon: Icons.flip_rounded,
                onPressed: () {
                  setState(() => _boardFlipped = !_boardFlipped);
                  unawaited(_saveActiveDrillSnapshot(force: true));
                },
              ),
              _DrillControlButton(
                label: _activeBookmark == null ? 'Bookmark' : 'Saved',
                icon: _activeBookmark == null
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_rounded,
                onPressed:
                    _bookmarkBusy ? null : () => unawaited(_toggleBookmark()),
              ),
              _DrillControlButton(
                label: 'Resign',
                icon: Icons.flag_rounded,
                onPressed: _isGameOver ? null : _resign,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineFallbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.warning.withAlpha(14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.warning.withAlpha(64)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.offline_bolt_rounded,
            size: 18,
            color: DesignSystem.warningLight,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stockfish is unavailable, so this drill is using the built-in move fallback.',
              style: TextStyle(
                color: DesignSystem.warningLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          color: DesignSystem.textPrimary,
          style: IconButton.styleFrom(
            backgroundColor: DesignSystem.backgroundRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: DesignSystem.border),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required IconData icon,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          child ??
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
        ],
      ),
    );
  }

  double _boardDimensionFor({
    required double availableWidth,
    required double availableHeight,
    required bool wideLayout,
  }) {
    final widthCap = availableWidth - (wideLayout ? 4.0 : 0.0);
    final heightCap = math.max(260.0, availableHeight);
    final maxSize = wideLayout ? 700.0 : 620.0;
    const minSize = 286.0;
    final dimension = math.min(widthCap, math.min(heightCap, maxSize));
    return math.max(minSize, dimension);
  }

  String _sideLabel(PieceColor color) =>
      color == PieceColor.white ? 'White' : 'Black';
}

class _ThinkingDotsText extends StatefulWidget {
  final String label;
  final Color color;

  const _ThinkingDotsText({
    required this.label,
    required this.color,
  });

  @override
  State<_ThinkingDotsText> createState() => _ThinkingDotsTextState();
}

class _ThinkingDotsTextState extends State<_ThinkingDotsText> {
  Timer? _timer;
  int _dots = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _dots = _dots == 3 ? 1 : _dots + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.label}${List.filled(_dots, '.').join()}',
      style: TextStyle(
        color: widget.color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EngineProfileButton extends StatelessWidget {
  final EnginePowerProfile profile;
  final VoidCallback onPressed;

  const _EngineProfileButton({
    required this.profile,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Engine power ${profile.label}',
      child: SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text('Engine: ${profile.label}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignSystem.textPrimary,
            backgroundColor: DesignSystem.primary.withAlpha(22),
            side: BorderSide(color: DesignSystem.primary.withAlpha(110)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnginePowerSheet extends StatelessWidget {
  final EnginePowerProfile selectedProfile;
  final ValueChanged<EnginePowerProfile> onSelected;

  const _EnginePowerSheet({
    required this.selectedProfile,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.fromBorderSide(
                BorderSide(color: DesignSystem.borderFocus),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + bottomInset),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DesignSystem.borderFocus,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DesignSystem.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DesignSystem.primary.withAlpha(72),
                            ),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            size: 18,
                            color: DesignSystem.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Engine Power',
                            style: TextStyle(
                              color: DesignSystem.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final profile in EnginePowerProfile.values) ...[
                      _EnginePowerOption(
                        profile: profile,
                        selected: profile == selectedProfile,
                        onTap: () => onSelected(profile),
                      ),
                      if (profile != EnginePowerProfile.values.last)
                        const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                    const _MaxEngineInfoLine(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnginePowerOption extends StatelessWidget {
  final EnginePowerProfile profile;
  final bool selected;
  final VoidCallback onTap;

  const _EnginePowerOption({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint =
        selected ? DesignSystem.primaryLight : DesignSystem.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: '${profile.label} ${profile.detailLabel}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? DesignSystem.primary.withAlpha(24)
                : DesignSystem.backgroundElevated.withAlpha(180),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? DesignSystem.primary.withAlpha(128)
                  : DesignSystem.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: tint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesignSystem.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tint.withAlpha(18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: tint.withAlpha(72)),
                          ),
                          child: Text(
                            profile.badgeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tint,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.detailLabel,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: tint,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.supportingText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaxEngineInfoLine extends StatelessWidget {
  const _MaxEngineInfoLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: DesignSystem.warningLight,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Max mode uses deeper Stockfish search. Recommended for powerful phones only.',
            style: TextStyle(
              color: DesignSystem.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrillControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _DrillControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground =
        enabled ? DesignSystem.textPrimary : DesignSystem.textMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            disabledForegroundColor: DesignSystem.textMuted,
            backgroundColor: enabled
                ? DesignSystem.backgroundElevated.withAlpha(205)
                : DesignSystem.backgroundElevated.withAlpha(92),
            side: BorderSide(
              color: enabled
                  ? DesignSystem.borderFocus
                  : DesignSystem.border.withAlpha(150),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

enum _PostGameAction {
  nextDrill,
  retryDrill,
  backToTraining,
  back,
}

class _PostGameResultDialog extends StatelessWidget {
  final GameEndResult result;
  final PieceColor userColor;
  final Color accentColor;
  final bool hasNextDrill;
  final bool isPositionMode;
  final bool isPositionCompleted;
  final ValueChanged<_PostGameAction> onAction;

  const _PostGameResultDialog({
    required this.result,
    required this.userColor,
    required this.accentColor,
    required this.hasNextDrill,
    required this.isPositionMode,
    required this.isPositionCompleted,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 430, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  resultColor.withAlpha(30),
                  DesignSystem.backgroundRaised,
                  DesignSystem.backgroundElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: resultColor.withAlpha(90)),
              boxShadow: [
                ...DesignSystem.shadowLg,
                BoxShadow(
                  color: resultColor.withAlpha(28),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: resultColor.withAlpha(28),
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: resultColor.withAlpha(90)),
                          ),
                          alignment: Alignment.center,
                          child:
                              Icon(_resultIcon, color: resultColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: const TextStyle(
                                  color: DesignSystem.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                result.reason,
                                style: TextStyle(
                                  color: resultColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.message,
                      style: const TextStyle(
                        color: DesignSystem.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPositionMode) ...[
                      const SizedBox(height: 12),
                      _PositionCompletionLine(
                        completed: isPositionCompleted,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (hasNextDrill) ...[
                      PremiumButton(
                        text: isPositionMode ? 'Next Position' : 'Next Drill',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => onAction(_PostGameAction.nextDrill),
                        fullWidth: true,
                        backgroundColor: accentColor,
                        glowColor: accentColor,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _DialogActionButton(
                      icon: Icons.replay_rounded,
                      label: 'Retry Drill',
                      onPressed: () => onAction(_PostGameAction.retryDrill),
                    ),
                    const SizedBox(height: 10),
                    _DialogActionButton(
                      icon: Icons.school_rounded,
                      label: 'Back to Training',
                      onPressed: () => onAction(_PostGameAction.backToTraining),
                    ),
                    const SizedBox(height: 10),
                    _DialogActionButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back',
                      onPressed: () => onAction(_PostGameAction.back),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _userWon =>
      result.winner == (userColor == PieceColor.white ? 'White' : 'Black');

  String get _title {
    if (isPositionMode) {
      return isPositionCompleted ? 'Position completed' : 'Attempt failed';
    }
    if (result.isDraw) return result.reason;
    return _userWon ? 'You Won' : 'You Lost';
  }

  Color get _resultColor {
    if (result.isDraw) return DesignSystem.warningLight;
    return _userWon ? DesignSystem.successLight : DesignSystem.errorLight;
  }

  IconData get _resultIcon {
    if (result.isDraw) return Icons.balance_rounded;
    if (result.reason == 'Checkmate') {
      return _userWon ? Icons.emoji_events_rounded : Icons.gpp_bad_rounded;
    }
    return _userWon ? Icons.flag_rounded : Icons.flag_outlined;
  }
}

class _PositionCompletionLine extends StatelessWidget {
  final bool completed;

  const _PositionCompletionLine({required this.completed});

  @override
  Widget build(BuildContext context) {
    final color =
        completed ? DesignSystem.successLight : DesignSystem.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(completed ? 22 : 12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(completed ? 82 : 42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                completed
                    ? 'Position completed\nProgress saved'
                    : 'Position not completed. Checkmate is required.',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DialogActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignSystem.textPrimary,
          side: const BorderSide(color: DesignSystem.borderFocus),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
