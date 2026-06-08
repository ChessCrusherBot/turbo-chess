import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/models.dart';

enum TurboModule {
  openings,
  middlegame,
  endgame,
}

extension TurboModuleDesign on TurboModule {
  Color get accentColor {
    switch (this) {
      case TurboModule.openings:
        return DesignSystem.primary;
      case TurboModule.middlegame:
        return DesignSystem.secondary;
      case TurboModule.endgame:
        return DesignSystem.tertiary;
    }
  }

  TurboIconKind get iconKind {
    switch (this) {
      case TurboModule.openings:
        return TurboIconKind.moduleOpenings;
      case TurboModule.middlegame:
        return TurboIconKind.moduleMiddlegame;
      case TurboModule.endgame:
        return TurboIconKind.moduleEndgame;
    }
  }
}

enum TurboIconKind {
  brand,
  moduleOpenings,
  moduleMiddlegame,
  moduleEndgame,
  compass,
  openingSetup,
  sicilian,
  pawnChain,
  shield,
  hypermodern,
  gambit,
  trap,
  transposition,
  plan,
  structure,
  transition,
  blockade,
  recognition,
  speed,
  tactics,
  sacrifice,
  mate,
  file,
  diagonal,
  activity,
  kingSafety,
  space,
  exchange,
  initiative,
  positional,
  center,
  defense,
  calculation,
  decision,
  archive,
  pawnEndgame,
  rookEndgame,
  queenEndgame,
  bishopEndgame,
  knightEndgame,
  opposition,
  promotion,
  fortress,
  study,
  attack,
  fork,
  pin,
  skewer,
  outpost,
  conversion,
  pawnBreak,
  home,
  training,
  playComputer,
  bookmarks,
  more,
  info,
  settings,
  help,
  premium,
  generic,
}

class TurboIconMapper {
  const TurboIconMapper._();

  static TurboIconKind categoryIconFor(OpeningTopic topic) {
    switch (topic.id) {
      case 'principles':
        return TurboIconKind.compass;
      case 'e4_e5':
        return TurboIconKind.openingSetup;
      case 'e4_sicilian':
        return TurboIconKind.sicilian;
      case 'e4_french':
        return TurboIconKind.pawnChain;
      case 'e4_caro':
        return TurboIconKind.shield;
      case 'e4_pirc':
      case 'd4_indian':
      case 'flank':
        return TurboIconKind.hypermodern;
      case 'd4_d5':
        return TurboIconKind.structure;
      case 'd4_dutch':
        return TurboIconKind.initiative;
      case 'gambits_white':
      case 'gambits_black':
        return TurboIconKind.gambit;
      case 'traps':
        return TurboIconKind.trap;
      case 'transpositions':
        return TurboIconKind.transposition;
      case 'typical_plans':
        return TurboIconKind.plan;
      case 'structure_from_opening':
      case 'pawn_struct_mid':
      case 'pawn_struct':
        return TurboIconKind.structure;
      case 'endgame_from_opening':
      case 'endgame_transition':
        return TurboIconKind.transition;
      case 'anti_openings':
        return TurboIconKind.blockade;
      case 'recognition':
        return TurboIconKind.recognition;
      case 'speed_opening':
      case 'speed_mid':
      case 'speed':
        return TurboIconKind.speed;
      case 'tactics1':
      case 'tactical':
        return TurboIconKind.tactics;
      case 'tactics2':
        return TurboIconKind.sacrifice;
      case 'mating':
        return TurboIconKind.mate;
      case 'open_files':
        return TurboIconKind.file;
      case 'diagonals':
        return TurboIconKind.diagonal;
      case 'piece_activity':
        return TurboIconKind.activity;
      case 'king_safety':
        return TurboIconKind.kingSafety;
      case 'space':
        return TurboIconKind.space;
      case 'exchanges':
      case 're_two':
        return TurboIconKind.exchange;
      case 'initiative':
        return TurboIconKind.initiative;
      case 'positional':
        return TurboIconKind.positional;
      case 'center':
        return TurboIconKind.center;
      case 'defense_mid':
      case 'defense':
        return TurboIconKind.defense;
      case 'calculation':
        return TurboIconKind.calculation;
      case 'practical':
        return TurboIconKind.decision;
      case 'famous_mid':
      case 'famous':
        return TurboIconKind.archive;
      case 'ke':
        return TurboIconKind.pawnEndgame;
      case 're':
      case 're_minor':
        return TurboIconKind.rookEndgame;
      case 'qe':
      case 'queen_vs':
        return TurboIconKind.queenEndgame;
      case 'be':
        return TurboIconKind.bishopEndgame;
      case 'ne':
        return TurboIconKind.knightEndgame;
      case 'bvn':
        return TurboIconKind.opposition;
      case 'zugzwang':
        return TurboIconKind.blockade;
      case 'technique':
        return TurboIconKind.conversion;
      case 'master':
        return TurboIconKind.moduleEndgame;
      case 'study':
        return TurboIconKind.study;
    }

    final label = topic.label.toLowerCase();
    if (_has(label, const ['sicilian'])) return TurboIconKind.sicilian;
    if (_has(label, const ['french', 'chain'])) return TurboIconKind.pawnChain;
    if (_has(label, const ['caro', 'defense'])) return TurboIconKind.shield;
    if (_has(label, const ['gambit'])) return TurboIconKind.gambit;
    if (_has(label, const ['trap'])) return TurboIconKind.trap;
    if (_has(label, const ['rook', 'file'])) return TurboIconKind.rookEndgame;
    if (_has(label, const ['queen'])) return TurboIconKind.queenEndgame;
    if (_has(label, const ['bishop', 'diagonal'])) {
      return TurboIconKind.diagonal;
    }
    if (_has(label, const ['knight'])) return TurboIconKind.knightEndgame;
    if (_has(label, const ['mate', 'king'])) return TurboIconKind.mate;
    if (_has(label, const ['pawn', 'structure'])) {
      return TurboIconKind.structure;
    }
    if (_has(label, const ['calculation'])) return TurboIconKind.calculation;
    if (_has(label, const ['endgame'])) return TurboIconKind.moduleEndgame;
    if (_has(label, const ['opening'])) return TurboIconKind.openingSetup;
    return TurboIconKind.generic;
  }

