import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';

void main() {
  testWidgets('board accepts last move and suggestion highlights',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChessBoardWidget(
              board: ChessBoard.starting(),
              size: 280,
              lastMoveFrom: 'e2',
              lastMoveTo: 'e4',
              suggestedMoveFrom: 'g1',
              suggestedMoveTo: 'f3',
              legalMoves: const ['e4', 'd4'],
              selectedSquare: 'e2',
              checkSquare: 'e1',
            ),
          ),
        ),
      ),
    );

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.lastMoveFrom, 'e2');
    expect(board.lastMoveTo, 'e4');
    expect(board.suggestedMoveFrom, 'g1');
    expect(board.suggestedMoveTo, 'f3');
    expect(tester.takeException(), isNull);
  });
}
