import 'package:flutter/material.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/design_system.dart';
import '../../../core/ui/turbo_chess_icons.dart';

class LearnScreen extends StatelessWidget {
  final bool isVisible;

  const LearnScreen({
    super.key,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        isVisible: isVisible,
        bottomBannerUsesSafeArea: false,
        child: ListView(
          key: const ValueKey('learn_scroll'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: const [
            SizedBox(height: 12),
            _LearnHero(),
            SizedBox(height: 18),
            _MasteryCard(
              title: 'Chess Basics Mastery',
              iconGlyph: TurboChessIconGlyph.chessBasicsMastery,
              accentColor: DesignSystem.primaryLight,
            ),
            SizedBox(height: 12),
            _MasteryCard(
              title: 'Openings Mastery',
              iconGlyph: TurboChessIconGlyph.openingDrills,
              accentColor: DesignSystem.primary,
            ),
            SizedBox(height: 12),
            _MasteryCard(
              title: 'Middlegame Mastery',
              iconGlyph: TurboChessIconGlyph.middlegameDrills,
              accentColor: DesignSystem.secondary,
            ),
            SizedBox(height: 12),
            _MasteryCard(
              title: 'Endgame Mastery',
              iconGlyph: TurboChessIconGlyph.endgameDrills,
              accentColor: DesignSystem.tertiary,
            ),
            SizedBox(height: 14),
            _GrandmasterCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LearnHero extends StatelessWidget {
  const _LearnHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coming Soon',
          style: textTheme.displaySmall?.copyWith(
            color: DesignSystem.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Structured chess lessons are being prepared.',
          style: TextStyle(
            color: DesignSystem.textMuted,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final String title;
  final TurboChessIconGlyph iconGlyph;
  final Color accentColor;

  const _MasteryCard({
    required this.title,
    required this.iconGlyph,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignSystem.backgroundRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withAlpha(46)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TurboChessIconBadge(
                glyph: iconGlyph,
                color: accentColor,
                size: 48,
                iconSize: 27,
                glow: false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignSystem.textPrimary,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const _ComingSoonBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrandmasterCard extends StatelessWidget {
  const _GrandmasterCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D3300),
              Color(0xFF1D1830),
              DesignSystem.backgroundRaised,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DesignSystem.secondaryLight.withAlpha(150)),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.secondary.withAlpha(36),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TurboChessIconBadge(
                    glyph: TurboChessIconGlyph.roadToGm,
                    color: DesignSystem.secondaryLight,
                    size: 58,
                    iconSize: 34,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROAD TO BECOMING A GM',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DesignSystem.secondaryOnContainer,
                            fontSize: 19,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'A complete Grandmaster journey is being planned.',
                          style: TextStyle(
                            color: DesignSystem.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _ComingSoonBadge(
                highlighted: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  final bool highlighted;

  const _ComingSoonBadge({
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlighted
        ? DesignSystem.secondaryLight.withAlpha(34)
        : DesignSystem.backgroundSurface;
    final border = highlighted
        ? DesignSystem.secondaryLight.withAlpha(116)
        : DesignSystem.border;
    final textColor = highlighted
        ? DesignSystem.secondaryOnContainer
        : DesignSystem.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        'Coming Soon',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