  static TurboIconKind subtopicIconFor(OpeningTopic topic, String subtopic) {
    final text = '${topic.label} $subtopic'.toLowerCase();

    if (_has(text, const ['checkmate', 'mating', 'mate '])) {
      return TurboIconKind.mate;
    }
    if (_has(text, const ['fork'])) return TurboIconKind.fork;
    if (_has(text, const ['pin'])) return TurboIconKind.pin;
    if (_has(text, const ['skewer'])) return TurboIconKind.skewer;
    if (_has(text, const ['trap', 'trick', 'stalemate'])) {
      return TurboIconKind.trap;
    }
    if (_has(text, const ['sacrifice', 'sac ', 'gambit'])) {
      return TurboIconKind.sacrifice;
    }
    if (_has(text, const ['attack', 'initiative', 'pressure', 'tempo'])) {
      return TurboIconKind.attack;
    }
    if (_has(text, const ['defense', 'defensive', 'hold', 'fortress'])) {
      return TurboIconKind.defense;
    }
    if (_has(text, const ['promotion', 'promote', 'queen a pawn'])) {
      return TurboIconKind.promotion;
    }
    if (_has(text, const ['pawn break', 'breakthrough', 'passed pawn'])) {
      return TurboIconKind.pawnBreak;
    }
    if (_has(text, const ['outpost', 'activity', 'active'])) {
      return TurboIconKind.outpost;
    }
    if (_has(text, const ['rook', 'file', 'rank'])) return TurboIconKind.file;
    if (_has(text, const ['bishop', 'diagonal'])) return TurboIconKind.diagonal;
    if (_has(text, const ['knight'])) return TurboIconKind.knightEndgame;
    if (_has(text, const ['opposition', 'zugzwang', 'blockade'])) {
      return TurboIconKind.blockade;
    }
    if (_has(text, const ['calculate', 'calculation', 'visualization'])) {
      return TurboIconKind.calculation;
    }
    if (_has(text, const ['structure', 'isolated', 'backward', 'hanging'])) {
      return TurboIconKind.structure;
    }
    if (_has(text, const ['center', 'central'])) return TurboIconKind.center;
    if (_has(text, const ['convert', 'conversion', 'winning endgame'])) {
      return TurboIconKind.conversion;
    }
    if (_has(text, const ['opening', 'setup', 'move order'])) {
      return TurboIconKind.openingSetup;
    }
    if (_has(text, const ['speed', 'blitz', 'rapid', 'clock'])) {
      return TurboIconKind.speed;
    }
    return categoryIconFor(topic);
  }

  static bool _has(String text, List<String> needles) {
    return needles.any((needle) => text.contains(needle));
  }
}

class TurboIcon extends StatelessWidget {
  final TurboIconKind kind;
  final Color color;
  final double size;
  final Color? secondaryColor;

  const TurboIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 24,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TurboIconPainter(
        kind: kind,
        color: color,
        secondaryColor: secondaryColor,
      ),
    );
  }
}

class TurboIconBadge extends StatelessWidget {
  final TurboIconKind kind;
  final Color color;
  final double size;
  final double iconSize;
  final bool glow;
  final BorderRadius? borderRadius;

  const TurboIconBadge({
    super.key,
    required this.kind,
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
            color.withAlpha(44),
            color.withAlpha(18),
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
      child: TurboIcon(kind: kind, color: color, size: iconSize),
    );
  }
}

class TurboBrandMarkBadge extends StatelessWidget {
  static const String launcherIconAsset =
      'assets/branding/turbo_chess_launcher_icon.png';

  final double size;

