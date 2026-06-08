import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/chess/chess_board.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/chess_rules.dart';
import '../../../core/engine/san_converter.dart';
import '../data/play_computer_history_store.dart';
import '../domain/play_computer_game_record.dart';

class PlayComputerHistoryScreen extends StatefulWidget {
  const PlayComputerHistoryScreen({super.key});

  @override
  State<PlayComputerHistoryScreen> createState() =>
      _PlayComputerHistoryScreenState();
}

class _PlayComputerHistoryScreenState extends State<PlayComputerHistoryScreen> {
  final PlayComputerHistoryStore _store = const PlayComputerHistoryStore();
  late Future<List<PlayComputerGameRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundBase,
      appBar: AppBar(
        title: const Text('Play History'),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        child: FutureBuilder<List<PlayComputerGameRecord>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? const <PlayComputerGameRecord>[];
            if (records.isEmpty) return const _EmptyHistoryState();

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = records[index];
                return _HistoryRecordTile(
                  record: record,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PlayComputerHistoryDetailScreen(
                        record: record,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PlayComputerHistoryDetailScreen extends StatefulWidget {
  final PlayComputerGameRecord record;

  const PlayComputerHistoryDetailScreen({
    super.key,
    required this.record,
  });

  @override
  State<PlayComputerHistoryDetailScreen> createState() =>
      _PlayComputerHistoryDetailScreenState();
}

class _PlayComputerHistoryDetailScreenState
    extends State<PlayComputerHistoryDetailScreen> {
  late final _ReplayBuildResult _replay;
  late final ScrollController _moveStripController;
  late final Map<int, GlobalKey> _movePillKeys;
  final GlobalKey _moveStripViewportKey = GlobalKey();
  int _plyIndex = 0;
  bool _flipped = false;
  bool _detailsExpanded = false;

  PlayComputerGameRecord get record => widget.record;

  @override
  void initState() {
    super.initState();
    _replay = _ReplayBuildResult.fromRecord(record);
    _moveStripController = ScrollController();
    _movePillKeys = {
      for (final move in _replay.moves)
        move.ply: GlobalKey(debugLabel: 'replay_move_pill_${move.ply}'),
    };
    _plyIndex = 0;
    _flipped = record.userColor == PieceColor.black;
  }

  @override
  void dispose() {
    _moveStripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _replay.positions[_plyIndex];
    final boardSize =
        MediaQuery.sizeOf(context).width.clamp(280.0, 430.0).toDouble();
    return Scaffold(
      backgroundColor: DesignSystem.backgroundBase,
      appBar: AppBar(
        title: const Text('Game Replay'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Flip board',
            onPressed: () => setState(() => _flipped = !_flipped),
            icon: const Icon(Icons.flip_rounded),
          ),
        ],
      ),
      body: AdScreenFrame(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _HistoryDetailHeader(
                  record: record,
                  expanded: _detailsExpanded,
                  onToggle: () => setState(
                    () => _detailsExpanded = !_detailsExpanded,
                  ),
                ),
              ),
            ),
            if (_replay.warning != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _MutedPanel(text: _replay.warning!),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ChessBoardWidget(
                    key: const ValueKey('play_history_replay_board'),
                    board: position.board,
                    size: boardSize,
                    flipped: _flipped,
                    lastMoveFrom: position.move?.from,
                    lastMoveTo: position.move?.to,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _ReplayControls(
                  current: _plyIndex,
                  total: _replay.positions.length - 1,
                  onFirst: _plyIndex == 0 ? null : () => _jumpTo(0),
                  onPrevious:
                      _plyIndex == 0 ? null : () => _jumpTo(_plyIndex - 1),
                  onNext: _plyIndex >= _replay.positions.length - 1
                      ? null
                      : () => _jumpTo(_plyIndex + 1),
                  onLast: _plyIndex >= _replay.positions.length - 1
                      ? null
                      : () => _jumpTo(_replay.positions.length - 1),
                ),
              ),
            ),
            if (_replay.moves.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _MutedPanel(text: 'No moves were played.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _ReplayMoveStrip(
                    controller: _moveStripController,
                    viewportKey: _moveStripViewportKey,
                    moveKeys: _movePillKeys,
                    moves: _replay.moves,
                    selectedPly: _plyIndex,
                    onSelectPly: _jumpTo,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _jumpTo(int index) {
    final nextIndex = index.clamp(0, _replay.positions.length - 1).toInt();
    if (_plyIndex == nextIndex) {
      _scheduleSelectedMoveScroll();
      return;
    }
    setState(() {
      _plyIndex = nextIndex;
    });
    _scheduleSelectedMoveScroll();
  }

  void _scheduleSelectedMoveScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollSelectedMoveIntoView();
    });
  }

  void _scrollSelectedMoveIntoView() {
    if (!_moveStripController.hasClients ||
        !_moveStripController.position.hasContentDimensions) {
      return;
    }

    if (_plyIndex <= 0) {
      if (_moveStripController.offset <= 0) return;
      unawaited(
        _moveStripController.animateTo(
          0,
          duration: DesignSystem.durationFast,
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }

    final itemContext = _movePillKeys[_plyIndex]?.currentContext;
    final viewportContext = _moveStripViewportKey.currentContext;
    if (itemContext == null || viewportContext == null) return;

    final itemBox = itemContext.findRenderObject();
    final viewportBox = viewportContext.findRenderObject();
    if (itemBox is! RenderBox ||
        viewportBox is! RenderBox ||
        !itemBox.hasSize ||
        !viewportBox.hasSize) {
      return;
    }

    final itemLeft = itemBox.localToGlobal(Offset.zero).dx -
        viewportBox
            .localToGlobal(
              Offset.zero,
            )
            .dx;
    final targetOffset = (_moveStripController.offset +
            itemLeft -
            ((viewportBox.size.width - itemBox.size.width) / 2))
        .clamp(0.0, _moveStripController.position.maxScrollExtent)
        .toDouble();

    unawaited(
      _moveStripController.animateTo(
        targetOffset,
        duration: DesignSystem.durationNormal,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _ReplayControls extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;

  const _ReplayControls({
    required this.current,
    required this.total,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('replay_first'),
              tooltip: 'Start',
              onPressed: onFirst,
              icon: const Icon(Icons.first_page_rounded),
            ),
            IconButton(
              key: const ValueKey('replay_previous'),
              tooltip: 'Previous',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                'Move $current / $total',
                key: const ValueKey('replay_move_counter'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DesignSystem.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('replay_next'),
              tooltip: 'Next',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              key: const ValueKey('replay_last'),
              tooltip: 'End',
              onPressed: onLast,
              icon: const Icon(Icons.last_page_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayBuildResult {
  final List<_ReplayPosition> positions;
  final List<_ReplayDisplayMove> moves;
  final String? warning;

  const _ReplayBuildResult({
    required this.positions,
    required this.moves,
    this.warning,
  });

  factory _ReplayBuildResult.fromRecord(PlayComputerGameRecord record) {
    final startingBoard = ChessBoard.tryFromFen(record.startingFen) ??
        ChessBoard.tryFromFen(record.finalFen) ??
        ChessBoard.starting();
    final positions = <_ReplayPosition>[
      _ReplayPosition(board: startingBoard),
    ];
    final displayMoves = <_ReplayDisplayMove>[];
    var current = startingBoard;
    String? warning;

    for (var index = 0; index < record.moves.length; index += 1) {
      final move = record.moves[index];
      if (move.move.length < 4) {
        warning = 'This saved game cannot be fully replayed.';
        break;
      }
      final next = ChessRules.applyUciMove(current, move.move) ??
          ChessBoard.tryFromFen(move.fenAfter);
      if (next == null) {
        warning = 'This saved game cannot be fully replayed.';
        break;
      }
      final san = _sanForReplayMove(
        uci: move.move,
        savedSan: move.moveSan,
        before: current,
      );
      displayMoves.add(
        _ReplayDisplayMove(
          ply: index + 1,
          moveNumber: move.moveNumber > 0 ? move.moveNumber : (index ~/ 2) + 1,
          sideToMove: move.sideToMoveBefore,
          san: san,
        ),
      );
      positions.add(
        _ReplayPosition(
          board: next,
          move: _ReplayMove(
            from: move.move.substring(0, 2),
            to: move.move.substring(2, 4),
          ),
        ),
      );
      current = next;
    }

    if (record.moves.isEmpty &&
        record.finalFen.isNotEmpty &&
        record.finalFen != record.startingFen) {
      final finalBoard = ChessBoard.tryFromFen(record.finalFen);
      if (finalBoard != null) {
        positions.add(_ReplayPosition(board: finalBoard));
        warning = 'This saved game cannot be fully replayed.';
      }
    }

    return _ReplayBuildResult(
      positions: positions,
      moves: displayMoves,
      warning: warning,
    );
  }

  static String _sanForReplayMove({
    required String uci,
    required String savedSan,
    required ChessBoard before,
  }) {
    final generatedSan = SanConverter.uciToSan(uci, before);
    if (generatedSan != uci.substring(2, 4)) return generatedSan;
    return savedSan.isNotEmpty ? savedSan : generatedSan;
  }
}

class _ReplayPosition {
  final ChessBoard board;
  final _ReplayMove? move;

  const _ReplayPosition({
    required this.board,
    this.move,
  });
}

class _ReplayMove {
  final String from;
  final String to;

  const _ReplayMove({
    required this.from,
    required this.to,
  });
}

class _ReplayDisplayMove {
  final int ply;
  final int moveNumber;
  final PieceColor sideToMove;
  final String san;

  const _ReplayDisplayMove({
    required this.ply,
    required this.moveNumber,
    required this.sideToMove,
    required this.san,
  });

  String get label {
    final prefix = sideToMove == PieceColor.white ? '$moveNumber. ' : '';
    return '$prefix$san';
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('play_history_empty_state'),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TurboIconBadge(
              kind: TurboIconKind.playComputer,
              color: DesignSystem.secondary,
              size: 58,
              iconSize: 32,
            ),
            SizedBox(height: 14),
            Text(
              'No games yet',
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Finished games will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignSystem.textMuted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  static final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  final PlayComputerGameRecord record;
  final VoidCallback onTap;

  const _HistoryRecordTile({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = record.isDraw
        ? DesignSystem.warningLight
        : record.userWon
            ? DesignSystem.successLight
            : DesignSystem.errorLight;

    return Semantics(
      button: true,
      label: 'Open play history ${record.resultText}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('play_history_record_${record.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withAlpha(70)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: color, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DesignSystem.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            _dateFormat.format(record.endedAt.toLocal()),
                            record.userColorLabel,
                            record.timeControlLabel,
                            '${record.moveCount} moves',
                          ].join(' | '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DesignSystem.textMuted,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DesignSystem.textMuted,
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
    return record.userWon ? 'You won' : 'You lost';
  }
}

class _HistoryDetailHeader extends StatelessWidget {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy h:mm a');

  final PlayComputerGameRecord record;
  final bool expanded;
  final VoidCallback onToggle;

  const _HistoryDetailHeader({
    required this.record,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = record.isDraw
        ? DesignSystem.warningLight
        : record.userWon
            ? DesignSystem.successLight
            : DesignSystem.errorLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: resultColor.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: resultColor.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('play_history_detail_card'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: resultColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: resultColor.withAlpha(66)),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: resultColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.resultText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesignSystem.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateFormat.format(record.endedAt.toLocal()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesignSystem.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('play_history_details_toggle'),
                      tooltip: expanded ? 'Hide details' : 'Show details',
                      onPressed: onToggle,
                      icon: AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: DesignSystem.durationFast,
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: DesignSystem.durationNormal,
                  curve: Curves.easeOutCubic,
                  child: expanded
                      ? Padding(
                          key: const ValueKey('play_history_details_expanded'),
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(
                                height: 1,
                                color: DesignSystem.border,
                              ),
                              const SizedBox(height: 6),
                              _MetaLine(
                                label: 'You played',
                                value: record.userColorLabel,
                              ),
                              _MetaLine(
                                label: 'Time control',
                                value: record.timeControlLabel,
                              ),
                              _MetaLine(
                                label: 'Engine',
                                value:
                                    '${record.engineProfileName}, depth ${record.engineDepth}, skill ${record.engineSkill}, ${record.engineMoveTimeMs}ms',
                              ),
                              _MetaLine(
                                label: 'Starting FEN',
                                value: record.startingFen,
                              ),
                              _MetaLine(
                                label: 'Final FEN',
                                value: record.finalFen,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplayMoveStrip extends StatelessWidget {
  final ScrollController controller;
  final GlobalKey viewportKey;
  final Map<int, GlobalKey> moveKeys;
  final List<_ReplayDisplayMove> moves;
  final int selectedPly;
  final ValueChanged<int> onSelectPly;

  const _ReplayMoveStrip({
    required this.controller,
    required this.viewportKey,
    required this.moveKeys,
    required this.moves,
    required this.selectedPly,
    required this.onSelectPly,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('play_history_horizontal_move_strip'),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.border),
      ),
      child: SizedBox(
        key: viewportKey,
        height: 52,
        child: SingleChildScrollView(
          key: const ValueKey('play_history_move_strip_scroll'),
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (var index = 0; index < moves.length; index += 1) ...[
                if (index > 0) const SizedBox(width: 8),
                KeyedSubtree(
                  key: moveKeys[moves[index].ply],
                  child: _MovePill(
                    move: moves[index],
                    selected: selectedPly == moves[index].ply,
                    onTap: () => onSelectPly(moves[index].ply),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MovePill extends StatelessWidget {
  final _ReplayDisplayMove move;
  final bool selected;
  final VoidCallback onTap;

  const _MovePill({
    required this.move,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('play_history_move_pill_${move.ply}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: DesignSystem.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? DesignSystem.primary.withAlpha(45)
                : DesignSystem.backgroundElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? DesignSystem.primaryLight
                  : DesignSystem.border.withAlpha(150),
            ),
          ),
          child: Text(
            move.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? DesignSystem.primaryOnContainer
                  : DesignSystem.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  final String text;

  const _MutedPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: const TextStyle(
            color: DesignSystem.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
