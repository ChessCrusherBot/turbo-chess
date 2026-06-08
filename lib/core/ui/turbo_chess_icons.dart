import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum TurboChessIconGlyph {
  openingDrills,
  middlegameDrills,
  endgameDrills,
  playVsComputer,
  bookmarks,
  chessBasicsMastery,
  roadToGm,
  settings,
  howToPlay,
  legal,
  about,
}

class TurboChessIconSymbol extends StatelessWidget {
  final TurboChessIconGlyph glyph;
  final Color color;
  final double size;

  const TurboChessIconSymbol({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final fontAwesomeIcon = _fontAwesomeIcon(glyph);
    if (fontAwesomeIcon != null) {
      return FaIcon(
        fontAwesomeIcon,
        color: color,
        size: size,
      );
    }

    return Icon(
      _materialIcon(glyph),
      color: color,
      size: size,
    );
  }

  static FaIconData? _fontAwesomeIcon(TurboChessIconGlyph glyph) {
    switch (glyph) {
      case TurboChessIconGlyph.openingDrills:
        return FontAwesomeIcons.chessPawn;
      case TurboChessIconGlyph.middlegameDrills:
        return FontAwesomeIcons.chessKnight;
      case TurboChessIconGlyph.endgameDrills:
        return FontAwesomeIcons.chessKing;
      case TurboChessIconGlyph.playVsComputer:
        return FontAwesomeIcons.robot;
      case TurboChessIconGlyph.roadToGm:
        return FontAwesomeIcons.crown;
      case TurboChessIconGlyph.bookmarks:
      case TurboChessIconGlyph.chessBasicsMastery:
      case TurboChessIconGlyph.settings:
      case TurboChessIconGlyph.howToPlay:
      case TurboChessIconGlyph.legal:
      case TurboChessIconGlyph.about:
        return null;
    }
  }

  static IconData _materialIcon(TurboChessIconGlyph glyph) {
    switch (glyph) {
      case TurboChessIconGlyph.bookmarks:
        return Icons.bookmark_rounded;
      case TurboChessIconGlyph.chessBasicsMastery:
        return Icons.menu_book_rounded;
      case TurboChessIconGlyph.settings:
        return Icons.settings_rounded;
      case TurboChessIconGlyph.howToPlay:
        return Icons.help_outline_rounded;
      case TurboChessIconGlyph.legal:
        return Icons.gavel_rounded;
      case TurboChessIconGlyph.about:
        return Icons.info_outline_rounded;
      case TurboChessIconGlyph.openingDrills:
      case TurboChessIconGlyph.middlegameDrills:
      case TurboChessIconGlyph.endgameDrills:
      case TurboChessIconGlyph.playVsComputer:
      case TurboChessIconGlyph.roadToGm:
        return Icons.circle;
    }
  }
}

class TurboChessIconBadge extends StatelessWidget {
  final TurboChessIconGlyph glyph;
  final Color color;
  final double size;
  final double iconSize;
  final bool glow;
  final BorderRadius? borderRadius;

  const TurboChessIconBadge({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 54,
    double? iconSize,
    this.glow = true,
    this.borderRadius,
  }) : iconSize = iconSize ?? size * 0.54;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(42),
            color.withAlpha(16),
          ],
        ),
        borderRadius: borderRadius ??
            BorderRadius.circular((size * 0.32).clamp(12, 18).toDouble()),
        border: Border.all(color: color.withAlpha(72)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: TurboChessIconSymbol(
        glyph: glyph,
        color: color,
        size: iconSize,
      ),
    );
  }
}
