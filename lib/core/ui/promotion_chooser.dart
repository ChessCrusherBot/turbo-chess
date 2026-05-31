import 'package:flutter/material.dart';

import '../chess/chess_board.dart';
import 'promotion_dialog.dart';

/// Shows a promotion chooser dialog and returns the selected piece type.
/// Returns null when the user cancels or dismisses the dialog.
Future<PieceType?> showPromotionChooser(
  BuildContext context,
  PieceColor color,
) async {
  final result = await PromotionDialog.show(context, color);
  return switch (result) {
    'r' => PieceType.rook,
    'b' => PieceType.bishop,
    'n' => PieceType.knight,
    'q' => PieceType.queen,
    _ => null,
  };
}
