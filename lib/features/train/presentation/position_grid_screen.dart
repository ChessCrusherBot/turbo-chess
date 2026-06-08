import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/design_system.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_fen_repository.dart';
import '../../../core/positions/position_progress_store.dart';

class PositionGridScreen extends StatefulWidget {
  final PositionCategory category;
  final PositionFenRepository? repository;
  final PositionProgressStore progressStore;

  const PositionGridScreen({
    super.key,
    required this.category,
    this.repository,
    this.progressStore = const PositionProgressStore(),
  });

  @override
  State<PositionGridScreen> createState() => _PositionGridScreenState();
}

class _PositionGridScreenState extends State<PositionGridScreen> {
  late final PositionFenRepository _repository;
  late final ScrollController _scrollController;
  late final TextEditingController _jumpController;
  late Future<_PositionGridSnapshot> _snapshotFuture;
  _PositionGridMetrics? _gridMetrics;
  Timer? _highlightTimer;
  int? _highlightedPosition;
  String? _jumpErrorText;

  Color get _accentColor => switch (widget.category) {
        PositionCategory.opening => DesignSystem.primary,
        PositionCategory.middlegame => DesignSystem.secondary,
        PositionCategory.endgame => DesignSystem.tertiary,
      };

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PositionFenRepository();
    _scrollController = ScrollController();
    _jumpController = TextEditingController();
    _snapshotFuture = _loadSnapshot();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _jumpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_PositionGridSnapshot> _loadSnapshot() async {
    final availableCount = await _repository.availableCount(widget.category);
    final progress = await widget.progressStore.snapshot(widget.category);

    return _PositionGridSnapshot(
      availableCount: availableCount,
      progress: progress,
    );
  }

  void _refreshProgress() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<void> _openPosition({
    required int positionIndex,
  }) async {
    await Navigator.pushNamed(
      context,
      '/train/position/drill',
      arguments: {
        'category': widget.category.id,
        'positionIndex': positionIndex,
      },
    );

    if (mounted) _refreshProgress();
  }

