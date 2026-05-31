import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/design_system.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_progress_store.dart';
import '../../../core/ui/turbo_chess_icons.dart';
import '../../play_computer/presentation/active_play_computer_resume_card.dart';

class TrainScreen extends StatefulWidget {
  final bool isVisible;

  const TrainScreen({
    super.key,
    this.isVisible = true,
  });

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  final PositionProgressStore _progressStore = const PositionProgressStore();
  Map<PositionCategory, PositionProgressSnapshot> _progress = const {};

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  @override
  void didUpdateWidget(covariant TrainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      _refreshProgress();
    }
  }

  Future<void> _refreshProgress() async {
    final entries = await Future.wait(
      PositionCategory.values.map((category) async {
        return MapEntry(category, await _progressStore.snapshot(category));
      }),
    );
    if (!mounted) return;
    setState(() => _progress = Map.fromEntries(entries));
  }

  Future<void> _openRoute(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) {
      await _refreshProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        isVisible: widget.isVisible,
        bottomBannerUsesSafeArea: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const SizedBox(height: 12),
            const AdFreeCompactStatusLine(
              padding: EdgeInsets.only(bottom: 16),
            ),
            const ActivePlayComputerResumeCard(
              padding: EdgeInsets.only(bottom: 14),
            ),
            _TrainActionBar(
              iconGlyph: TurboChessIconGlyph.openingDrills,
              title: 'Opening Drills',
              subtitle: _progressLabel(PositionCategory.opening),
              progress: _progress[PositionCategory.opening],
              accentColor: DesignSystem.primary,
              onTap: () => _openRoute('/train/openings'),
            ),
            const SizedBox(height: 12),
            _TrainActionBar(
              iconGlyph: TurboChessIconGlyph.middlegameDrills,
              title: 'Middlegame Drills',
              subtitle: _progressLabel(PositionCategory.middlegame),
              progress: _progress[PositionCategory.middlegame],
              accentColor: DesignSystem.secondary,
              onTap: () => _openRoute('/train/middlegame'),
            ),
            const SizedBox(height: 12),
            _TrainActionBar(
              iconGlyph: TurboChessIconGlyph.endgameDrills,
              title: 'Endgame Drills',
              subtitle: _progressLabel(PositionCategory.endgame),
              progress: _progress[PositionCategory.endgame],
              accentColor: DesignSystem.tertiary,
              onTap: () => _openRoute('/train/endgame'),
            ),
            const SizedBox(height: 12),
            _TrainActionBar(
              iconGlyph: TurboChessIconGlyph.playVsComputer,
              title: 'Play vs Computer',
              subtitle: 'Standard chess practice',
              accentColor: DesignSystem.secondary,
              onTap: () => _openRoute('/play/computer'),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(PositionCategory category) {
    final completed = _progress[category]?.completedCount ?? 0;
    return '$completed / 10,000 completed';
  }
}

class _TrainActionBar extends StatelessWidget {
  final TurboChessIconGlyph iconGlyph;
  final String title;
  final String subtitle;
  final PositionProgressSnapshot? progress;
  final Color accentColor;
  final VoidCallback onTap;

  const _TrainActionBar({
    required this.iconGlyph,
    required this.title,
    required this.subtitle,
    this.progress,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress?.completedCount ?? 0;
    final fraction = (completed / 10000).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignSystem.backgroundRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(18),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(24),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: accentColor.withAlpha(68)),
              ),
              alignment: Alignment.center,
              child: TurboChessIconSymbol(
                glyph: iconGlyph,
                color: accentColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignSystem.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: fraction,
                        backgroundColor:
                            DesignSystem.backgroundElevated.withAlpha(230),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignSystem.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
