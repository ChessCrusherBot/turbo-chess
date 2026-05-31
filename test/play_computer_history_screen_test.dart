import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/models/play_mode.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_history_store.dart';
import 'package:turbo_chess/features/play_computer/domain/play_computer_game_record.dart';
import 'package:turbo_chess/features/play_computer/presentation/play_computer_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history detail shows replay board and stepping controls',
      (tester) async {
    final record = PlayComputerGameRecord(
      id: 'game-one',
      startedAt: DateTime.utc(2026, 1, 1, 12),
      endedAt: DateTime.utc(2026, 1, 1, 12, 5),
      userColor: PieceColor.white,
      engineColor: PieceColor.black,
      result: 'user_checkmate_win',
      resultText: 'White wins by checkmate!',
      resultReason: 'Checkmate',
      winner: 'White',
      timeControlLabel: 'No Time Control',
      noTimeControl: true,
      engineProfileName: 'Strong',
      engineDepth: 12,
      engineSkill: 12,
      engineMoveTimeMs: 800,
      startingFen: ChessBoard.standardStartingFen,
      finalFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
      moveCount: 2,
      moves: const [
        MoveRecord(
          move: 'e2e4',
          fenBefore: ChessBoard.standardStartingFen,
          fenAfter:
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          isUser: true,
          moveNumber: 1,
          sideToMoveBefore: PieceColor.white,
          sideToMoveAfter: PieceColor.black,
          moveSan: 'e4',
        ),
        MoveRecord(
          move: 'e7e5',
          fenBefore:
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          fenAfter:
              'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
          isUser: false,
          moveNumber: 1,
          sideToMoveBefore: PieceColor.black,
          sideToMoveAfter: PieceColor.white,
          moveSan: 'e5',
        ),
      ],
    );

    SharedPreferences.setMockInitialValues({
      PlayComputerHistoryStore.preferencesKey: [jsonEncode(record.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(home: PlayComputerHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('You won'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('play_history_record_game-one')));
    await tester.pumpAndSettle();

    expect(find.text('Game Replay'), findsOneWidget);
    expect(find.byKey(const ValueKey('play_history_replay_board')),
        findsOneWidget);
    final replayBoardSize =
        tester.getSize(find.byKey(const ValueKey('play_history_replay_board')));
    expect(replayBoardSize.width, closeTo(replayBoardSize.height, 1));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replay_move_counter')),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('replay_move_counter')), findsOneWidget);
    expect(find.text('Move 0 / 2'), findsOneWidget);
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    expect(find.text('e2e4'), findsOneWidget);
    expect(find.text('e7e5'), findsOneWidget);

    var board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(board.board.toFen(), ChessBoard.standardStartingFen);

    await tester.tap(find.byKey(const ValueKey('replay_next')));
    await tester.pumpAndSettle();
    expect(find.text('Move 1 / 2'), findsOneWidget);
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(
      board.board.toFen(),
      ChessRules.applyUciMove(
        ChessBoard.fromFen(ChessBoard.standardStartingFen),
        'e2e4',
      )!
          .toFen(),
    );

    await tester.tap(find.text('e5'));
    await tester.pumpAndSettle();
    expect(find.text('Move 2 / 2'), findsOneWidget);
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    final afterE4 = ChessRules.applyUciMove(
      ChessBoard.fromFen(ChessBoard.standardStartingFen),
      'e2e4',
    )!;
    expect(
      board.board.toFen(),
      ChessRules.applyUciMove(afterE4, 'e7e5')!.toFen(),
    );

    await tester.tap(find.byKey(const ValueKey('replay_previous')));
    await tester.pumpAndSettle();
    expect(find.text('Move 1 / 2'), findsOneWidget);
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(board.board.toFen(), afterE4.toFen());

    await tester.tap(find.byKey(const ValueKey('replay_first')));
    await tester.pumpAndSettle();
    expect(find.text('Move 0 / 2'), findsOneWidget);
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(board.board.toFen(), ChessBoard.standardStartingFen);

    await tester.tap(find.byKey(const ValueKey('replay_last')));
    await tester.pumpAndSettle();
    expect(find.text('Move 2 / 2'), findsOneWidget);
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(board.board.toFen(), record.finalFen);
  });

  testWidgets('history detail handles old record without UCI moves',
      (tester) async {
    final record = PlayComputerGameRecord(
      id: 'old-game',
      startedAt: DateTime.utc(2026, 1, 1, 12),
      endedAt: DateTime.utc(2026, 1, 1, 12, 5),
      userColor: PieceColor.white,
      engineColor: PieceColor.black,
      result: 'draw',
      resultText: 'Game over.',
      resultReason: 'Draw',
      winner: null,
      timeControlLabel: 'No Time Control',
      noTimeControl: true,
      engineProfileName: 'Strong',
      engineDepth: 12,
      engineSkill: 12,
      engineMoveTimeMs: 800,
      startingFen: ChessBoard.standardStartingFen,
      finalFen: ChessBoard.standardStartingFen,
      moveCount: 0,
      moves: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayComputerHistoryDetailScreen(record: record),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('play_history_replay_board')),
        findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No moves were played.'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('No moves were played.'), findsOneWidget);
  });
}
