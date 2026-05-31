import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';
import '../../../core/positions/position_category.dart';
import '../../../core/positions/position_progress_store.dart';
import '../../../core/ui/turbo_chess_icons.dart';
import '../../play_computer/presentation/active_play_computer_resume_card.dart';

class HomeScreen extends StatefulWidget {
  final bool isVisible;

  const HomeScreen({
    super.key,
    this.isVisible = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PositionProgressStore _progressStore = const PositionProgressStore();
  Map<PositionCategory, PositionProgressSnapshot> _progress = const {};

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
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
    setState(() {
      _progress = Map.fromEntries(entries);
    });
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
      backgroundColor: DesignSystem.backgroundBase,
      body: SafeArea(
        top: true,
        bottom: false,
        child: AdScreenFrame(
          isVisible: widget.isVisible,
          showTopBanner: false,
          showBottomBanner: false,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DesignSystem.backgroundBase,
                  DesignSystem.backgroundBase,
                  DesignSystem.backgroundSurface,
                ],
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TurboBrandMarkBadge(size: 50),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Turbo Chess',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: DesignSystem.textPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const Text(
                                    'Training and engine play',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: DesignSystem.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const AdFreeCompactStatusLine(
                          padding: EdgeInsets.only(top: 12),
                        ),
                        const ActivePlayComputerResumeCard(
                          padding: EdgeInsets.only(top: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: AdBannerSlot(
                      key: const ValueKey('home_safe_top_banner_slot'),
                      placement: AdBannerPlacement.top,
                      isVisible: widget.isVisible,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Start',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: DesignSystem.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const Icon(
                          Icons.bolt_rounded,
                          color: DesignSystem.tertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _HomeActionBar(
                          iconGlyph: TurboChessIconGlyph.openingDrills,
                          title: 'Opening Drills',
                          subtitle: _progressLabel(PositionCategory.opening),
                          progress: _progress[PositionCategory.opening],
                          color: DesignSystem.primary,
                          onTap: () => _openRoute('/train/openings'),
                        ),
                        const SizedBox(height: 12),
                        _HomeActionBar(
                          iconGlyph: TurboChessIconGlyph.middlegameDrills,
                          title: 'Middlegame Drills',
                          subtitle: _progressLabel(PositionCategory.middlegame),
                          progress: _progress[PositionCategory.middlegame],
                          color: DesignSystem.secondary,
                          onTap: () => _openRoute('/train/middlegame'),
                        ),
                        const SizedBox(height: 12),
                        _HomeActionBar(
                          iconGlyph: TurboChessIconGlyph.endgameDrills,
                          title: 'Endgame Drills',
                          subtitle: _progressLabel(PositionCategory.endgame),
                          progress: _progress[PositionCategory.endgame],
                          color: DesignSystem.tertiary,
                          onTap: () => _openRoute('/train/endgame'),
                        ),
                        const SizedBox(height: 12),
                        _HomeActionBar(
                          iconGlyph: TurboChessIconGlyph.playVsComputer,
                          title: 'Play vs Computer',
                          subtitle: 'Standard chess practice',
                          color: DesignSystem.secondary,
                          onTap: () => _openRoute('/play/computer'),
                        ),
                        const SizedBox(height: 12),
                        _HomeActionBar(
                          iconGlyph: TurboChessIconGlyph.bookmarks,
                          title: 'Bookmarks',
                          subtitle: 'Saved drill positions',
                          color: DesignSystem.warning,
                          onTap: () => _openRoute('/bookmarks'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _progressLabel(PositionCategory category) {
    final completed = _progress[category]?.completedCount ?? 0;
    return '$completed / 10,000 completed';
  }
}

class _HomeActionBar extends StatelessWidget {
  final TurboChessIconGlyph iconGlyph;
  final String title;
  final String subtitle;
  final PositionProgressSnapshot? progress;
  final Color color;
  final VoidCallback onTap;

  const _HomeActionBar({
    required this.iconGlyph,
    required this.title,
    required this.subtitle,
    this.progress,
    required this.color,
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
          border: Border.all(color: color.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(18),
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
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: color.withAlpha(68)),
              ),
              alignment: Alignment.center,
              child: TurboChessIconSymbol(
                glyph: iconGlyph,
                color: color,
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
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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