  void _jumpToPosition(int positionIndex, int availableCount) {
    final target = positionIndex.clamp(1, availableCount).toInt();
    final metrics = _gridMetrics;
    if (metrics == null || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jumpToPosition(target, availableCount);
      });
      return;
    }

    final row = (target - 1) ~/ metrics.crossAxisCount;
    final rawOffset = row * metrics.rowExtent;
    final maxOffset = _scrollController.position.maxScrollExtent;
    final offset = rawOffset.clamp(0.0, maxOffset).toDouble();

    _scrollController.jumpTo(offset);
    _highlightPosition(target);
  }

  void _highlightPosition(int positionIndex) {
    _highlightTimer?.cancel();
    setState(() => _highlightedPosition = positionIndex);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedPosition = null);
    });
  }

  void _submitJump(int availableCount) {
    final parsed = int.tryParse(_jumpController.text.trim());
    if (parsed == null || parsed < 1 || parsed > availableCount) {
      setState(() {
        _jumpErrorText = 'Enter a number from 1 to $availableCount.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _jumpErrorText = null;
    });
    _jumpToPosition(parsed, availableCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        child: FutureBuilder<_PositionGridSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _PositionGridMessage(
                title: 'Positions unavailable',
                message: 'Check that the bundled position file is registered.',
                color: _accentColor,
              );
            }

            final data = snapshot.data;
            if (data == null || data.availableCount == 0) {
              return _PositionGridMessage(
                title: 'No positions yet',
                message: 'Add one FEN per line to the position asset.',
                color: _accentColor,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: _PositionJumpCard(
                    color: _accentColor,
                    availableCount: data.availableCount,
                    controller: _jumpController,
                    errorText: _jumpErrorText,
                    onChanged: (_) {
                      if (_jumpErrorText != null) {
                        setState(() => _jumpErrorText = null);
                      }
                    },
                    onSubmitted: () => _submitJump(data.availableCount),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _PositionFastNavigation(
                    availableCount: data.availableCount,
                    lastPlayedIndex: data.progress.lastPlayedIndex,
                    color: _accentColor,
                    onQuickJump: (positionIndex) =>
                        _jumpToPosition(positionIndex, data.availableCount),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _gridMetrics = _PositionGridMetrics.fromWidth(
                          constraints.maxWidth,
                        );
                        return GridView.builder(
                          key: const ValueKey('position_grid_lazy_builder'),
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 142,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: data.availableCount,
                          itemBuilder: (context, index) {
                            final positionIndex = index + 1;
                            final completed =
                                data.progress.isCompleted(positionIndex);
                            final current = !completed &&
                                positionIndex == data.progress.lastPlayedIndex;

                            return _PositionTile(
                              positionIndex: positionIndex,
                              category: widget.category,
                              color: _accentColor,
                              completed: completed,
                              current: current,
                              highlighted:
                                  _highlightedPosition == positionIndex,
                              onTap: () => _openPosition(
                                positionIndex: positionIndex,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PositionGridSnapshot {
  final int availableCount;
  final PositionProgressSnapshot progress;

  const _PositionGridSnapshot({
    required this.availableCount,
    required this.progress,
  });
}

class _PositionJumpCard extends StatelessWidget {
  final Color color;
  final int availableCount;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const _PositionJumpCard({
    required this.color,
    required this.availableCount,
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('permanent_jump_position_card'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(26),
            DesignSystem.backgroundRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(28),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withAlpha(82)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_tab_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Jump to Position',
                    style: TextStyle(
                      color: DesignSystem.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('jump_position_input'),
                    controller: controller,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    style: const TextStyle(
                      color: DesignSystem.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Position number',
                      hintText: '1-$availableCount',
                      errorText: errorText,
                      prefixIcon: Icon(Icons.tag_rounded, color: color),
                      filled: true,
                      fillColor: DesignSystem.backgroundBase.withAlpha(150),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: color.withAlpha(65)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmitted(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const ValueKey('jump_position_go'),
                    onPressed: onSubmitted,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: const Text('Jump'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionFastNavigation extends StatelessWidget {
  final int availableCount;
  final int lastPlayedIndex;
  final Color color;
  final ValueChanged<int> onQuickJump;

  const _PositionFastNavigation({
    required this.availableCount,
    required this.lastPlayedIndex,
    required this.color,
    required this.onQuickJump,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = lastPlayedIndex.clamp(1, availableCount).toInt();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Fast navigation',
                    style: TextStyle(
                      color: DesignSystem.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              key: const ValueKey('position_quick_jump_controls'),
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickJumpChip(
                  label: 'Top',
                  onTap: () => onQuickJump(1),
                ),
                _QuickJumpChip(
                  label: 'Last played',
                  onTap: () => onQuickJump(currentIndex),
                ),
                _QuickJumpChip(
                  label: '25%',
                  onTap: () => onQuickJump((availableCount * 0.25).round()),
                ),
                _QuickJumpChip(
                  label: '50%',
                  onTap: () => onQuickJump((availableCount * 0.50).round()),
                ),
                _QuickJumpChip(
                  label: '75%',
                  onTap: () => onQuickJump((availableCount * 0.75).round()),
                ),
                _QuickJumpChip(
                  label: 'Bottom',
                  onTap: () => onQuickJump(availableCount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickJumpChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickJumpChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: ValueKey('quick_jump_$label'),
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.unfold_more_rounded, size: 17),
    );
  }
}

class _PositionGridMetrics {
  static const double horizontalPadding = 40;
  static const double maxCrossAxisExtent = 142;
  static const double mainAxisSpacing = 12;
  static const double crossAxisSpacing = 12;
  static const double childAspectRatio = 0.72;

  final int crossAxisCount;
  final double rowExtent;

  const _PositionGridMetrics({
    required this.crossAxisCount,
    required this.rowExtent,
  });

  factory _PositionGridMetrics.fromWidth(double width) {
    final crossAxisExtent = (width - horizontalPadding).clamp(1.0, width);
    final count = (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
        .ceil()
        .clamp(1, 1000)
        .toInt();
    final usableWidth = crossAxisExtent - crossAxisSpacing * (count - 1);
    final tileWidth = usableWidth / count;
    final tileHeight = tileWidth / childAspectRatio;
    return _PositionGridMetrics(
      crossAxisCount: count,
      rowExtent: tileHeight + mainAxisSpacing,
    );
  }
}

class _PositionTile extends StatelessWidget {
  final int positionIndex;
  final PositionCategory category;
  final Color color;
  final bool completed;
  final bool current;
  final bool highlighted;
  final VoidCallback onTap;

  const _PositionTile({
    required this.positionIndex,
    required this.category,
    required this.color,
    required this.completed,
    required this.current,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final endgameCompleted = completed && category == PositionCategory.endgame;
    final tileColor = endgameCompleted
        ? const Color(0xFF241F16)
        : DesignSystem.backgroundRaised;
    const foreground = DesignSystem.textPrimary;
    final statusIcon =
        completed ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded;
    final completedColor = endgameCompleted
        ? DesignSystem.warningLight
        : DesignSystem.successLight;
    final statusColor = completed ? completedColor : color;
    final borderColor = highlighted
        ? DesignSystem.warningLight
        : endgameCompleted
            ? completedColor.withAlpha(168)
            : color.withAlpha(76);
    final statusLabel = completed
        ? 'Completed'
        : current
            ? 'Last played'
            : 'Open';

    return Semantics(
      button: true,
      enabled: true,
      label: 'Position $positionIndex $statusLabel',
      child: InkWell(
        key: ValueKey('position_tile_$positionIndex'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: DesignSystem.durationFast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: highlighted ? 2 : 1),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: DesignSystem.warningLight.withAlpha(45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : endgameCompleted
                    ? [
                        BoxShadow(
                          color: DesignSystem.warningLight.withAlpha(24),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : DesignSystem.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const Spacer(),
                ],
              ),
              const Spacer(),
              Text(
                'Position',
                style: TextStyle(
                  color: foreground.withAlpha(190),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$positionIndex',
                style: const TextStyle(
                  color: foreground,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionGridMessage extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const _PositionGridMessage({
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, color: color, size: 34),
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
    );
  }
}