  const TurboBrandMarkBadge({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      (size * 0.32).clamp(14, 18).toDouble(),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF172033),
            Color(0xFF081018),
          ],
        ),
        borderRadius: radius,
        border: Border.all(color: DesignSystem.secondary.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.secondary.withAlpha(28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          launcherIconAsset,
          key: const ValueKey('home_turbo_chess_launcher_icon'),
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'Turbo Chess app icon',
        ),
      ),
    );
  }
}

class _TurboIconPainter extends CustomPainter {
  final TurboIconKind kind;
  final Color color;
  final Color? secondaryColor;

  const _TurboIconPainter({
    required this.kind,
    required this.color,
    this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 32;
    final light = secondaryColor ?? Color.lerp(color, Colors.white, 0.38)!;
    final dark = Color.lerp(color, Colors.black, 0.32)!;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final thin = Paint()
      ..color = light.withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solid = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = color.withAlpha(68)
      ..style = PaintingStyle.fill;
    final shade = Paint()
      ..color = dark.withAlpha(120)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.scale(scale, scale);

    switch (kind) {
      case TurboIconKind.brand:
        _drawBrand(canvas, solid, Paint()..color = light, shade);
        break;
      case TurboIconKind.moduleOpenings:
        _drawOpeningModule(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.moduleMiddlegame:
        _drawMiddlegameModule(canvas, stroke, thin, solid, soft);
        break;
      case TurboIconKind.moduleEndgame:
        _drawEndgameModule(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.compass:
        _drawCompass(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.openingSetup:
        _drawOpeningSetup(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.sicilian:
        _drawSicilian(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.pawnChain:
        _drawPawnChain(canvas, stroke, solid);
        break;
      case TurboIconKind.shield:
      case TurboIconKind.defense:
        _drawShield(canvas, stroke, thin, soft);
        break;
      case TurboIconKind.hypermodern:
        _drawHypermodern(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.gambit:
      case TurboIconKind.sacrifice:
        _drawSacrifice(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.trap:
        _drawTrap(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.transposition:
      case TurboIconKind.exchange:
        _drawCrossingArrows(canvas, stroke, solid);
        break;
      case TurboIconKind.plan:
      case TurboIconKind.decision:
        _drawPlan(canvas, stroke, solid);
        break;
      case TurboIconKind.structure:
        _drawStructure(canvas, stroke, solid);
        break;
      case TurboIconKind.transition:
        _drawTransition(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.blockade:
      case TurboIconKind.fortress:
        _drawFortress(canvas, stroke, solid);
        break;
      case TurboIconKind.recognition:
        _drawRecognition(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.speed:
        _drawSpeed(canvas, stroke, solid);
        break;
      case TurboIconKind.tactics:
      case TurboIconKind.attack:
      case TurboIconKind.initiative:
        _drawTactics(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.mate:
      case TurboIconKind.kingSafety:
        _drawMate(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.file:
      case TurboIconKind.rookEndgame:
        _drawFile(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.diagonal:
      case TurboIconKind.bishopEndgame:
        _drawDiagonal(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.activity:
      case TurboIconKind.knightEndgame:
      case TurboIconKind.outpost:
        _drawActivity(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.space:
        _drawSpace(canvas, stroke);
        break;
      case TurboIconKind.positional:
      case TurboIconKind.center:
        _drawCenter(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.calculation:
        _drawCalculation(canvas, stroke, solid);
        break;
      case TurboIconKind.archive:
      case TurboIconKind.study:
        _drawStudy(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.pawnEndgame:
        _drawPawnEndgame(canvas, stroke, solid);
        break;
      case TurboIconKind.queenEndgame:
      case TurboIconKind.promotion:
        _drawPromotion(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.opposition:
        _drawOpposition(canvas, stroke, solid);
        break;
      case TurboIconKind.fork:
        _drawFork(canvas, stroke, solid);
        break;
      case TurboIconKind.pin:
        _drawPin(canvas, stroke, solid);
        break;
      case TurboIconKind.skewer:
        _drawSkewer(canvas, stroke, solid);
        break;
      case TurboIconKind.conversion:
        _drawConversion(canvas, stroke, solid);
        break;
      case TurboIconKind.pawnBreak:
        _drawPawnBreak(canvas, stroke, solid);
        break;
      case TurboIconKind.home:
        _drawHome(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.training:
        _drawTraining(canvas, stroke, solid);
        break;
      case TurboIconKind.playComputer:
        _drawPlayComputer(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.bookmarks:
        _drawBookmarks(canvas, stroke, thin, solid);
        break;
      case TurboIconKind.more:
        _drawMore(canvas, stroke, solid);
        break;
      case TurboIconKind.info:
        _drawInfo(canvas, stroke, solid);
        break;
      case TurboIconKind.settings:
        _drawSettings(canvas, stroke, solid);
        break;
      case TurboIconKind.help:
        _drawHelp(canvas, stroke, solid);
        break;
      case TurboIconKind.premium:
        _drawCrown(canvas, 16, 17, 1, solid, stroke);
        break;
      case TurboIconKind.generic:
        _drawGeneric(canvas, stroke, thin, solid);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TurboIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor;
  }

  void _drawBrand(Canvas canvas, Paint solid, Paint light, Paint shade) {
    final crown = Path()
      ..moveTo(7, 13)
      ..lineTo(10.5, 7.5)
      ..lineTo(14, 12.2)
      ..lineTo(16, 6)
      ..lineTo(18, 12.2)
      ..lineTo(21.5, 7.5)
      ..lineTo(25, 13)
      ..lineTo(23.4, 17)
      ..lineTo(8.6, 17)
      ..close();
    canvas.drawPath(crown, solid);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 17.5, 14, 2.8), const Radius.circular(1.4)),
      light,
    );

    final body = Path()
      ..moveTo(10, 26)
      ..lineTo(22, 26)
      ..cubicTo(21, 22.2, 19.2, 20, 16, 20)
      ..cubicTo(12.8, 20, 11, 22.2, 10, 26)
      ..close();
    canvas.drawPath(body, solid);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 25, 18, 3.2), const Radius.circular(1.6)),
      solid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 28, 22, 3.2), const Radius.circular(1.6)),
      solid,
    );
    final cut = Path()
      ..moveTo(17.8, 20.5)
      ..lineTo(24.5, 15.8)
      ..lineTo(21.8, 22.2)
      ..lineTo(18.8, 22.8)
      ..close();
    canvas.drawPath(cut, shade);
  }

  void _drawOpeningModule(
      Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6.5, 7.5, 19, 17), const Radius.circular(3)),
      stroke,
    );
    canvas.drawLine(const Offset(12, 8), const Offset(12, 24), thin);
    canvas.drawLine(const Offset(19, 8), const Offset(19, 24), thin);
    _drawArrow(canvas, const Offset(10, 21), const Offset(21.5, 11), stroke);
    canvas.drawCircle(const Offset(10, 21), 2.1, solid);
    canvas.drawCircle(const Offset(21.5, 11), 2.1, solid);
  }

  void _drawMiddlegameModule(
      Canvas canvas, Paint stroke, Paint thin, Paint solid, Paint soft) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6.5, 6.5, 19, 19), const Radius.circular(4)),
      soft,
    );
    canvas.drawCircle(const Offset(16, 16), 8.8, stroke);
    _drawArrow(canvas, const Offset(8, 24), const Offset(24, 8), stroke);
    _drawArrow(canvas, const Offset(8, 8), const Offset(24, 24), stroke);
    canvas.drawCircle(const Offset(16, 16), 3.2, solid);
    canvas.drawLine(const Offset(11, 16), const Offset(21, 16), thin);
  }

  void _drawEndgameModule(
      Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawLine(const Offset(6, 26), const Offset(26, 26), thin);
    _drawCrown(canvas, 12, 13, 0.5, solid, stroke);
    _drawPawnAt(canvas, 21, 25, 0.62, solid, stroke);
    canvas.drawLine(const Offset(8, 20), const Offset(22, 20), stroke);
    canvas.drawCircle(const Offset(22, 20), 2.1, solid);
  }

  void _drawCompass(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawBoardDiamond(canvas, stroke, thin);
    final pointer = Path()
      ..moveTo(16, 7)
      ..lineTo(19.4, 17)
      ..lineTo(16, 15.2)
      ..lineTo(12.6, 17)
      ..close();
    canvas.drawPath(pointer, solid);
    canvas.drawCircle(const Offset(16, 16), 2, solid);
  }

  void _drawOpeningSetup(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 7, 18, 18), const Radius.circular(3)),
      stroke,
    );
    canvas.drawLine(const Offset(16, 7), const Offset(16, 25), thin);
    canvas.drawLine(const Offset(7, 16), const Offset(25, 16), thin);
    _drawArrow(canvas, const Offset(11, 22), const Offset(20.5, 12.5), stroke);
    canvas.drawCircle(const Offset(11, 22), 2.2, solid);
  }

  void _drawSicilian(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawLine(const Offset(11, 7), const Offset(11, 25), thin);
    canvas.drawLine(const Offset(21, 7), const Offset(21, 25), thin);
    _drawArrow(canvas, const Offset(8, 23), const Offset(24, 9), stroke);
    canvas.drawCircle(const Offset(11, 21), 2.4, solid);
    canvas.drawCircle(const Offset(21, 11), 2.4, solid);
  }

  void _drawPawnChain(Canvas canvas, Paint stroke, Paint solid) {
    _drawPawnAt(canvas, 10, 24, 0.55, solid, stroke);
    _drawPawnAt(canvas, 16, 18, 0.55, solid, stroke);
    _drawPawnAt(canvas, 22, 12, 0.55, solid, stroke);
    canvas.drawLine(const Offset(11.8, 20), const Offset(14.4, 17.4), stroke);
    canvas.drawLine(const Offset(17.8, 14), const Offset(20.4, 11.4), stroke);
  }

  void _drawShield(Canvas canvas, Paint stroke, Paint thin, Paint soft) {
    final path = Path()
      ..moveTo(16, 5)
      ..lineTo(25, 8.5)
      ..lineTo(23.5, 20)
      ..cubicTo(22.6, 24, 19.6, 27, 16, 28)
      ..cubicTo(12.4, 27, 9.4, 24, 8.5, 20)
      ..lineTo(7, 8.5)
      ..close();
    canvas.drawPath(path, soft);
    canvas.drawPath(path, stroke);
    canvas.drawLine(const Offset(16, 9), const Offset(16, 23), thin);
  }

  void _drawHypermodern(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 2.6, solid);
    canvas.drawArc(const Rect.fromLTWH(7, 7, 18, 18), -0.9, 1.8, false, stroke);
    canvas.drawArc(const Rect.fromLTWH(10, 10, 12, 12), 2.25, 1.8, false, thin);
    canvas.drawLine(const Offset(7, 25), const Offset(25, 7), stroke);
  }

  void _drawSacrifice(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawPawnAt(canvas, 11, 24, 0.68, solid, stroke);
    _drawArrow(canvas, const Offset(15, 21), const Offset(24, 11), stroke);
    canvas.drawLine(const Offset(21, 20), const Offset(25, 24), thin);
    canvas.drawLine(const Offset(25, 20), const Offset(21, 24), thin);
  }

  void _drawTrap(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 8, 18, 16), const Radius.circular(3)),
      stroke,
    );
    canvas.drawLine(const Offset(9, 12), const Offset(23, 12), thin);
    canvas.drawLine(const Offset(11, 22), const Offset(21, 14), stroke);
    canvas.drawCircle(const Offset(21, 14), 2.3, solid);
  }

