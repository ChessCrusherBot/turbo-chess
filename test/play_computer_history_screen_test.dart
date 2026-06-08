import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/design_system.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/engine/san_converter.dart';
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
    expect(
      find.byKey(const ValueKey('play_history_detail_card')),
      findsOneWidget,
    );
    expect(find.text('White wins by checkmate!'), findsOneWidget);
    expect(find.textContaining('Starting FEN'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('play_history_details_toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Starting FEN'), findsOneWidget);
    expect(find.textContaining('Final FEN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('play_history_details_toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Starting FEN'), findsNothing);
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('play_history_horizontal_move_strip')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('play_history_horizontal_move_strip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('play_history_move_1')), findsNothing);
    expect(find.text('Move 0 / 2'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    expect(find.text('e2e4'), findsNothing);
    expect(find.text('e7e5'), findsNothing);
    expect(find.textContaining('...'), findsNothing);

    var board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_history_replay_board')),
    );
    expect(board.board.toFen(), ChessBoard.standardStartingFen);

    await tester.tap(find.byKey(const ValueKey('replay_next')));
    await tester.pumpAndSettle();
    expect(find.text('Move 1 / 2'), findsOneWidget);
    expect(_movePillBorderColor(tester, 1), DesignSystem.primaryLight);
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
    expect(_movePillBorderColor(tester, 2), DesignSystem.primaryLight);
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
    expect(find.text('e2e4'), findsNothing);
    expect(find.text('e7e5'), findsNothing);

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

  testWidgets('long replay move strip follows the current move and scrolls',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final record = _recordFromUciMoves(
      id: 'long-game',
      moves: const [
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
        'a7a6',
        'b5a4',
        'g8f6',
        'e1g1',
        'f8e7',
        'f1e1',
        'b7b5',
        'a4b3',
        'd7d6',
        'c2c3',
        'e8g8',
        'h2h3',
        'c6b8',
        'd2d4',
        'b8d7',
        'c3c4',
        'c7c6',
        'c4b5',
        'a6b5',
        'b1c3',
        'c8b7',
        'c1g5',
        'b5b4',
        'c3b1',
        'h7h6',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayComputerHistoryDetailScreen(record: record),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replay_move_counter')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('play_history_horizontal_move_strip')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Move 0 / 30'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('e2e4'), findsNothing);
    expect(find.text('e7e5'), findsNothing);
    expect(find.textContaining('...'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('replay_next')));
    await tester.pumpAndSettle();
    expect(find.text('Move 1 / 30'), findsOneWidget);
    expect(_movePillBorderColor(tester, 1), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 1);

    await tester.tap(find.byKey(const ValueKey('replay_next')));
    await tester.pumpAndSettle();
    expect(find.text('Move 2 / 30'), findsOneWidget);
    expect(_movePillBorderColor(tester, 2), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 2);

    await tester.tap(find.byKey(const ValueKey('replay_next')));
    await tester.pumpAndSettle();
    expect(find.text('Move 3 / 30'), findsOneWidget);
    expect(find.text('2. Nf3'), findsOneWidget);
    expect(_movePillBorderColor(tester, 3), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 3);

    await tester.tap(find.byKey(const ValueKey('replay_last')));
    await tester.pumpAndSettle();
    expect(find.text('Move 30 / 30'), findsOneWidget);
    expect(_movePillBorderColor(tester, 30), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 30);
    expect(_moveStripOffset(tester), greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('play_history_move_pill_29')));
    await tester.pumpAndSettle();
    expect(find.text('Move 29 / 30'), findsOneWidget);
    expect(_movePillBorderColor(tester, 29), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 29);

    await tester.tap(find.byKey(const ValueKey('replay_previous')));
    await tester.pumpAndSettle();
    expect(find.text('Move 28 / 30'), findsOneWidget);
    expect(_movePillBorderColor(tester, 28), DesignSystem.primaryLight);
    _expectMovePillInsideStrip(tester, 28);

    await tester.tap(find.byKey(const ValueKey('replay_first')));
    await tester.pumpAndSettle();
    expect(find.text('Move 0 / 30'), findsOneWidget);
    expect(_moveStripOffset(tester), closeTo(0, 1));
    expect(_movePillBorderColor(tester, 1), isNot(DesignSystem.primaryLight));
  });

  testWidgets('history replay regenerates check and checkmate SAN suffixes',
      (tester) async {
    final checkRecord = _recordFromUciMoves(
      id: 'check-game',
      startingFen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
      moves: const ['a1a8'],
      stripCheckSuffixes: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayComputerHistoryDetailScreen(
          key: const ValueKey('check-record-detail'),
          record: checkRecord,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('play_history_horizontal_move_strip')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('1. Ra8+'), findsOneWidget);
    expect(find.text('1. Ra8'), findsNothing);

    final mateRecord = _recordFromUciMoves(
      id: 'mate-game',
      startingFen: '7k/8/5KQ1/8/8/8/8/8 w - - 0 1',
      moves: const ['g6g7'],
      stripCheckSuffixes: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlayComputerHistoryDetailScreen(
          key: const ValueKey('mate-record-detail'),
          record: mateRecord,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('play_history_horizontal_move_strip')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('1. Qg7#'), findsOneWidget);
    expect(find.text('1. Qg7'), findsNothing);
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

Color? _movePillBorderColor(WidgetTester tester, int ply) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(ValueKey('play_history_move_pill_$ply')),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final decoration = container.decoration as BoxDecoration;
  final border = decoration.border as Border;
  return border.top.color;
}

PlayComputerGameRecord _recordFromUciMoves({
  required String id,
  required List<String> moves,
  String startingFen = ChessBoard.standardStartingFen,
  bool stripCheckSuffixes = false,
}) {
  var board = ChessBoard.fromFen(startingFen);
  final records = <MoveRecord>[];

  for (var index = 0; index < moves.length; index += 1) {
    final uci = moves[index];
    final before = board;
    final san = SanConverter.uciToSan(uci, before);
    final savedSan =
        stripCheckSuffixes ? san.replaceFirst(RegExp(r'[+#]$'), '') : san;
    final after = ChessRules.applyUciMove(before, uci);
    expect(after, isNotNull, reason: 'Expected $uci to be legal');

    records.add(
      MoveRecord(
        move: uci,
        fenBefore: before.toFen(),
        fenAfter: after!.toFen(),
        isUser: before.turn == PieceColor.white,
        moveNumber: (index ~/ 2) + 1,
        sideToMoveBefore: before.turn,
        sideToMoveAfter: after.turn,
        moveSan: savedSan,
      ),
    );
    board = after;
  }

  return PlayComputerGameRecord(
    id: id,
    startedAt: DateTime.utc(2026, 1, 1, 12),
    endedAt: DateTime.utc(2026, 1, 1, 12, 20),
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
    startingFen: startingFen,
    finalFen: board.toFen(),
    moveCount: records.length,
    moves: records,
  );
}

void _expectMovePillInsideStrip(WidgetTester tester, int ply) {
  final stripRect = _globalRect(
    tester,
    find.byKey(const ValueKey('play_history_horizontal_move_strip')),
  );
  final pillRect = _globalRect(
    tester,
    find.byKey(ValueKey('play_history_move_pill_$ply')),
  );

  expect(pillRect.left, greaterThanOrEqualTo(stripRect.left + 1));
  expect(pillRect.right, lessThanOrEqualTo(stripRect.right - 1));
}

double _moveStripOffset(WidgetTester tester) {
  final strip = tester.widget<SingleChildScrollView>(
    find.byKey(const ValueKey('play_history_move_strip_scroll')),
  );
  return strip.controller!.offset;
}

Rect _globalRect(WidgetTester tester, Finder finder) {
  final topLeft = tester.getTopLeft(finder);
  final size = tester.getSize(finder);
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
}
