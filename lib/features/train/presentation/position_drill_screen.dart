import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_service.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/chess/chess_board.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/play_vs_engine.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_fen_repository.dart';
import '../../../core/positions/position_progress_store.dart';
import 'drill_detail_base.dart';

class PositionDrillScreen extends StatefulWidget {
  final PositionCategory category;
  final int positionIndex;
  final PositionFenRepository? repository;
  final PositionProgressStore progressStore;
  final AdFreeService? adFreeService;
  final EngineMoveProvider? engineMoveProvider;
  final ValueChanged<DrillDebugSnapshot>? debugOnStateChanged;

  const PositionDrillScreen({
    super.key,
    required this.category,
    required this.positionIndex,
    this.repository,
    this.progressStore = const PositionProgressStore(),
    this.adFreeService,
    this.engineMoveProvider,
    this.debugOnStateChanged,
  });

  @override
  State<PositionDrillScreen> createState() => _PositionDrillScreenState();
}

class _PositionDrillScreenState extends State<PositionDrillScreen> {
  late PositionFenRepository _repository;
  late AdFreeService _adFreeService;
  _PositionDrillSnapshot? _snapshot;
  Object? _snapshotError;
  bool _loadingSnapshot = true;
  int _snapshotLoadToken = 0;

  bool get _hasActiveDrillSnapshot {
    final snapshot = _snapshot;
    return snapshot != null && snapshot.unlocked && snapshot.fen != null;
  }

