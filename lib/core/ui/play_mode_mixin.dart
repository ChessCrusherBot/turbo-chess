import 'package:flutter/material.dart';
import '../chess/chess_board.dart';
import '../design_system.dart';
import '../models/play_mode.dart';
import '../ui_components.dart';

class PlayModePanelWidget extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onResign;
  final VoidCallback onFlipBoard;
  final bool engineThinking;
  final bool isGameOver;
  final GameEndResult? result;
  final PieceColor userColor;
  final ChessBoard board;
  final List<MoveRecord> gameMoves;
  final VoidCallback onResultOptions;
  final VoidCallback onRetry;

  const PlayModePanelWidget({
    super.key,
    required this.accentColor,
    required this.onResign,
    required this.onFlipBoard,
    required this.engineThinking,
    required this.isGameOver,
    required this.result,
    required this.userColor,
    required this.board,
    required this.gameMoves,
    required this.onResultOptions,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final resultData = _resultMeta();
    final userWon =
        result?.winner == (userColor == PieceColor.white ? 'White' : 'Black');
    final sideToMove = board.turn == PieceColor.white ? 'White' : 'Black';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withAlpha(18),
            DesignSystem.backgroundRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(60)),
        boxShadow: DesignSystem.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Drill',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: DesignSystem.textPrimary,
                      ),
                    ),
                    Text(
                      '$sideToMove to move',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (engineThinking)
                const Icon(
                  Icons.memory_rounded,
                  size: 18,
                  color: DesignSystem.primaryLight,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InlineActionChip(
                icon: Icons.flip_rounded,
                label: 'Flip',
                enabled: true,
                onTap: onFlipBoard,
              ),
              _InlineActionChip(
                icon: Icons.flag_rounded,
                label: 'Resign',
                enabled: !isGameOver,
                onTap: onResign,
                color: DesignSystem.error,
              ),
            ],
          ),
          if (engineThinking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Engine is thinking...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignSystem.textMuted,
                  ),
                ),
              ],
            ),
          ],
          if (board.halfMoveClock > 40) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: DesignSystem.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  '50-move rule: ${100 - board.halfMoveClock} half-moves remaining',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DesignSystem.warningLight,
                  ),
                ),
              ],
            ),
          ],
          if (isGameOver && result != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (result!.isDraw
                        ? resultData.$2
                        : (userWon ? DesignSystem.success : DesignSystem.error))
                    .withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(resultData.$1, color: resultData.$2, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result!.message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DesignSystem.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: 'Result Options',
                    icon: Icons.fact_check_rounded,
                    onPressed: onResultOptions,
                    fullWidth: true,
                    backgroundColor: DesignSystem.primary,
                    glowColor: DesignSystem.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DesignSystem.textMuted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry Drill'),
                  ),
                ),
              ],
            ),
          ],
          if (gameMoves.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < gameMoves.length; i++)
                    Text(
                      gameMoves[i].toDisplayString((i ~/ 2) + 1),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        color:
                            gameMoves[i].isUser ? accentColor : Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color) _resultMeta() {
    switch (result?.reason) {
      case '50-Move Rule':
        return (Icons.timer_off_rounded, DesignSystem.warning);
      case 'Threefold Repetition':
        return (Icons.repeat_rounded, DesignSystem.primary);
      case 'Insufficient Material':
        return (Icons.remove_circle_outline, DesignSystem.textMuted);
      case 'Stalemate':
        return (Icons.do_not_disturb_on_rounded, DesignSystem.secondary);
      case 'Resignation':
        return (Icons.flag_rounded, DesignSystem.error);
      case 'Checkmate':
        final userWon = result?.winner ==
            (userColor == PieceColor.white ? 'White' : 'Black');
        return userWon
            ? (Icons.flag_rounded, DesignSystem.success)
            : (Icons.sentiment_dissatisfied_rounded, DesignSystem.error);
      default:
        if (result?.isDraw == true) {
          return (Icons.remove_circle_outline, DesignSystem.warning);
        }
        return (Icons.flag_rounded, DesignSystem.success);
    }
  }
}

class _InlineActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? color;

  const _InlineActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? DesignSystem.textPrimary;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DesignSystem.backgroundSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DesignSystem.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
