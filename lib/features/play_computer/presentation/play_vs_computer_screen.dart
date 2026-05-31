import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/audio/chess_sound_events.dart';
import '../../../core/audio/turbo_sound_service.dart';
import '../../../core/chess/chess_board.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/chess_rules.dart';
import '../../../core/engine/engine_evaluation.dart';
import '../../../core/engine/engine_manager.dart';
import '../../../core/engine/engine_power_profile.dart';
import '../../../core/engine/play_vs_engine.dart';
import '../../../core/models/play_mode.dart';
import '../../../core/ui/confirm_leave_dialog.dart';
import '../../../core/ui/confirm_resign_dialog.dart';
import '../../../core/ui/promotion_dialog.dart';
import '../data/play_computer_active_game_store.dart';
import '../data/play_computer_history_store.dart';
import '../domain/chess_game_clock.dart';
import '../domain/play_computer_game_record.dart';

enum PlayerColorChoice { white, black, random }

class TimeControlOption {
  final String label;
  final Duration? base;
  final Duration increment;

  const TimeControlOption({
    required this.label,
    required this.base,
    this.increment = Duration.zero,
  });

  const TimeControlOption.noClock({
    required this.label,
  })  : base = null,
        increment = Duration.zero;

  bool get isNoClock => base == null;

  static const noTimeControl = TimeControlOption.noClock(
    label: 'No Time Control',
  );
  static const fiveMinutes = TimeControlOption(
    label: '5 minutes',
    base: Duration(minutes: 5),
  );
  static const defaultOption = fiveMinutes;

  static const timedOptions = [
    TimeControlOption(label: '15 seconds', base: Duration(seconds: 15)),
    TimeControlOption(label: '30 seconds', base: Duration(seconds: 30)),
    TimeControlOption(label: '1 minute', base: Duration(minutes: 1)),
    TimeControlOption(
      label: '1+1',
      base: Duration(minutes: 1),
      increment: Duration(seconds: 1),
    ),
    TimeControlOption(
      label: '2+1',
      base: Duration(minutes: 2),
      increment: Duration(seconds: 1),
    ),
    TimeControlOption(
      label: '3+2',
      base: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    ),
    fiveMinutes,
    TimeControlOption(
      label: '5+5',
      base: Duration(minutes: 5),
      increment: Duration(seconds: 5),
    ),
    TimeControlOption(label: '10 minutes', base: Duration(minutes: 10)),
    TimeControlOption(
      label: '10+5',
      base: Duration(minutes: 10),
      increment: Duration(seconds: 5),
    ),
    TimeControlOption(
      label: '15+10',
      base: Duration(minutes: 15),
      increment: Duration(seconds: 10),
    ),
    TimeControlOption(label: '20 minutes', base: Duration(minutes: 20)),
    TimeControlOption(label: '30 minutes', base: Duration(minutes: 30)),
    TimeControlOption(label: '60 minutes', base: Duration(minutes: 60)),
  ];

  static const options = [
    noTimeControl,
    ...timedOptions,
  ];
}

typedef PlayEvaluationProvider = Future<int?> Function(String fen, int depth);

class PlayVsComputerScreen extends StatefulWidget {
  final String? initialFen;
  final EngineMoveProvider? engineMoveProvider;
  final PlayEvaluationProvider? evaluationProvider;
  final bool resumeActiveOnOpen;

  const PlayVsComputerScreen({
    super.key,
    this.initialFen,
    this.engineMoveProvider,
    this.evaluationProvider,
    this.resumeActiveOnOpen = false,
  });

  @override
  State<PlayVsComputerScreen> createState() => _PlayVsComputerScreenState();
}

