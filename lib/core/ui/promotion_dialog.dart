import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../chess/chess_board.dart';
import '../design_system.dart';

/// Shows a dialog for the user to choose a promotion piece.
class PromotionDialog extends StatelessWidget {
  final PieceColor color;

  const PromotionDialog({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    const options = [
      _PromotionOption(code: 'q', label: 'Queen', whiteFen: 'Q', blackFen: 'q'),
      _PromotionOption(code: 'r', label: 'Rook', whiteFen: 'R', blackFen: 'r'),
      _PromotionOption(
          code: 'b', label: 'Bishop', whiteFen: 'B', blackFen: 'b'),
      _PromotionOption(
          code: 'n', label: 'Knight', whiteFen: 'N', blackFen: 'n'),
    ];
    final isWhite = color == PieceColor.white;
    final accent = isWhite ? DesignSystem.primaryLight : DesignSystem.secondary;
    final tileBackground =
        isWhite ? const Color(0xFF263041) : const Color(0xFFF0E2C2);

    return SafeArea(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          key: const ValueKey('promotion_dialog_card'),
          constraints: const BoxConstraints(maxWidth: 330),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withAlpha(95)),
              boxShadow: [
                ...DesignSystem.shadowLg,
                BoxShadow(
                  color: accent.withAlpha(26),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(22),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: accent.withAlpha(78)),
                        ),
                        child: Icon(
                          Icons.upgrade_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Promote pawn',
                          style: TextStyle(
                            color: DesignSystem.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Choose a piece',
                    style: TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final option in options)
                            SizedBox(
                              width: tileWidth,
                              child: _PromotionTile(
                                option: option,
                                color: color,
                                accent: accent,
                                tileBackground: tileBackground,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('promotion_cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<String?> show(BuildContext context, PieceColor color) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PromotionDialog(color: color),
    );
  }
}

class _PromotionOption {
  final String code;
  final String label;
  final String whiteFen;
  final String blackFen;

  const _PromotionOption({
    required this.code,
    required this.label,
    required this.whiteFen,
    required this.blackFen,
  });
}

class _PromotionTile extends StatelessWidget {
  final _PromotionOption option;
  final PieceColor color;
  final Color accent;
  final Color tileBackground;

  const _PromotionTile({
    required this.option,
    required this.color,
    required this.accent,
    required this.tileBackground,
  });

  @override
  Widget build(BuildContext context) {
    final fen = color == PieceColor.white ? option.whiteFen : option.blackFen;
    return Semantics(
      button: true,
      label: 'Promote to ${option.label}',
      child: InkWell(
        key: ValueKey('promotion_${color.name}_${option.code}'),
        onTap: () => Navigator.of(context).pop(option.code),
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignSystem.backgroundElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withAlpha(72)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tileBackground,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: color == PieceColor.white
                              ? Colors.white.withAlpha(46)
                              : const Color(0xFF8A6C3F).withAlpha(120),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: SvgPicture.asset(
                          ChessPieceAssets.assetForFenChar(fen),
                          fit: BoxFit.contain,
                          semanticsLabel:
                              '${color == PieceColor.white ? 'White' : 'Black'} ${option.label}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignSystem.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
