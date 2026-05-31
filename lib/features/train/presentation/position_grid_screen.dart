import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_service.dart';
import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_fen_repository.dart';
import '../../../core/positions/position_progress_store.dart';

class PositionGridScreen extends StatefulWidget {
  final PositionCategory category;
  final PositionFenRepository? repository;
  final PositionProgressStore progressStore;
  final AdFreeService? adFreeService;

  const PositionGridScreen({
    super.key,
    required this.category,
    this.repository,
    this.progressStore = const PositionProgressStore(),
    this.adFreeService,
  });

  @override
  State<PositionGridScreen> createState() => _PositionGridScreenState();
}

class _PositionGridScreenState extends State<PositionGridScreen> {
  late final PositionFenRepository _repository;
  late final AdFreeService _adFreeService;
  late final ScrollController _scrollController;
  late Future<_PositionGridSnapshot> _snapshotFuture;
  _PositionGridMetrics? _gridMetrics;
  Timer? _highlightTimer;
  int? _highlightedPosition;

  Color get _accentColor => switch (widget.category) {
        PositionCategory.opening => DesignSystem.primary,
        PositionCategory.middlegame => DesignSystem.secondary,
        PositionCategory.endgame => DesignSystem.tertiary,
      };

  TurboIconKind get _iconKind => switch (widget.category) {
        PositionCategory.opening => TurboIconKind.moduleOpenings,
        PositionCategory.middlegame => TurboIconKind.moduleMiddlegame,
        PositionCategory.endgame => TurboIconKind.moduleEndgame,
      };

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PositionFenRepository();
    _adFreeService = widget.adFreeService ?? AdFreeService.instance;
    _scrollController = ScrollController();
    _snapshotFuture = _loadSnapshot();
    _adFreeService.addListener(_handlePremiumChanged);
  }

  @override
  void dispose() {
    _adFreeService.removeListener(_handlePremiumChanged);
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePremiumChanged() {
    if (mounted) setState(() {});
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
    required bool unlocked,
  }) async {
    if (!unlocked) {
      await _showLockedPositionDialog(positionIndex);
      return;
    }

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

  Future<void> _showLockedPositionDialog(int positionIndex) async {
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _LockedPositionPremiumDialog(
        positionIndex: positionIndex,
        categoryTitle: widget.category.title,
        adFreeService: _adFreeService,
      ),
    );

    if (!mounted) return;
    if (unlocked == true) {
      _refreshProgress();
      _showSnackBar('Premium access active. All positions are unlocked.',
          success: true);
    }
  }

  void _showSnackBar(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? DesignSystem.backgroundElevated
            : DesignSystem.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  Future<void> _showJumpDialog(int availableCount) async {
    final controller = TextEditingController();
    final target = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: DesignSystem.backgroundRaised,
              title: const Text('Jump to position'),
              content: TextField(
                key: const ValueKey('jump_position_input'),
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Position number',
                  hintText: '1-$availableCount',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  final parsed = int.tryParse(controller.text.trim());
                  if (parsed == null || parsed < 1 || parsed > availableCount) {
                    setDialogState(() {
                      errorText = 'Enter a number from 1 to $availableCount.';
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, parsed);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('jump_position_go'),
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null ||
                        parsed < 1 ||
                        parsed > availableCount) {
                      setDialogState(() {
                        errorText = 'Enter a number from 1 to $availableCount.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, parsed);
                  },
                  child: const Text('Jump'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (target != null && mounted) {
      _jumpToPosition(target, availableCount);
    }
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

            final hasPremiumAccess = _adFreeService.status.isAdFree;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: _PositionGridHeader(
                    category: widget.category,
                    color: _accentColor,
                    iconKind: _iconKind,
                    availableCount: data.availableCount,
                    highestUnlockedIndex: data.progress.highestUnlockedIndex,
                    hasPremiumAccess: hasPremiumAccess,
                  ),
                ),
                const AdFreeCompactStatusLine(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _PositionFastNavigation(
                    availableCount: data.availableCount,
                    highestUnlockedIndex: data.progress.highestUnlockedIndex,
                    hasPremiumAccess: hasPremiumAccess,
                    color: _accentColor,
                    onQuickJump: (positionIndex) =>
                        _jumpToPosition(positionIndex, data.availableCount),
                    onOpenJumpDialog: () =>
                        unawaited(_showJumpDialog(data.availableCount)),
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
                            final unlocked = PositionProgressStore.isUnlocked(
                              positionIndex: positionIndex,
                              highestUnlockedIndex:
                                  data.progress.highestUnlockedIndex,
                              hasPremiumAccess: hasPremiumAccess,
                            );
                            final completed =
                                data.progress.isCompleted(positionIndex);
                            final current = !completed &&
                                !hasPremiumAccess &&
                                positionIndex ==
                                    data.progress.highestUnlockedIndex;

                            return _PositionTile(
                              positionIndex: positionIndex,
                              color: _accentColor,
                              unlocked: unlocked,
                              completed: completed,
                              current: current,
                              premiumUnlocked: hasPremiumAccess && !completed,
                              highlighted:
                                  _highlightedPosition == positionIndex,
                              onTap: () => _openPosition(
                                positionIndex: positionIndex,
                                unlocked: unlocked,
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

class _PositionGridHeader extends StatelessWidget {
  final PositionCategory category;
  final Color color;
  final TurboIconKind iconKind;
  final int availableCount;
  final int highestUnlockedIndex;
  final bool hasPremiumAccess;

  const _PositionGridHeader({
    required this.category,
    required this.color,
    required this.iconKind,
    required this.availableCount,
    required this.highestUnlockedIndex,
    required this.hasPremiumAccess,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedThrough = hasPremiumAccess
        ? availableCount
        : highestUnlockedIndex.clamp(1, availableCount).toInt();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TurboIconBadge(
              kind: iconKind,
              color: color,
              size: 52,
              iconSize: 29,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DesignSystem.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$availableCount training positions',
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPremiumAccess
                        ? 'Premium unlocks all positions'
                        : 'Unlocked through Position $unlockedThrough',
                    style: TextStyle(
                      color: hasPremiumAccess
                          ? DesignSystem.secondary
                          : DesignSystem.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _PositionFastNavigation extends StatelessWidget {
  final int availableCount;
  final int highestUnlockedIndex;
  final bool hasPremiumAccess;
  final Color color;
  final ValueChanged<int> onQuickJump;
  final VoidCallback onOpenJumpDialog;

  const _PositionFastNavigation({
    required this.availableCount,
    required this.highestUnlockedIndex,
    required this.hasPremiumAccess,
    required this.color,
    required this.onQuickJump,
    required this.onOpenJumpDialog,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = hasPremiumAccess
        ? availableCount
        : highestUnlockedIndex.clamp(1, availableCount).toInt();

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
                TextButton.icon(
                  key: const ValueKey('open_jump_position_dialog'),
                  onPressed: onOpenJumpDialog,
                  icon: const Icon(Icons.keyboard_tab_rounded, size: 18),
                  label: const Text('Jump'),
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
                  label: 'Current',
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

class _LockedPositionPremiumDialog extends StatefulWidget {
  final int positionIndex;
  final String categoryTitle;
  final AdFreeService adFreeService;

  const _LockedPositionPremiumDialog({
    required this.positionIndex,
    required this.categoryTitle,
    required this.adFreeService,
  });

  @override
  State<_LockedPositionPremiumDialog> createState() =>
      _LockedPositionPremiumDialogState();
}

class _LockedPositionPremiumDialogState
    extends State<_LockedPositionPremiumDialog> {
  bool _subscribing = false;
  bool _restoring = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.adFreeService.addListener(_handlePremiumChanged);
  }

  @override
  void dispose() {
    widget.adFreeService.removeListener(_handlePremiumChanged);
    super.dispose();
  }

  void _handlePremiumChanged() {
    if (!mounted || !widget.adFreeService.status.isAdFree) return;
    _closeWithPremiumAccess();
  }

  void _closeWithPremiumAccess() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
  }

  Future<void> _subscribe() async {
    if (_subscribing || _restoring) return;
    setState(() {
      _subscribing = true;
      _message = null;
    });

    await widget.adFreeService.subscribeAdFree();
    if (!mounted) return;
    final status = widget.adFreeService.status;
    if (status.isAdFree) {
      _closeWithPremiumAccess();
      return;
    }

    setState(() {
      _subscribing = false;
      _message = status.subscriptionError ??
          status.subscriptionMessage ??
          'Complete the purchase in Google Play.';
    });
  }

  Future<void> _restorePremium() async {
    if (_subscribing || _restoring) return;
    setState(() {
      _restoring = true;
      _message = null;
    });

    final result = await widget.adFreeService.restorePremium();
    if (!mounted) return;
    if (widget.adFreeService.status.isAdFree) {
      _closeWithPremiumAccess();
      return;
    }

    setState(() {
      _restoring = false;
      _message = result.status == PremiumRestoreStatus.notFound
          ? PremiumSubscriptionCopy.restoreTroubleshootingMessage
          : result.message;
    });
  }

  void _showHowRestoreWorks() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('How restore works'),
        content: const Text(PremiumSubscriptionCopy.accountNoticeLong),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignSystem.backgroundRaised,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DesignSystem.warningLight.withAlpha(110)),
            boxShadow: DesignSystem.shadowLg,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: DesignSystem.warningLight.withAlpha(26),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: DesignSystem.warningLight,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unlock all positions',
                              style: TextStyle(
                                color: DesignSystem.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${widget.categoryTitle} Position ${widget.positionIndex} is locked.',
                              style: const TextStyle(
                                color: DesignSystem.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Complete earlier positions to unlock it for free, or use Premium to unlock every position instantly.',
                    style: TextStyle(
                      color: DesignSystem.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _PremiumDialogInfoBox(
                    text: PremiumSubscriptionCopy.accountNotice,
                  ),
                  const SizedBox(height: 12),
                  _PremiumDialogOption(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Subscribe',
                    subtitle:
                        'Unlock all positions and remove ads while subscribed.',
                    color: DesignSystem.primaryLight,
                    buttonLabel: 'Subscribe',
                    loading: _subscribing,
                    onPressed: _subscribing || _restoring
                        ? null
                        : () => unawaited(_subscribe()),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _subscribing || _restoring
                        ? null
                        : () => unawaited(_restorePremium()),
                    icon: _restoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore Premium'),
                  ),
                  TextButton.icon(
                    onPressed: _subscribing || _restoring
                        ? null
                        : _showHowRestoreWorks,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('How restore works'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: DesignSystem.warningLight,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'You can also continue free by completing the previous positions.',
                    style: TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _subscribing || _restoring
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumDialogInfoBox extends StatelessWidget {
  final String text;

  const _PremiumDialogInfoBox({required this.text});

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
        child: Text(
          text,
          style: const TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PremiumDialogOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String buttonLabel;
  final bool loading;
  final VoidCallback? onPressed;

  const _PremiumDialogOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.buttonLabel,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: DesignSystem.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: DesignSystem.textMuted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPressed,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  final int positionIndex;
  final Color color;
  final bool unlocked;
  final bool completed;
  final bool current;
  final bool premiumUnlocked;
  final bool highlighted;
  final VoidCallback onTap;

  const _PositionTile({
    required this.positionIndex,
    required this.color,
    required this.unlocked,
    required this.completed,
    required this.current,
    required this.premiumUnlocked,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = unlocked
        ? DesignSystem.backgroundRaised
        : DesignSystem.backgroundElevated.withAlpha(130);
    final foreground = unlocked
        ? DesignSystem.textPrimary
        : DesignSystem.textMuted.withAlpha(180);
    final statusIcon = completed
        ? Icons.check_circle_rounded
        : unlocked
            ? Icons.play_circle_fill_rounded
            : Icons.lock_rounded;
    final statusColor = completed
        ? DesignSystem.successLight
        : unlocked
            ? color
            : DesignSystem.textMuted;
    final borderColor = highlighted
        ? DesignSystem.warningLight
        : unlocked
            ? color.withAlpha(76)
            : DesignSystem.border;
    final statusLabel = completed
        ? 'Completed'
        : premiumUnlocked
            ? 'Premium'
            : current
                ? 'Current'
                : unlocked
                    ? 'Current'
                    : 'Locked';

    return Semantics(
      button: true,
      enabled: unlocked,
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
                : unlocked
                    ? DesignSystem.shadowSm
                    : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const Spacer(),
                  if (premiumUnlocked)
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: DesignSystem.secondary,
                      size: 18,
                    ),
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
                style: TextStyle(
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