  void _drawCrossingArrows(Canvas canvas, Paint stroke, Paint solid) {
    _drawArrow(canvas, const Offset(7, 11), const Offset(23, 11), stroke);
    _drawArrow(canvas, const Offset(25, 21), const Offset(9, 21), stroke);
    canvas.drawCircle(const Offset(16, 16), 2.1, solid);
  }

  void _drawPlan(Canvas canvas, Paint stroke, Paint solid) {
    const points = [
      Offset(8, 23),
      Offset(13, 14),
      Offset(19, 18),
      Offset(24, 8),
    ];
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], stroke);
    }
    for (final point in points) {
      canvas.drawCircle(point, 2.6, solid);
    }
  }

  void _drawStructure(Canvas canvas, Paint stroke, Paint solid) {
    _drawPawnAt(canvas, 10, 24, 0.58, solid, stroke);
    _drawPawnAt(canvas, 16, 21, 0.58, solid, stroke);
    _drawPawnAt(canvas, 22, 24, 0.58, solid, stroke);
    canvas.drawLine(const Offset(10, 17), const Offset(22, 17), stroke);
  }

  void _drawTransition(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawPawnAt(canvas, 9.5, 24, 0.55, solid, stroke);
    _drawArrow(canvas, const Offset(14, 18), const Offset(22, 18), stroke);
    _drawCrown(canvas, 23, 13, 0.48, solid, stroke);
    canvas.drawLine(const Offset(20, 24), const Offset(27, 24), thin);
  }

  void _drawFortress(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 12, 18, 13), const Radius.circular(2)),
      stroke,
    );
    for (final x in [8.0, 14.0, 20.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 8, 4, 5), solid);
    }
    canvas.drawLine(const Offset(10, 19), const Offset(22, 19), stroke);
  }

  void _drawRecognition(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    final eye = Path()
      ..moveTo(5.5, 16)
      ..cubicTo(9, 9.5, 23, 9.5, 26.5, 16)
      ..cubicTo(23, 22.5, 9, 22.5, 5.5, 16)
      ..close();
    canvas.drawPath(eye, stroke);
    canvas.drawCircle(const Offset(16, 16), 3.5, solid);
    canvas.drawLine(const Offset(9, 24), const Offset(23, 8), thin);
  }

  void _drawSpeed(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(17, 17), 9, stroke);
    canvas.drawLine(const Offset(17, 17), const Offset(22, 12), stroke);
    canvas.drawCircle(const Offset(17, 17), 1.8, solid);
    _drawLine(canvas, const Offset(5, 11), const Offset(10, 11), stroke);
    _drawLine(canvas, const Offset(4, 17), const Offset(9, 17), stroke);
    _drawLine(canvas, const Offset(5, 23), const Offset(10, 23), stroke);
  }

  void _drawTactics(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    final bolt = Path()
      ..moveTo(18, 4)
      ..lineTo(8, 18)
      ..lineTo(15, 18)
      ..lineTo(13, 28)
      ..lineTo(24, 13.5)
      ..lineTo(17, 13.5)
      ..close();
    canvas.drawPath(bolt, solid);
    canvas.drawLine(const Offset(6, 8), const Offset(10, 12), thin);
    canvas.drawLine(const Offset(24, 22), const Offset(27, 25), stroke);
  }

  void _drawMate(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawCrown(canvas, 16, 12, 0.68, solid, stroke);
    canvas.drawCircle(const Offset(16, 19), 7.4, stroke);
    canvas.drawLine(const Offset(8.6, 19), const Offset(23.4, 19), thin);
    canvas.drawLine(const Offset(16, 11.6), const Offset(16, 26.4), thin);
  }

  void _drawFile(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(11, 6, 10, 21), const Radius.circular(2)),
      stroke,
    );
    canvas.drawLine(const Offset(16, 7), const Offset(16, 26), thin);
    _drawRookAt(canvas, 16, 23, 0.7, solid, stroke);
  }

  void _drawDiagonal(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawLine(const Offset(6, 26), const Offset(26, 6), stroke);
    canvas.drawLine(const Offset(9, 23), const Offset(13, 27), thin);
    canvas.drawLine(const Offset(19, 5), const Offset(23, 9), thin);
    canvas.drawCircle(const Offset(16, 16), 2.7, solid);
  }

  void _drawActivity(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawArc(const Rect.fromLTWH(7, 7, 18, 18), -0.2, 4.9, false, stroke);
    _drawArrow(canvas, const Offset(14, 24), const Offset(24, 20), stroke);
    canvas.drawLine(const Offset(10, 21), const Offset(10, 13), thin);
    canvas.drawLine(const Offset(10, 13), const Offset(17, 13), thin);
    canvas.drawCircle(const Offset(17, 13), 2.4, solid);
  }

  void _drawSpace(Canvas canvas, Paint stroke) {
    _drawLine(canvas, const Offset(7, 13), const Offset(7, 7), stroke);
    _drawLine(canvas, const Offset(7, 7), const Offset(13, 7), stroke);
    _drawLine(canvas, const Offset(25, 13), const Offset(25, 7), stroke);
    _drawLine(canvas, const Offset(25, 7), const Offset(19, 7), stroke);
    _drawLine(canvas, const Offset(7, 19), const Offset(7, 25), stroke);
    _drawLine(canvas, const Offset(7, 25), const Offset(13, 25), stroke);
    _drawLine(canvas, const Offset(25, 19), const Offset(25, 25), stroke);
    _drawLine(canvas, const Offset(25, 25), const Offset(19, 25), stroke);
  }

  void _drawCenter(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 8.5, stroke);
    canvas.drawCircle(const Offset(16, 16), 2.8, solid);
    canvas.drawLine(const Offset(7.5, 16), const Offset(24.5, 16), thin);
    canvas.drawLine(const Offset(16, 7.5), const Offset(16, 24.5), thin);
  }

  void _drawCalculation(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(8, 16), 2.4, solid);
    final targets = [
      const Offset(18, 8),
      const Offset(18, 16),
      const Offset(18, 24)
    ];
    for (final target in targets) {
      canvas.drawLine(const Offset(10, 16), target, stroke);
      canvas.drawCircle(target, 2.2, solid);
    }
    canvas.drawLine(const Offset(20, 8), const Offset(26, 12), stroke);
    canvas.drawLine(const Offset(20, 24), const Offset(26, 20), stroke);
  }

  void _drawStudy(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 6, 16, 20), const Radius.circular(3)),
      stroke,
    );
    canvas.drawLine(const Offset(12, 12), const Offset(20, 12), thin);
    canvas.drawLine(const Offset(12, 17), const Offset(18, 17), thin);
    canvas.drawCircle(const Offset(21, 23), 2.5, solid);
  }

  void _drawPawnEndgame(Canvas canvas, Paint stroke, Paint solid) {
    _drawPawnAt(canvas, 12, 25, 0.72, solid, stroke);
    _drawCrown(canvas, 21, 12, 0.55, solid, stroke);
    canvas.drawLine(const Offset(6, 27), const Offset(26, 27), stroke);
  }

  void _drawPromotion(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawPawnAt(canvas, 11, 25, 0.62, solid, stroke);
    _drawArrow(canvas, const Offset(17, 23), const Offset(22, 12), stroke);
    _drawCrown(canvas, 23, 10, 0.54, solid, stroke);
    canvas.drawLine(const Offset(7, 27), const Offset(25, 27), thin);
  }

  void _drawOpposition(Canvas canvas, Paint stroke, Paint solid) {
    _drawCrown(canvas, 10, 13, 0.48, solid, stroke);
    _drawCrown(canvas, 22, 13, 0.48, solid, stroke);
    canvas.drawLine(const Offset(13, 20), const Offset(19, 20), stroke);
    canvas.drawCircle(const Offset(16, 20), 2, solid);
  }

  void _drawFork(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawLine(const Offset(16, 24), const Offset(16, 12), stroke);
    canvas.drawLine(const Offset(16, 12), const Offset(9, 7), stroke);
    canvas.drawLine(const Offset(16, 12), const Offset(23, 7), stroke);
    canvas.drawCircle(const Offset(16, 24), 2.4, solid);
    canvas.drawCircle(const Offset(9, 7), 2.2, solid);
    canvas.drawCircle(const Offset(23, 7), 2.2, solid);
  }

  void _drawPin(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawLine(const Offset(7, 16), const Offset(25, 16), stroke);
    canvas.drawCircle(const Offset(10, 16), 2.3, solid);
    canvas.drawCircle(const Offset(16, 16), 2.3, solid);
    canvas.drawCircle(const Offset(23, 16), 2.3, solid);
  }

  void _drawSkewer(Canvas canvas, Paint stroke, Paint solid) {
    _drawArrow(canvas, const Offset(6, 22), const Offset(25, 8), stroke);
    canvas.drawCircle(const Offset(12, 17.6), 2.5, solid);
    canvas.drawCircle(const Offset(20, 11.7), 1.9, solid);
  }

  void _drawConversion(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawLine(const Offset(7, 24), const Offset(25, 24), stroke);
    canvas.drawLine(const Offset(7, 19), const Offset(25, 19), stroke);
    _drawArrow(canvas, const Offset(10, 15), const Offset(22, 8), stroke);
    canvas.drawCircle(const Offset(22, 8), 2.2, solid);
  }

  void _drawPawnBreak(Canvas canvas, Paint stroke, Paint solid) {
    _drawPawnAt(canvas, 10, 25, 0.55, solid, stroke);
    _drawPawnAt(canvas, 22, 25, 0.55, solid, stroke);
    _drawArrow(canvas, const Offset(16, 24), const Offset(16, 10), stroke);
    canvas.drawLine(const Offset(12, 16), const Offset(20, 16), stroke);
  }

  void _drawHome(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    final roof = Path()
      ..moveTo(6.5, 15.5)
      ..lineTo(16, 7)
      ..lineTo(25.5, 15.5);
    canvas.drawPath(roof, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 15, 14, 11), const Radius.circular(2.5)),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(13, 18, 6, 8), const Radius.circular(1.4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thin.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = thin.color,
    );
    canvas.drawCircle(const Offset(16, 13.5), 2.1, solid);
    canvas.drawLine(const Offset(11, 26), const Offset(21, 26), thin);
  }

  void _drawTraining(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 10, stroke);
    canvas.drawCircle(const Offset(16, 16), 5.4, stroke);
    canvas.drawCircle(const Offset(16, 16), 2.1, solid);
    _drawArrow(canvas, const Offset(8, 24), const Offset(24, 8), stroke);
    canvas.drawCircle(const Offset(24, 8), 2.2, solid);
  }

  void _drawPlayComputer(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 8, 20, 15), const Radius.circular(3)),
      stroke,
    );
    canvas.drawLine(const Offset(12, 27), const Offset(20, 27), stroke);
    canvas.drawLine(const Offset(16, 23), const Offset(16, 27), thin);
    canvas.drawCircle(const Offset(11, 14), 1.8, solid);
    canvas.drawCircle(const Offset(21, 14), 1.8, solid);
    canvas.drawPath(
      Path()
        ..moveTo(12, 19)
        ..quadraticBezierTo(16, 21.5, 20, 19),
      thin,
    );
    canvas.drawCircle(const Offset(16, 5.8), 1.6, solid);
    canvas.drawLine(const Offset(16, 7.5), const Offset(16, 8.5), thin);
  }

  void _drawBookmarks(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    final bookmark = Path()
      ..moveTo(10, 6)
      ..lineTo(22, 6)
      ..quadraticBezierTo(24, 6, 24, 8)
      ..lineTo(24, 27)
      ..lineTo(16, 22)
      ..lineTo(8, 27)
      ..lineTo(8, 8)
      ..quadraticBezierTo(8, 6, 10, 6)
      ..close();
    canvas.drawPath(bookmark, stroke);
    canvas.drawLine(const Offset(12, 12), const Offset(20, 12), thin);
    canvas.drawLine(const Offset(12, 17), const Offset(18, 17), thin);
    canvas.drawCircle(const Offset(16, 22), 2.1, solid);
  }

  void _drawMore(Canvas canvas, Paint stroke, Paint solid) {
    for (final rect in const [
      Rect.fromLTWH(7, 7, 7, 7),
      Rect.fromLTWH(18, 7, 7, 7),
      Rect.fromLTWH(7, 18, 7, 7),
      Rect.fromLTWH(18, 18, 7, 7),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        stroke,
      );
    }
    canvas.drawCircle(const Offset(16, 16), 1.8, solid);
  }

  void _drawInfo(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 10, stroke);
    canvas.drawCircle(const Offset(16, 10.5), 1.5, solid);
    canvas.drawLine(const Offset(16, 15), const Offset(16, 22), stroke);
  }

  void _drawSettings(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 4.2, stroke);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final from = Offset(16 + math.cos(angle) * 7, 16 + math.sin(angle) * 7);
      final to = Offset(16 + math.cos(angle) * 10, 16 + math.sin(angle) * 10);
      canvas.drawLine(from, to, stroke);
    }
    canvas.drawCircle(const Offset(16, 16), 1.8, solid);
  }

  void _drawHelp(Canvas canvas, Paint stroke, Paint solid) {
    canvas.drawCircle(const Offset(16, 16), 10, stroke);
    final path = Path()
      ..moveTo(12, 13)
      ..cubicTo(12.4, 9.5, 20, 9.5, 20, 13.8)
      ..cubicTo(20, 16.4, 16, 16.5, 16, 19.2);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(const Offset(16, 23), 1.5, solid);
  }

  void _drawGeneric(Canvas canvas, Paint stroke, Paint thin, Paint solid) {
    _drawBoardDiamond(canvas, stroke, thin);
    canvas.drawCircle(const Offset(16, 16), 2.6, solid);
  }

  void _drawBoardDiamond(Canvas canvas, Paint stroke, Paint thin) {
    final board = Path()
      ..moveTo(16, 4.5)
      ..lineTo(27.5, 16)
      ..lineTo(16, 27.5)
      ..lineTo(4.5, 16)
      ..close();
    canvas.drawPath(board, stroke);
    canvas.drawLine(const Offset(10.2, 10.2), const Offset(21.8, 21.8), thin);
    canvas.drawLine(const Offset(21.8, 10.2), const Offset(10.2, 21.8), thin);
  }

  void _drawCrown(Canvas canvas, double x, double y, double scale, Paint solid,
      Paint stroke) {
    final outline = Paint()
      ..color = stroke.color.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, stroke.strokeWidth * scale * 0.45)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(x - 8 * scale, y + 2.5 * scale)
      ..lineTo(x - 5 * scale, y - 4 * scale)
      ..lineTo(x - 1.8 * scale, y + 1.4 * scale)
      ..lineTo(x, y - 5.6 * scale)
      ..lineTo(x + 1.8 * scale, y + 1.4 * scale)
      ..lineTo(x + 5 * scale, y - 4 * scale)
      ..lineTo(x + 8 * scale, y + 2.5 * scale)
      ..lineTo(x + 6.8 * scale, y + 6.3 * scale)
      ..lineTo(x - 6.8 * scale, y + 6.3 * scale)
      ..close();
    canvas.drawPath(path, solid);
    canvas.drawPath(path, outline);
  }

  void _drawPawnAt(Canvas canvas, double x, double y, double scale, Paint solid,
      Paint stroke) {
    final outline = Paint()
      ..color = stroke.color.withAlpha(130)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.65, stroke.strokeWidth * scale * 0.38)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(x, y - 13 * scale), 3.2 * scale, solid);
    canvas.drawCircle(Offset(x, y - 13 * scale), 3.2 * scale, outline);
    final body = Path()
      ..moveTo(x - 5.5 * scale, y - 3.5 * scale)
      ..cubicTo(x - 4.8 * scale, y - 9 * scale, x - 3.2 * scale,
          y - 11.5 * scale, x, y - 11.5 * scale)
      ..cubicTo(x + 3.2 * scale, y - 11.5 * scale, x + 4.8 * scale,
          y - 9 * scale, x + 5.5 * scale, y - 3.5 * scale)
      ..close();
    canvas.drawPath(body, solid);
    canvas.drawPath(body, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x - 6.2 * scale, y - 4.2 * scale, 12.4 * scale, 2.8 * scale),
        Radius.circular(1.4 * scale),
      ),
      solid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 8 * scale, y - 1.8 * scale, 16 * scale, 3.4 * scale),
        Radius.circular(1.7 * scale),
      ),
      solid,
    );
  }

  void _drawRookAt(Canvas canvas, double x, double y, double scale, Paint solid,
      Paint stroke) {
    final outline = Paint()
      ..color = stroke.color.withAlpha(135)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, stroke.strokeWidth * scale * 0.38)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(x - 6 * scale, y - 10 * scale)
      ..lineTo(x - 3.5 * scale, y - 10 * scale)
      ..lineTo(x - 3.5 * scale, y - 7.5 * scale)
      ..lineTo(x - 1 * scale, y - 7.5 * scale)
      ..lineTo(x - 1 * scale, y - 10 * scale)
      ..lineTo(x + 1 * scale, y - 10 * scale)
      ..lineTo(x + 1 * scale, y - 7.5 * scale)
      ..lineTo(x + 3.5 * scale, y - 7.5 * scale)
      ..lineTo(x + 3.5 * scale, y - 10 * scale)
      ..lineTo(x + 6 * scale, y - 10 * scale)
      ..lineTo(x + 4.5 * scale, y - 2 * scale)
      ..lineTo(x - 4.5 * scale, y - 2 * scale)
      ..close();
    canvas.drawPath(path, solid);
    canvas.drawPath(path, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x - 6.5 * scale, y - 2.5 * scale, 13 * scale, 3.5 * scale),
        Radius.circular(1.3 * scale),
      ),
      solid,
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint stroke) {
    canvas.drawLine(from, to, stroke);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - math.cos(angle - math.pi / 6) * 4,
          to.dy - math.sin(angle - math.pi / 6) * 4)
      ..lineTo(to.dx - math.cos(angle + math.pi / 6) * 4,
          to.dy - math.sin(angle + math.pi / 6) * 4)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
  }
}