  Color get _accentColor => switch (widget.category) {
        PositionCategory.opening => DesignSystem.primary,
        PositionCategory.middlegame => DesignSystem.secondary,
        PositionCategory.endgame => DesignSystem.tertiary,
      };

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PositionFenRepository();
    _adFreeService = widget.adFreeService ?? AdFreeService.instance;
    _startSnapshotLoad(reason: 'initial route load');
    _adFreeService.addListener(_handlePremiumChanged);
  }

  @override
  void dispose() {
    _adFreeService.removeListener(_handlePremiumChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PositionDrillScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeIdentityChanged = oldWidget.category != widget.category ||
        oldWidget.positionIndex != widget.positionIndex;
    final dependenciesChanged = oldWidget.repository != widget.repository ||
        oldWidget.adFreeService != widget.adFreeService ||
        oldWidget.progressStore != widget.progressStore;

    if (routeIdentityChanged) {
      _adFreeService.removeListener(_handlePremiumChanged);
      _repository = widget.repository ?? PositionFenRepository();
      _adFreeService = widget.adFreeService ?? AdFreeService.instance;
      _adFreeService.addListener(_handlePremiumChanged);
      _snapshot = null;
      _snapshotError = null;
      _loadingSnapshot = true;
      _startSnapshotLoad(reason: 'position route changed');
      return;
    }

    if (dependenciesChanged) {
      if (oldWidget.adFreeService != widget.adFreeService) {
        _adFreeService.removeListener(_handlePremiumChanged);
        _adFreeService = widget.adFreeService ?? AdFreeService.instance;
        _adFreeService.addListener(_handlePremiumChanged);
      }
      _repository = widget.repository ?? PositionFenRepository();
      if (_hasActiveDrillSnapshot) {
        _debugLog(
          'blocked same-position dependency refresh while drill is active',
        );
        return;
      }
      _startSnapshotLoad(reason: 'inactive dependency refresh');
    }
  }

  void _handlePremiumChanged() {
    if (!mounted) return;
    if (_hasActiveDrillSnapshot) {
      _debugLog('blocked premium refresh while drill is active');
      return;
    }
    _startSnapshotLoad(reason: 'premium refresh without active drill');
  }

  void _startSnapshotLoad({required String reason}) {
    final token = ++_snapshotLoadToken;
    final category = widget.category;
    final positionIndex = widget.positionIndex;
    final repository = _repository;
    final progressStore = widget.progressStore;
    final adFreeService = _adFreeService;

    setState(() {
      _loadingSnapshot = true;
      _snapshotError = null;
    });

    unawaited(
      _loadSnapshot(
        category: category,
        positionIndex: positionIndex,
        repository: repository,
        progressStore: progressStore,
        adFreeService: adFreeService,
      ).then((snapshot) {
        if (!mounted ||
            token != _snapshotLoadToken ||
            category != widget.category ||
            positionIndex != widget.positionIndex) {
          _debugLog('ignored stale snapshot load for $reason');
          return;
        }
        if (_hasActiveDrillSnapshot) {
          _debugLog('blocked completed snapshot from replacing active drill');
          setState(() {
            _loadingSnapshot = false;
          });
          return;
        }
        setState(() {
          _snapshot = snapshot;
          _snapshotError = null;
          _loadingSnapshot = false;
        });
      }).catchError((Object error) {
        if (!mounted ||
            token != _snapshotLoadToken ||
            category != widget.category ||
            positionIndex != widget.positionIndex) {
          _debugLog('ignored stale snapshot error for $reason');
          return;
        }
        if (_hasActiveDrillSnapshot) {
          _debugLog('blocked snapshot error from replacing active drill');
          setState(() {
            _loadingSnapshot = false;
          });
          return;
        }
        setState(() {
          _snapshotError = error;
          _loadingSnapshot = false;
        });
      }),
    );
  }

  Future<_PositionDrillSnapshot> _loadSnapshot({
    required PositionCategory category,
    required int positionIndex,
    required PositionFenRepository repository,
    required PositionProgressStore progressStore,
    required AdFreeService adFreeService,
  }) async {
    final availableCount = await repository.availableCount(category);
    final progress = await progressStore.snapshot(category);
    final hasPremiumAccess = adFreeService.status.isAdFree;
    final inRange = positionIndex >= 1 && positionIndex <= availableCount;
    final unlocked = inRange &&
        PositionProgressStore.isUnlocked(
          positionIndex: positionIndex,
          highestUnlockedIndex: progress.highestUnlockedIndex,
          hasPremiumAccess: hasPremiumAccess,
        );
    final fen =
        unlocked ? await repository.loadFen(category, positionIndex) : null;
    if (fen != null) {
      ChessBoard.fromFen(fen);
    }
    if (unlocked) {
      await progressStore.setLastPlayed(category, positionIndex);
    }

    return _PositionDrillSnapshot(
      availableCount: availableCount,
      inRange: inRange,
      unlocked: unlocked,
      fen: fen,
      completed: progress.isCompleted(positionIndex),
    );
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(
        'Turbo Chess position drill ${widget.category.id} '
        '#${widget.positionIndex}: $message',
      );
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    final data = _snapshot;
    if (data != null && data.inRange && data.unlocked && data.fen != null) {
      return DrillDetailBaseScreen.position(
        key: ValueKey(
          'position_drill_${widget.category.id}_${widget.positionIndex}',
        ),
        category: widget.category,
        positionIndex: widget.positionIndex,
        fen: data.fen!,
        totalPositions: data.availableCount,
        color: _accentColor,
        positionRepository: _repository,
        positionProgressStore: widget.progressStore,
        initialPositionCompleted: data.completed,
        adFreeService: _adFreeService,
        engineMoveProvider: widget.engineMoveProvider,
        debugOnStateChanged: widget.debugOnStateChanged,
      );
    }

    if (_loadingSnapshot && data == null) {
      return Scaffold(
        backgroundColor: DesignSystem.backgroundBase,
        body: AdScreenFrame(
          child: Center(
            child: CircularProgressIndicator(color: _accentColor),
          ),
        ),
      );
    }

    if (_snapshotError != null) {
      final error = _snapshotError;
      final message = error is FormatException
          ? 'The selected FEN is invalid and was not opened.'
          : 'The bundled FEN could not be loaded.';
      return _PositionDrillMessage(
        title: 'Position unavailable',
        message: message,
        color: _accentColor,
      );
    }

    if (data == null || !data.inRange) {
      return _PositionDrillMessage(
        title: 'Position not found',
        message: 'This position index is not in the pilot file.',
        color: _accentColor,
      );
    }

    if (!data.unlocked || data.fen == null) {
      return _PositionDrillMessage(
        title: 'Position locked',
        message: 'Complete the previous position to unlock this one.',
        color: _accentColor,
      );
    }

    return _PositionDrillMessage(
      title: 'Position unavailable',
      message: 'The bundled FEN could not be loaded.',
      color: _accentColor,
    );
  }
}

class _PositionDrillSnapshot {
  final int availableCount;
  final bool inRange;
  final bool unlocked;
  final String? fen;
  final bool completed;

  const _PositionDrillSnapshot({
    required this.availableCount,
    required this.inRange,
    required this.unlocked,
    required this.fen,
    required this.completed,
  });
}

class _PositionDrillMessage extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const _PositionDrillMessage({
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundBase,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: AdScreenFrame(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: color, size: 36),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DesignSystem.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: DesignSystem.textMuted,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