class _PlayVsComputerScreenState extends State<PlayVsComputerScreen>
    with WidgetsBindingObserver {
  static const Color _boardLight = Color(0xFFE6D8BD);
  static const Color _boardDark = Color(0xFF5E7C66);
  static const int _maxPowerDepth = 20;
  static const int _maxPowerMoveTimeMs = 3000;
  static const int _maxPowerSkillLevel = 20;
  static const int _maxPowerThreads = 2;
  static const int _maxPowerHashMb = 64;

  final TextEditingController _fenController = TextEditingController();
  final PlayComputerHistoryStore _historyStore =
      const PlayComputerHistoryStore();
  final PlayComputerActiveGameStore _activeGameStore =
      const PlayComputerActiveGameStore();
  final TurboSoundService _soundService = TurboSoundService.instance;

  PlayerColorChoice _colorChoice = PlayerColorChoice.white;
  bool _timeControlEnabled = false;
  TimeControlOption _timeControl = TimeControlOption.noTimeControl;
  TimeControlOption _lastTimedTimeControl = TimeControlOption.defaultOption;
  bool _usePastedFen = false;
  String? _fenError;
  PieceColor? _pastedSideToMove;

  EnginePowerProfile _engineProfile = EnginePowerProfile.strong;
  int _depth = 12;
  int _moveTimeMs = 800;
  int _skillLevel = 20;
  int _threads = 1;
  int _hashMb = 32;
  bool _maxPowerEnabled = false;
  EnginePowerProfile _savedEngineProfile = EnginePowerProfile.strong;
  int _savedDepth = 12;
  int _savedMoveTimeMs = 800;
  int _savedSkillLevel = 20;
  int _savedThreads = 1;
  int _savedHashMb = 32;

  bool _showEvaluation = false;
  bool _showSuggestion = false;
  bool _showMoveFeedback = false;
  bool _showLegalMoves = true;
  bool _showLastMove = true;

  bool _inGame = false;
  bool _engineThinking = false;
  bool _gameOver = false;
  bool _boardFlipped = false;
  bool _resultDialogVisible = false;
  bool _leaveDialogVisible = false;
  bool _leavingAfterResign = false;
  bool _suppressResultDialog = false;
  bool _gameRecordSaved = false;
  String _currentInitialFen = ChessBoard.standardStartingFen;
  PieceColor _userColor = PieceColor.white;
  ChessBoard _board = ChessBoard.starting();
  PlayVsEngine? _game;
  EngineSearchConfig? _currentEngineConfig;
  ChessGameClock? _clock;
  Timer? _clockTimer;
  DateTime? _lastTick;
  bool _engineClockExpiredThisTurn = false;
  DateTime? _gameStartedAt;
  String? _selectedSquare;
  List<String> _legalMoves = const [];
  String? _lastMoveFrom;
  String? _lastMoveTo;
  String? _checkSquare;
  String? _resultMessage;
  String? _moveFeedback;
  int? _evaluationCp;
  String? _suggestionMove;
  int _analysisToken = 0;
  DateTime? _lastSnapshotWriteAt;
  PlayComputerGameRecord? _lastSavedRecord;
  Future<PlayComputerGameRecord?>? _finishGameFuture;

  bool get _hasActiveGame {
    final game = _game;
    return _inGame &&
        game != null &&
        !_gameOver &&
        !game.isGameOver &&
        !_resultDialogVisible &&
        !_leavingAfterResign;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_soundService.initialize());
    final initialFen = widget.initialFen;
    if (initialFen != null) {
      final board = ChessBoard.tryFromFen(initialFen);
      _usePastedFen = true;
      _fenController.text = initialFen;
      _pastedSideToMove = board?.turn;
      _fenError = board == null ? 'Enter a valid standard chess FEN.' : null;
      if (board != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startGame();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.resumeActiveOnOpen) {
          unawaited(_restoreActiveGameFromStore());
        } else {
          unawaited(_offerActiveGameRestore());
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveActiveGameSnapshot());
    _clockTimer?.cancel();
    _game?.dispose();
    _fenController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveActiveGameSnapshot(force: true));
    }
  }

  void _validateFenInput() {
    if (!_usePastedFen) {
      setState(() {
        _fenError = null;
        _pastedSideToMove = null;
      });
      return;
    }
    final board = ChessBoard.tryFromFen(_fenController.text);
    setState(() {
      _fenError = board == null ? 'Enter a valid standard chess FEN.' : null;
      _pastedSideToMove = board?.turn;
    });
  }

  EngineSearchConfig _engineConfig({bool light = false}) {
    if (_maxPowerEnabled) {
      final moveTime = light ? 350 : _maxPowerMoveTimeMs;
      return EngineSearchConfig(
        profile: EnginePowerProfile.max,
        depth: light ? 8 : _maxPowerDepth,
        skillLevel: _maxPowerSkillLevel,
        limitStrength: false,
        ponder: false,
        threads: light ? 1 : _maxPowerThreads,
        hashMb: _maxPowerHashMb,
        timeout: Duration(milliseconds: moveTime + 3500),
        moveTimeMs: moveTime,
      );
    }

    final depth = light ? math.min(_depth, 8) : _depth;
    final moveTime = light ? math.min(_moveTimeMs, 350) : _moveTimeMs;
    return EngineSearchConfig(
      profile: _engineProfile,
      depth: depth.clamp(1, 20).toInt(),
      skillLevel: _skillLevel.clamp(0, 20).toInt(),
      limitStrength: _skillLevel < 20,
      ponder: false,
      threads: _threads.clamp(1, 2).toInt(),
      hashMb: _hashMb.clamp(16, 64).toInt(),
      timeout: Duration(milliseconds: moveTime + 3000),
      moveTimeMs: moveTime,
    );
  }

  void _resetRecommendedEngineSettings() {
    setState(() {
      _maxPowerEnabled = false;
      _engineProfile = EnginePowerProfile.strong;
      _depth = 12;
      _moveTimeMs = 800;
      _skillLevel = 20;
      _threads = 1;
      _hashMb = 32;
    });
  }

  void _setMaxPower(bool enabled) {
    setState(() {
      if (enabled) {
        if (!_maxPowerEnabled) {
          _savedEngineProfile = _engineProfile;
          _savedDepth = _depth;
          _savedMoveTimeMs = _moveTimeMs;
          _savedSkillLevel = _skillLevel;
          _savedThreads = _threads;
          _savedHashMb = _hashMb;
        }
        _maxPowerEnabled = true;
        _engineProfile = EnginePowerProfile.max;
        _depth = _maxPowerDepth;
        _moveTimeMs = _maxPowerMoveTimeMs;
        _skillLevel = _maxPowerSkillLevel;
        _threads = _maxPowerThreads;
        _hashMb = _maxPowerHashMb;
      } else {
        _maxPowerEnabled = false;
        _engineProfile = _savedEngineProfile;
        _depth = _savedDepth;
        _moveTimeMs = _savedMoveTimeMs;
        _skillLevel = _savedSkillLevel;
        _threads = _savedThreads;
        _hashMb = _savedHashMb;
      }
    });
  }

  void _startGame() {
    final fen = _usePastedFen
        ? _fenController.text.trim()
        : ChessBoard.standardStartingFen;
    final startingBoard = ChessBoard.tryFromFen(fen);
    if (startingBoard == null) {
      setState(() {
        _fenError = 'Enter a valid standard chess FEN.';
      });
      return;
    }

    final chosenColor = switch (_colorChoice) {
      PlayerColorChoice.white => PieceColor.white,
      PlayerColorChoice.black => PieceColor.black,
      PlayerColorChoice.random =>
        math.Random().nextBool() ? PieceColor.white : PieceColor.black,
    };

    _game?.dispose();
    _clockTimer?.cancel();
    final engineConfig = _engineConfig();
    final game = PlayVsEngine(
      startingFen: fen,
      userColor: chosenColor,
      engineProfile: engineConfig.profile,
      engineConfig: engineConfig,
      engineMoveProvider: widget.engineMoveProvider,
    );

    _attachGameCallbacks(game);

    setState(() {
      _game = game;
      _currentEngineConfig = engineConfig;
      _board = startingBoard;
      _currentInitialFen = fen;
      _userColor = chosenColor;
      _boardFlipped = chosenColor == PieceColor.black;
      _clock = _timeControl.isNoClock
          ? null
          : ChessGameClock(
              initialWhite: _timeControl.base!,
              initialBlack: _timeControl.base!,
              increment: _timeControl.increment,
              activeSide: startingBoard.turn,
            );
      _gameStartedAt = DateTime.now();
      _lastSavedRecord = null;
      _gameRecordSaved = false;
      _finishGameFuture = null;
      _engineClockExpiredThisTurn = false;
      _resultDialogVisible = false;
      _leaveDialogVisible = false;
      _leavingAfterResign = false;
      _suppressResultDialog = false;
      _selectedSquare = null;
      _legalMoves = const [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _checkSquare = null;
      _resultMessage = null;
      _moveFeedback = null;
      _evaluationCp = null;
      _suggestionMove = null;
      _engineThinking = false;
      _gameOver = false;
      _inGame = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_game, game)) return;
      if (_clock != null) {
        _clock?.start(startingBoard.turn);
        _startClockTimer();
      }
      game.start();
      unawaited(_saveActiveGameSnapshot(force: true));
    });
  }

  void _attachGameCallbacks(PlayVsEngine game) {
    game.onBoardUpdate = (board, state) {
      if (!mounted || !identical(_game, game)) return;
      setState(() {
        _board = board;
        _engineThinking = state == PlayState.engineThinking;
        _gameOver = state == PlayState.gameOver || _gameOver;
        _checkSquare = ChessRules.isKingInCheck(board, board.turn)
            ? ChessRules.findKingSquare(board, board.turn)
            : null;
        if (state != PlayState.userTurn) {
          _suggestionMove = null;
        }
      });
      if (state == PlayState.gameOver) {
        _clock?.stop();
        _clockTimer?.cancel();
      } else {
        _clock?.activeSide = board.turn;
      }
      unawaited(_saveActiveGameSnapshot(force: true));
      _refreshHelpers();
    };

    game.onMoveMade = (moveUci) {
      if (!mounted || !identical(_game, game) || moveUci.length < 4) return;
      final mover = _opposite(game.board.turn);
      _clock?.applyMove(mover: mover, nextTurn: game.board.turn);
      _engineClockExpiredThisTurn = false;
      setState(() {
        _lastMoveFrom = moveUci.substring(0, 2);
        _lastMoveTo = moveUci.substring(2, 4);
        _selectedSquare = null;
        _legalMoves = const [];
        _moveFeedback = '${_sideLabel(mover)} played $moveUci';
        _suggestionMove = null;
      });
      unawaited(_saveActiveGameSnapshot(force: true));
      _playSoundForLatestMove(game);
    };

    game.onGameOver = (result) {
      if (!mounted || !identical(_game, game)) return;
      _clock?.stop();
      _clockTimer?.cancel();
      setState(() {
        _gameOver = true;
        _engineThinking = false;
        _resultMessage = result.message;
      });
      _soundService.playGameOver();
      final finishFuture = _finishGame(result, game);
      _finishGameFuture = finishFuture;
      unawaited(finishFuture);
    };
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _lastTick = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final clock = _clock;
      if (clock == null || !clock.running || _gameOver) return;
      final now = DateTime.now();
      final elapsed = now.difference(_lastTick ?? now);
      _lastTick = now;
      final timeout = clock.tickPlayVsComputer(
        elapsed: elapsed,
        userColor: _userColor,
      );
      if (timeout != null) {
        _handleTimeout(timeout.side);
      } else if (mounted) {
        setState(() {});
        unawaited(_saveActiveGameSnapshot());
      }
    });
  }

  void _handleTimeout(PieceColor side) {
    if (side != _userColor) {
      if (!_engineClockExpiredThisTurn) {
        _engineClockExpiredThisTurn = true;
        _game?.requestImmediateEngineMove();
      }
      if (_clock != null) {
        _clock!.activeSide = side;
        _clock!.running = true;
      }
      if (mounted) setState(() {});
      return;
    }
    _clock?.stop();
    _clockTimer?.cancel();
    final game = _game;
    game?.dispose();
    final winner = _opposite(side);
    final result = GameEndResult(
      reason: 'Timeout',
      winner: _sideLabel(winner),
      message:
          '${_sideLabel(winner)} wins on time. ${_sideLabel(side)} flagged.',
    );
    if (!mounted) return;
    setState(() {
      _gameOver = true;
      _engineThinking = false;
      _resultMessage = result.message;
      _selectedSquare = null;
      _legalMoves = const [];
    });
    _soundService.playGameOver();
    if (game != null) {
      unawaited(_finishGame(result, game));
    }
  }

  Future<void> _onTapSquare(String square) async {
    final game = _game;
    if (game == null || _gameOver || _engineThinking) return;
    if (game.state != PlayState.userTurn) return;

    if (_selectedSquare == null) {
      final moves = game.getLegalMovesFrom(square);
      if (moves.isEmpty) return;
      setState(() {
        _selectedSquare = square;
        _legalMoves = moves;
      });
      _soundService.playTap();
      return;
    }

    if (_legalMoves.contains(square)) {
      final from = _selectedSquare!;
      final piece = _board.pieces[from];
      String? promotion;
      if (piece?.type == PieceType.pawn) {
        final toRank = int.tryParse(square[1]) ?? 0;
        final promotes = (piece!.color == PieceColor.white && toRank == 8) ||
            (piece.color == PieceColor.black && toRank == 1);
        if (promotes) {
          promotion = await PromotionDialog.show(context, piece.color);
          if (!mounted || promotion == null) {
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
      await game.userMove(from, square, promotion: promotion);
      return;
    }

    final moves = game.getLegalMovesFrom(square);
    setState(() {
      _selectedSquare = moves.isEmpty ? null : square;
      _legalMoves = moves;
    });
  }

  void _playSoundForLatestMove(PlayVsEngine game) {
    Future.microtask(() {
      if (!mounted || !identical(_game, game)) return;
      if (game.isGameOver) return;
      final move = game.moves.isEmpty ? null : game.moves.last;
      if (move == null) return;
      _soundService.playEvent(
        soundEventForCompletedMove(boardAfter: game.board, move: move),
      );
    });
  }

  Future<void> _resign() async {
    if (_gameOver) return;
    final shouldResign = await ConfirmResignDialog.show(context);
    if (!mounted || !shouldResign) return;
    _clock?.stop();
    _game?.resign();
  }

  Future<void> _handleBackOrCloseRequested() async {
    if (!_hasActiveGame) {
      if (!mounted) return;
      await Navigator.maybePop(context);
      return;
    }

    if (_leaveDialogVisible || _leavingAfterResign) return;
    _leaveDialogVisible = true;
    final shouldLeave = await ConfirmLeaveDialog.show(
      context,
      title: 'Resign game?',
      message:
          'You are currently playing against the computer. If you leave now, this game will end as a resignation.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Resign & Leave',
      icon: Icons.flag_rounded,
    );
    _leaveDialogVisible = false;
    if (!mounted || !shouldLeave) return;
    await _resignAndLeave();
  }

  Future<void> _resignAndLeave() async {
    if (_leavingAfterResign) return;
    final game = _game;
    if (game == null || _gameOver || game.isGameOver) {
      if (!mounted) return;
      await Navigator.maybePop(context);
      return;
    }

    _leavingAfterResign = true;
    _suppressResultDialog = true;
    _clock?.stop();
    _clockTimer?.cancel();
    game.resign();
    final finishFuture = _finishGameFuture;
    if (finishFuture != null) {
      await finishFuture;
    }
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    _newGame();
  }

  void _resetGame() {
    _fenController.text = _currentInitialFen;
    _usePastedFen = _currentInitialFen != ChessBoard.standardStartingFen;
    _startGame();
  }

  void _newGame() {
    _game?.dispose();
    _clockTimer?.cancel();
    unawaited(_activeGameStore.clear());
    setState(() {
      _inGame = false;
      _gameOver = false;
      _engineThinking = false;
      _selectedSquare = null;
      _legalMoves = const [];
      _resultMessage = null;
      _lastSavedRecord = null;
      _gameRecordSaved = false;
      _finishGameFuture = null;
      _engineClockExpiredThisTurn = false;
      _gameStartedAt = null;
      _currentEngineConfig = null;
      _leaveDialogVisible = false;
      _leavingAfterResign = false;
      _suppressResultDialog = false;
    });
  }

  Future<void> _offerActiveGameRestore() async {
    if (_inGame || widget.initialFen != null) return;
    final hasRawSave = await _activeGameStore.hasSavedSnapshotData();
    final snapshot = await _activeGameStore.load();
    if (!mounted) return;
    if (snapshot == null) {
      if (hasRawSave) {
        await _offerUnusableActiveGameDiscard();
      }
      return;
    }

    final action = await showDialog<_ActiveGameRestoreAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume unfinished game?'),
        content: const Text(
          'You have an unfinished game against the computer.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('discard_active_play_game'),
            onPressed: () =>
                Navigator.of(context).pop(_ActiveGameRestoreAction.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            key: const ValueKey('resume_active_play_game'),
            onPressed: () =>
                Navigator.of(context).pop(_ActiveGameRestoreAction.resume),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == _ActiveGameRestoreAction.discard) {
      await _activeGameStore.clear();
      return;
    }
    if (action == _ActiveGameRestoreAction.resume) {
      _restoreActiveGame(snapshot);
    }
  }

  Future<void> _offerUnusableActiveGameDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume unfinished game?'),
        content: const Text('This unfinished game cannot be restored.'),
        actions: [
          FilledButton(
            key: const ValueKey('discard_active_play_game'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (discard == true) {
      await _activeGameStore.clear();
    }
  }

  Future<void> _restoreActiveGameFromStore() async {
    if (_inGame || widget.initialFen != null) return;
    final hasRawSave = await _activeGameStore.hasSavedSnapshotData();
    final snapshot = await _activeGameStore.load();
    if (!mounted) return;
    if (snapshot == null) {
      if (hasRawSave) {
        await _offerUnusableActiveGameDiscard();
      }
      return;
    }
    _restoreActiveGame(snapshot);
  }

  void _restoreActiveGame(PlayComputerActiveGameSnapshot snapshot) {
    final board = ChessBoard.tryFromFen(snapshot.currentFen);
    if (board == null) {
      unawaited(_activeGameStore.clear());
      return;
    }

    _game?.dispose();
    _clockTimer?.cancel();
    final profile = EnginePowerProfile.fromId(snapshot.engineProfileId);
    final engineConfig = EngineSearchConfig(
      profile: profile,
      depth: snapshot.engineDepth,
      skillLevel: snapshot.engineSkill,
      limitStrength: snapshot.engineSkill < 20,
      ponder: false,
      threads: snapshot.engineThreads,
      hashMb: snapshot.engineHashMb,
      timeout: Duration(milliseconds: snapshot.engineMoveTimeMs + 3000),
      moveTimeMs: snapshot.engineMoveTimeMs,
    );
    final game = PlayVsEngine.restored(
      startingFen: snapshot.startingFen,
      currentFen: snapshot.currentFen,
      moves: snapshot.moves,
      userColor: snapshot.userColor,
      engineProfile: engineConfig.profile,
      engineConfig: engineConfig,
      engineMoveProvider: widget.engineMoveProvider,
    );
    _attachGameCallbacks(game);

    final restoredTimeControl = _timeControlFromSnapshot(snapshot);
    final restoredClock = snapshot.noTimeControl
        ? null
        : ChessGameClock(
            initialWhite:
                Duration(milliseconds: snapshot.whiteRemainingMs ?? 0),
            initialBlack:
                Duration(milliseconds: snapshot.blackRemainingMs ?? 0),
            increment: Duration(
              milliseconds: snapshot.timeControlIncrementMs,
            ),
            activeSide: _pieceColorFromName(
              snapshot.clockActiveSide,
              fallback: board.turn,
            ),
            running: snapshot.clockRunning,
          );

    setState(() {
      _game = game;
      _currentEngineConfig = engineConfig;
      _board = board;
      _currentInitialFen = snapshot.startingFen;
      _userColor = snapshot.userColor;
      _colorChoice = snapshot.userColor == PieceColor.white
          ? PlayerColorChoice.white
          : PlayerColorChoice.black;
      _boardFlipped = snapshot.boardFlipped;
      _timeControl = restoredTimeControl;
      _lastTimedTimeControl = restoredTimeControl.isNoClock
          ? _lastTimedTimeControl
          : restoredTimeControl;
      _timeControlEnabled = snapshot.timeControlEnabled;
      _clock = restoredClock;
      _engineProfile = profile;
      _depth = snapshot.engineDepth;
      _moveTimeMs = snapshot.engineMoveTimeMs;
      _skillLevel = snapshot.engineSkill;
      _threads = snapshot.engineThreads;
      _hashMb = snapshot.engineHashMb;
      _maxPowerEnabled = snapshot.maxPowerEnabled;
      _gameStartedAt = snapshot.startedAt;
      _lastSavedRecord = null;
      _gameRecordSaved = false;
      _finishGameFuture = null;
      _engineClockExpiredThisTurn = false;
      _resultDialogVisible = false;
      _leaveDialogVisible = false;
      _leavingAfterResign = false;
      _suppressResultDialog = false;
      _selectedSquare = null;
      _legalMoves = const [];
      final lastMove = snapshot.moves.isEmpty ? null : snapshot.moves.last.move;
      _lastMoveFrom = lastMove == null || lastMove.length < 4
          ? null
          : lastMove.substring(0, 2);
      _lastMoveTo = lastMove == null || lastMove.length < 4
          ? null
          : lastMove.substring(2, 4);
      _checkSquare = ChessRules.isKingInCheck(board, board.turn)
          ? ChessRules.findKingSquare(board, board.turn)
          : null;
      _resultMessage = null;
      _moveFeedback = snapshot.moves.isEmpty
          ? null
          : '${snapshot.moves.last.isUser ? 'You' : 'Engine'} played ${snapshot.moves.last.move}';
      _evaluationCp = null;
      _suggestionMove = null;
      _engineThinking = game.state == PlayState.engineThinking;
      _gameOver = false;
      _inGame = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_game, game)) return;
      if (_clock?.running == true) _startClockTimer();
      game.resumeRestored();
      unawaited(_saveActiveGameSnapshot(force: true));
    });
  }

  TimeControlOption _timeControlFromSnapshot(
    PlayComputerActiveGameSnapshot snapshot,
  ) {
    if (snapshot.noTimeControl || snapshot.timeControlBaseMs == null) {
      return TimeControlOption.noTimeControl;
    }
    for (final option in TimeControlOption.options) {
      if (option.label == snapshot.timeControlLabel) return option;
    }
    return TimeControlOption(
      label: snapshot.timeControlLabel,
      base: Duration(milliseconds: snapshot.timeControlBaseMs!),
      increment: Duration(milliseconds: snapshot.timeControlIncrementMs),
    );
  }

  Future<void> _saveActiveGameSnapshot({bool force = false}) async {
    final game = _game;
    if (!_inGame || game == null || _gameOver || game.isGameOver) return;
    final now = DateTime.now();
    if (!force &&
        _lastSnapshotWriteAt != null &&
        now.difference(_lastSnapshotWriteAt!) <
            const Duration(milliseconds: 900)) {
      return;
    }
    _lastSnapshotWriteAt = now;
    final clock = _clock;
    final snapshot = PlayComputerActiveGameSnapshot(
      startedAt: _gameStartedAt ?? now,
      updatedAt: now,
      startingFen: _currentInitialFen,
      currentFen: game.board.toFen(),
      userColor: _userColor,
      engineColor: _opposite(_userColor),
      engineProfileId: (_currentEngineConfig ?? _engineConfig()).profile.id,
      engineDepth: (_currentEngineConfig ?? _engineConfig()).depth,
      engineSkill: (_currentEngineConfig ?? _engineConfig()).skillLevel,
      engineMoveTimeMs:
          (_currentEngineConfig ?? _engineConfig()).moveTimeMs ?? _moveTimeMs,
      engineThreads: (_currentEngineConfig ?? _engineConfig()).threads,
      engineHashMb: (_currentEngineConfig ?? _engineConfig()).hashMb,
      maxPowerEnabled: _maxPowerEnabled,
      boardFlipped: _boardFlipped,
      timeControlLabel: _timeControl.label,
      timeControlEnabled: _timeControlEnabled,
      noTimeControl: _timeControl.isNoClock,
      timeControlBaseMs: _timeControl.base?.inMilliseconds,
      timeControlIncrementMs: _timeControl.increment.inMilliseconds,
      whiteRemainingMs: clock?.whiteRemaining.inMilliseconds,
      blackRemainingMs: clock?.blackRemaining.inMilliseconds,
      clockActiveSide: clock?.activeSide.name,
      clockRunning: clock?.running ?? false,
      moves: game.moves,
    );
    await _activeGameStore.save(snapshot);
  }

  Future<void> _refreshHelpers() async {
    if (!_inGame) return;
    if (!_showEvaluation && !_showSuggestion) return;
    final token = ++_analysisToken;
    final fen = _board.toFen();
    if (_showEvaluation) {
      final eval = await (widget.evaluationProvider?.call(fen, 8) ??
          EngineManager().getEvaluation(fen, depth: 8));
      if (!mounted || token != _analysisToken || _board.toFen() != fen) return;
      setState(() => _evaluationCp = eval);
    }
    if (_showSuggestion && _game?.state == PlayState.userTurn) {
      final move = await EngineManager().getBestMoveWithConfig(
        fen,
        _engineConfig(light: true),
      );
      if (!mounted || token != _analysisToken || _board.toFen() != fen) return;
      setState(() => _suggestionMove = move);
    }
  }

  Future<PlayComputerGameRecord?> _finishGame(
    GameEndResult result,
    PlayVsEngine game,
  ) async {
    if (_gameRecordSaved) {
      final record = _lastSavedRecord;
      if (record != null && !_suppressResultDialog) {
        await _showGameResultDialog(record);
      }
      return record;
    }

    _gameRecordSaved = true;
    final endedAt = DateTime.now();
    final recordEngineConfig = _currentEngineConfig ?? _engineConfig();
    final record = PlayComputerGameRecord(
      id: 'play_${endedAt.microsecondsSinceEpoch}',
      startedAt: _gameStartedAt ?? endedAt,
      endedAt: endedAt,
      userColor: _userColor,
      engineColor: _opposite(_userColor),
      result: PlayComputerGameRecord.resultCodeFor(result, _userColor),
      resultText: result.message,
      resultReason: result.reason,
      winner: result.winner,
      timeControlLabel: _timeControl.label,
      noTimeControl: _timeControl.isNoClock,
      engineProfileName: recordEngineConfig.profile.label,
      engineDepth: recordEngineConfig.depth,
      engineSkill: recordEngineConfig.skillLevel,
      engineMoveTimeMs: recordEngineConfig.moveTimeMs ?? _moveTimeMs,
      startingFen: _currentInitialFen,
      finalFen: game.board.toFen(),
      moveCount: game.moves.length,
      moves: game.moves,
    );

    await _historyStore.saveRecord(record);
    await _activeGameStore.clear();
    if (!mounted) return record;
    setState(() {
      _lastSavedRecord = record;
    });
    if (!_suppressResultDialog) {
      await _showGameResultDialog(record);
    }
    return record;
  }

  Future<void> _showGameResultDialog(PlayComputerGameRecord record) async {
    if (_resultDialogVisible || !mounted) return;
    _resultDialogVisible = true;
    final action = await showDialog<_PlayGameResultAction>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PlayGameResultDialog(
        record: record,
        onAction: (action) => Navigator.pop(context, action),
      ),
    );
    _resultDialogVisible = false;
    if (!mounted) return;

    switch (action) {
      case _PlayGameResultAction.newGame:
        _newGame();
        break;
      case _PlayGameResultAction.viewHistory:
        await Navigator.pushNamed(context, '/play/history');
        break;
      case _PlayGameResultAction.close:
      case null:
        break;
    }
  }

  Future<void> _openHistory() async {
    await Navigator.pushNamed(context, '/play/history');
  }

  @override
  Widget build(BuildContext context) {
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;

    return PopScope<Object?>(
      canPop: !_hasActiveGame,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleBackOrCloseRequested());
      },
      child: Scaffold(
        backgroundColor: DesignSystem.backgroundBase,
        appBar: AppBar(
          leading: routeCanPop
              ? IconButton(
                  key: const ValueKey('play_back_button'),
                  tooltip: 'Back',
                  onPressed: () => unawaited(_handleBackOrCloseRequested()),
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          title: Text(_inGame ? 'Play vs Computer' : 'Computer Setup'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              key: const ValueKey('play_history_button'),
              tooltip: 'Play history',
              onPressed: () => unawaited(_openHistory()),
              icon: const Icon(Icons.history_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: AdScreenFrame(
          showTopBanner: !_inGame,
          showBottomBanner: false,
          child: SafeArea(
            top: false,
            child: _inGame ? _buildGame() : _buildSetup(),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return ListView(
      key: const ValueKey('play_setup_list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _Section(
          title: 'Color',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choiceChip('White', PlayerColorChoice.white),
              _choiceChip('Black', PlayerColorChoice.black),
              _choiceChip('Random', PlayerColorChoice.random),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Time Control',
          child: _buildTimeControlSelector(),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Start Position',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paste FEN'),
                subtitle: Text(
                  _pastedSideToMove == null
                      ? 'Normal starting position is used when off.'
                      : '${_sideLabel(_pastedSideToMove!)} to move',
                ),
                value: _usePastedFen,
                onChanged: (value) {
                  setState(() => _usePastedFen = value);
                  _validateFenInput();
                },
              ),
              if (_usePastedFen) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _fenController,
                  minLines: 2,
                  maxLines: 3,
                  onChanged: (_) => _validateFenInput(),
                  decoration: InputDecoration(
                    hintText: ChessBoard.standardStartingFen,
                    errorText: _fenError,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(title: 'Engine', child: _buildEngineSettings()),
        const SizedBox(height: 12),
        _Section(title: 'Helpers', child: _buildHelperToggles()),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('start_computer_game'),
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Game'),
        ),
      ],
    );
  }

  Widget _choiceChip(String label, PlayerColorChoice choice) {
    return ChoiceChip(
      label: Text(label),
      selected: _colorChoice == choice,
      onSelected: (_) => setState(() => _colorChoice = choice),
    );
  }

  Widget _buildTimeControlSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('time_control_toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Time Control'),
          value: _timeControlEnabled,
          onChanged: (value) {
            setState(() {
              _timeControlEnabled = value;
              if (value) {
                _timeControl = _lastTimedTimeControl;
              } else {
                if (!_timeControl.isNoClock) {
                  _lastTimedTimeControl = _timeControl;
                }
                _timeControl = TimeControlOption.noTimeControl;
              }
            });
          },
        ),
        if (_timeControlEnabled) ...[
          const SizedBox(height: 8),
          Wrap(
            key: const ValueKey('time_control_presets'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in TimeControlOption.timedOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: identical(_timeControl, option),
                  onSelected: (_) {
                    setState(() {
                      _timeControl = option;
                      _lastTimedTimeControl = option;
                    });
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEngineSettings() {
    final controlsEnabled = !_maxPowerEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('max_power_panel'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _maxPowerEnabled
                ? DesignSystem.warning.withAlpha(22)
                : DesignSystem.backgroundElevated.withAlpha(170),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _maxPowerEnabled
                  ? DesignSystem.warningLight.withAlpha(130)
                  : DesignSystem.border,
            ),
          ),
          child: SwitchListTile.adaptive(
            key: const ValueKey('max_power_toggle'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.bolt_rounded,
              color: _maxPowerEnabled
                  ? DesignSystem.warningLight
                  : DesignSystem.textMuted,
            ),
            title: const Text(
              'Max Power',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text(
              'Recommended for powerful phones only. Uses more battery and processing power.',
            ),
            value: _maxPowerEnabled,
            onChanged: _setMaxPower,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<EnginePowerProfile>(
          initialValue: _engineProfile,
          decoration: const InputDecoration(labelText: 'Strength profile'),
          items: [
            for (final profile in EnginePowerProfile.values)
              DropdownMenuItem(value: profile, child: Text(profile.label)),
          ],
          onChanged: controlsEnabled
              ? (value) {
                  if (value != null) setState(() => _engineProfile = value);
                }
              : null,
        ),
        _slider(
          label: 'Depth',
          value: _depth.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          display: '$_depth',
          onChanged: controlsEnabled
              ? (value) => setState(() => _depth = value.round())
              : null,
        ),
        _slider(
          label: 'Move time',
          value: _moveTimeMs.toDouble(),
          min: 200,
          max: 3000,
          divisions: 14,
          display: '${_moveTimeMs}ms',
          onChanged: controlsEnabled
              ? (value) => setState(() => _moveTimeMs = value.round())
              : null,
        ),
        _slider(
          label: 'Skill',
          value: _skillLevel.toDouble(),
          min: 0,
          max: 20,
          divisions: 20,
          display: '$_skillLevel',
          onChanged: controlsEnabled
              ? (value) => setState(() => _skillLevel = value.round())
              : null,
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _threads,
                decoration: const InputDecoration(labelText: 'Threads'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                ],
                onChanged: controlsEnabled
                    ? (value) {
                        if (value != null) setState(() => _threads = value);
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _hashMb,
                decoration: const InputDecoration(labelText: 'Hash'),
                items: const [
                  DropdownMenuItem(value: 16, child: Text('16 MB')),
                  DropdownMenuItem(value: 32, child: Text('32 MB')),
                  DropdownMenuItem(value: 64, child: Text('64 MB')),
                ],
                onChanged: controlsEnabled
                    ? (value) {
                        if (value != null) setState(() => _hashMb = value);
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _maxPowerEnabled ? null : _resetRecommendedEngineSettings,
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Recommended settings'),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          '$label: $display',
          style: const TextStyle(
            color: DesignSystem.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHelperToggles() {
    return Column(
      children: [
        _toggle('Legal move highlights', _showLegalMoves,
            (value) => setState(() => _showLegalMoves = value)),
        _toggle('Last move highlight', _showLastMove,
            (value) => setState(() => _showLastMove = value)),
        _toggle('Evaluation bar', _showEvaluation, (value) {
          setState(() => _showEvaluation = value);
          _refreshHelpers();
        }),
        _toggle('Suggestion', _showSuggestion, (value) {
          setState(() => _showSuggestion = value);
          _refreshHelpers();
        }),
        _toggle('Move feedback', _showMoveFeedback,
            (value) => setState(() => _showMoveFeedback = value)),
      ],
    );
  }

  Widget _toggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildGame() {
    final clock = _clock;
    final suggestionMove = _suggestionMove;
    final suggestionFrom =
        _showSuggestion && suggestionMove != null && suggestionMove.length >= 4
            ? suggestionMove.substring(0, 2)
            : null;
    final suggestionTo =
        _showSuggestion && suggestionMove != null && suggestionMove.length >= 4
            ? suggestionMove.substring(2, 4)
            : null;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (clock != null)
          Row(
            children: [
              Expanded(
                child: _ClockPill(
                  label: 'White',
                  duration: clock.whiteRemaining,
                  active: clock.running && clock.activeSide == PieceColor.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ClockPill(
                  label: 'Black',
                  duration: clock.blackRemaining,
                  active: clock.running && clock.activeSide == PieceColor.black,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        Center(
          child: _BoardWithEvaluationBar(
            showEvaluation: _showEvaluation,
            centipawns: _evaluationCp,
            boardBuilder: (boardSize) {
              return ChessBoardWidget(
                key: const ValueKey('play_chess_board_area'),
                board: _board,
                size: boardSize,
                onTapSquare: (square) => unawaited(_onTapSquare(square)),
                selectedSquare: _selectedSquare,
                legalMoves: _showLegalMoves ? _legalMoves : const [],
                lastMoveFrom: _showLastMove ? _lastMoveFrom : null,
                lastMoveTo: _showLastMove ? _lastMoveTo : null,
                suggestedMoveFrom: suggestionFrom,
                suggestedMoveTo: suggestionTo,
                checkSquare: _checkSquare,
                flipped: _boardFlipped,
                lightSquare: _boardLight,
                darkSquare: _boardDark,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _controlButton(
              'Flip',
              Icons.flip_rounded,
              () {
                setState(() => _boardFlipped = !_boardFlipped);
                unawaited(_saveActiveGameSnapshot(force: true));
              },
            ),
            _controlButton('Reset', Icons.replay_rounded, _resetGame),
            _controlButton('Resign', Icons.flag_rounded,
                _gameOver ? null : () => unawaited(_resign())),
            _controlButton('New', Icons.add_rounded, _newGame),
          ],
        ),
        const SizedBox(height: 12),
        _StatusPanel(
          text: _resultMessage ??
              (_engineThinking
                  ? 'Engine thinking'
                  : '${_sideLabel(_board.turn)} to move'),
          subtext: [
            'You are ${_sideLabel(_userColor)}',
            _timeControl.label,
            if (_showSuggestion && _suggestionMove != null)
              'Suggestion: $_suggestionMove',
            if (_showMoveFeedback && _moveFeedback != null) _moveFeedback!,
          ].join(' | '),
          highlighted: _engineThinking,
        ),
      ],
    );
  }

  Widget _controlButton(String label, IconData icon, VoidCallback? onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  PieceColor _opposite(PieceColor color) =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;

  PieceColor _pieceColorFromName(String? value,
      {required PieceColor fallback}) {
    switch (value?.toLowerCase()) {
      case 'white':
        return PieceColor.white;
      case 'black':
        return PieceColor.black;
      default:
        return fallback;
    }
  }

  String _sideLabel(PieceColor color) =>
      color == PieceColor.white ? 'White' : 'Black';
}

enum _ActiveGameRestoreAction {
  discard,
  resume,
}

enum _PlayGameResultAction {
  newGame,
  viewHistory,
  close,
}

class _PlayGameResultDialog extends StatelessWidget {
  final PlayComputerGameRecord record;
  final ValueChanged<_PlayGameResultAction> onAction;

  const _PlayGameResultDialog({
    required this.record,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = _resultColor;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
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
                          border: Border.all(color: resultColor.withAlpha(90)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(_resultIcon, color: resultColor, size: 28),
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
                              record.resultReason,
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
                    record.resultText,
                    style: const TextStyle(
                      color: DesignSystem.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ResultFactPanel(record: record),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => onAction(_PlayGameResultAction.newGame),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Game'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PlayDialogActionButton(
                    icon: Icons.history_rounded,
                    label: 'View History',
                    onPressed: () =>
                        onAction(_PlayGameResultAction.viewHistory),
                  ),
                  const SizedBox(height: 10),
                  _PlayDialogActionButton(
                    icon: Icons.close_rounded,
                    label: 'Close',
                    onPressed: () => onAction(_PlayGameResultAction.close),
                    muted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    if (record.isDraw) return record.resultReason;
    return record.userWon ? 'You Won' : 'You Lost';
  }

  Color get _resultColor {
    if (record.isDraw) return DesignSystem.warningLight;
    return record.userWon ? DesignSystem.successLight : DesignSystem.errorLight;
  }

  IconData get _resultIcon {
    if (record.isDraw) return Icons.balance_rounded;
    if (record.resultReason == 'Checkmate') {
      return record.userWon
          ? Icons.emoji_events_rounded
          : Icons.gpp_bad_rounded;
    }
    if (record.resultReason == 'Timeout') return Icons.timer_off_rounded;
    return record.userWon ? Icons.flag_rounded : Icons.flag_outlined;
  }
}

class _ResultFactPanel extends StatelessWidget {
  final PlayComputerGameRecord record;

  const _ResultFactPanel({required this.record});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundBase.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultFact(label: 'You played', value: record.userColorLabel),
            _ResultFact(label: 'Time control', value: record.timeControlLabel),
            _ResultFact(label: 'Moves', value: '${record.moveCount}'),
            _ResultFact(
              label: 'Engine',
              value:
                  '${record.engineProfileName}, depth ${record.engineDepth}, skill ${record.engineSkill}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultFact extends StatelessWidget {
  final String label;
  final String value;

  const _ResultFact({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: DesignSystem.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayDialogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool muted;

  const _PlayDialogActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        muted ? DesignSystem.textMuted : DesignSystem.textPrimary;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(
            color: muted ? DesignSystem.border : DesignSystem.borderFocus,
          ),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _BoardWithEvaluationBar extends StatelessWidget {
  static const double _maxBoardSize = 430;
  static const double _regularEvalBarWidth = 34;
  static const double _compactEvalBarWidth = 28;
  static const double _regularGap = 8;
  static const double _compactGap = 6;

  final bool showEvaluation;
  final int? centipawns;
  final Widget Function(double boardSize) boardBuilder;

  const _BoardWithEvaluationBar({
    required this.showEvaluation,
    required this.centipawns,
    required this.boardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = math.max(0.0, MediaQuery.sizeOf(context).width);
        final maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : fallbackWidth;
        final compact = maxWidth < 360;
        final evalBarWidth = showEvaluation
            ? (compact ? _compactEvalBarWidth : _regularEvalBarWidth)
            : 0.0;
        final gap =
            showEvaluation ? (compact ? _compactGap : _regularGap) : 0.0;
        final availableBoardWidth =
            math.max(0.0, maxWidth - evalBarWidth - gap);
        final boardSize = math.min(
          _maxBoardSize,
          showEvaluation ? availableBoardWidth : maxWidth,
        );

        return SizedBox(
          key: const ValueKey('play_eval_board_layout'),
          width: maxWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showEvaluation) ...[
                SizedBox(
                  key: const ValueKey('play_evaluation_bar'),
                  width: evalBarWidth,
                  height: boardSize,
                  child: _EvaluationRail(
                    centipawns: centipawns,
                    height: boardSize,
                  ),
                ),
                SizedBox(width: gap),
              ],
              boardBuilder(boardSize),
            ],
          ),
        );
      },
    );
  }
}

class _ClockPill extends StatelessWidget {
  final String label;
  final Duration duration;
  final bool active;

  const _ClockPill({
    required this.label,
    required this.duration,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? DesignSystem.secondary : DesignSystem.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? DesignSystem.secondary.withAlpha(18)
            : DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(active ? 130 : 70)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            Text(
              _formatDuration(duration),
              style: const TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _EvaluationRail extends StatelessWidget {
  final int? centipawns;
  final double height;

  const _EvaluationRail({
    required this.centipawns,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final whiteShare = EngineEvaluation.whiteShare(centipawns);
    final blackFlex = ((1 - whiteShare) * 1000).round().clamp(1, 999).toInt();
    final whiteFlex = (whiteShare * 1000).round().clamp(1, 999).toInt();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 16,
              height: height,
              child: Column(
                children: [
                  Expanded(
                    flex: blackFlex,
                    child: Container(color: const Color(0xFF10131A)),
                  ),
                  Expanded(
                    flex: whiteFlex,
                    child: Container(color: const Color(0xFFF3E6C8)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 1,
            right: 1,
            child: Container(
              key: const ValueKey('play_eval_value'),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              decoration: BoxDecoration(
                color: DesignSystem.backgroundRaised.withAlpha(232),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignSystem.border),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  EngineEvaluation.formatWhiteScore(centipawns),
                  style: const TextStyle(
                    color: DesignSystem.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
String debugFormatPlayEvaluation(int? centipawns) {
  return EngineEvaluation.formatWhiteScore(centipawns);
}

@visibleForTesting
double debugWhiteEvaluationShare(int? centipawns) {
  return EngineEvaluation.whiteShare(centipawns);
}

class _StatusPanel extends StatelessWidget {
  final String text;
  final String subtext;
  final bool highlighted;

  const _StatusPanel({
    required this.text,
    required this.subtext,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? DesignSystem.primary.withAlpha(20)
            : DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? DesignSystem.primary : DesignSystem.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            TurboIcon(
              kind: TurboIconKind.playComputer,
              color: highlighted
                  ? DesignSystem.primaryLight
                  : DesignSystem.textMuted,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: DesignSystem.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
