import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_history_store.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_active_game_store.dart';
import 'package:turbo_chess/features/play_computer/presentation/play_computer_history_screen.dart';
import 'package:turbo_chess/core/engine/play_vs_engine.dart';
import 'package:turbo_chess/features/play_computer/presentation/play_vs_computer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TurboSoundService.instance.debugResetForTesting();
  });

  testWidgets('setup screen renders standard play options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    expect(find.text('Computer Setup'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Random'), findsOneWidget);
    expect(find.byKey(const ValueKey('time_control_toggle')), findsOneWidget);
    final timeToggle = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('time_control_toggle')),
    );
    expect(timeToggle.value, isFalse);
    expect(find.text('No Clock'), findsNothing);
    expect(find.text('No clock'), findsNothing);
    expect(find.textContaining('Play freely'), findsNothing);
    expect(find.byKey(const ValueKey('no_time_control_summary')), findsNothing);
    expect(find.text('15 seconds'), findsNothing);
    expect(find.text('Paste FEN'), findsOneWidget);
    expect(find.byKey(const ValueKey('play_history_button')), findsOneWidget);
    expect(find.textContaining('Chess960'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Engine'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Engine'), findsOneWidget);
    expect(find.text('Skill: 20'), findsOneWidget);
  });

  testWidgets('setup start game button stays fixed while options scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await tester.pump();

    final startButton = find.byKey(const ValueKey('start_computer_game'));
    final footer = find.byKey(const ValueKey('play_setup_sticky_footer'));
    final setupList = find.byKey(const ValueKey('play_setup_list'));

    expect(startButton, findsOneWidget);
    expect(footer, findsOneWidget);

    final initialButtonTop = tester.getTopLeft(startButton).dy;
    final initialFooterRect = _globalRect(tester, footer);

    await tester.drag(setupList, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(startButton).dy, closeTo(initialButtonTop, 1));
    expect(_globalRect(tester, footer).top, closeTo(initialFooterRect.top, 1));

    await tester.scrollUntilVisible(
      find.text('Move feedback'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final footerRect = _globalRect(tester, footer);
    final moveFeedbackRect = _globalRect(tester, find.text('Move feedback'));
    expect(moveFeedbackRect.bottom, lessThanOrEqualTo(footerRect.top + 1));
    expect(tester.getTopLeft(startButton).dy, closeTo(initialButtonTop, 1));
  });

  testWidgets('color selection works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.tap(find.text('Black'));
    await tester.pump();

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Black'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('time control toggle reveals presets and selection works', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    expect(find.text('15 seconds'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('time_control_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('15 seconds'), findsOneWidget);

    await tester.tap(find.text('10+5'));
    await tester.pump();

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '10+5'),
    );
    expect(chip.selected, isTrue);

    await tester.tap(find.byKey(const ValueKey('time_control_toggle')));
    await tester.pumpAndSettle();

    expect(find.text('15 seconds'), findsNothing);
    expect(find.text('10+5'), findsNothing);
  });

  testWidgets('No Time Control starts a game without clocks or timeout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await _scrollSetupToStart(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));

    expect(find.text('No clock'), findsNothing);
    expect(find.text('No Clock'), findsNothing);
    expect(find.textContaining('wins on time'), findsNothing);
    expect(find.text('Bookmark'), findsNothing);
  });

  testWidgets('timed setup starts a game with visible clocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.tap(find.byKey(const ValueKey('time_control_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 seconds'));
    await tester.pump();

    await _scrollSetupToStart(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();

    expect(find.text('0:15'), findsWidgets);
  });

  testWidgets('eval bar on does not overflow on a small phone', (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    expect(find.byKey(const ValueKey('play_evaluation_bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('play_chess_board_area')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar on keeps board inside available layout width',
      (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    final layoutRect = _globalRect(
        tester, find.byKey(const ValueKey('play_eval_board_layout')));
    final evalRect =
        _globalRect(tester, find.byKey(const ValueKey('play_evaluation_bar')));
    final boardRect = _globalRect(
        tester, find.byKey(const ValueKey('play_chess_board_area')));
    final gap = boardRect.left - evalRect.right;

    expect(evalRect.left, greaterThanOrEqualTo(layoutRect.left - 1));
    expect(boardRect.right, lessThanOrEqualTo(layoutRect.right + 1));
    expect(
      evalRect.width + gap + boardRect.width,
      lessThanOrEqualTo(layoutRect.width + 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar on keeps board square', (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    _expectPlayBoardSquare(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar height equals board height', (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    final evalSize = tester.getSize(
      find.byKey(const ValueKey('play_evaluation_bar')),
    );
    final boardSize = tester.getSize(
      find.byKey(const ValueKey('play_chess_board_area')),
    );

    expect(evalSize.height, closeTo(boardSize.height, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar top aligns with board top', (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    final evalRect =
        _globalRect(tester, find.byKey(const ValueKey('play_evaluation_bar')));
    final boardRect = _globalRect(
        tester, find.byKey(const ValueKey('play_chess_board_area')));

    expect(evalRect.top, closeTo(boardRect.top, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar bottom aligns with board bottom', (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    final evalRect =
        _globalRect(tester, find.byKey(const ValueKey('play_evaluation_bar')));
    final boardRect = _globalRect(
        tester, find.byKey(const ValueKey('play_chess_board_area')));

    expect(evalRect.bottom, closeTo(boardRect.bottom, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('eval bar off keeps normal square board layout', (tester) async {
    await _pumpSmallPhonePlayScreen(tester);
    await _startComputerGame(tester);

    expect(find.byKey(const ValueKey('play_evaluation_bar')), findsNothing);
    expect(find.byKey(const ValueKey('play_chess_board_area')), findsOneWidget);
    _expectPlayBoardSquare(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flip with eval bar on keeps board visible and square',
      (tester) async {
    await _startComputerGameWithEvaluationBar(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Flip'));
    await tester.pump();

    _expectPlayBoardSquare(tester);
    final board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_chess_board_area')),
    );
    expect(board.flipped, isTrue);
    _expectPlayBoardInsideLayout(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('move with eval bar on keeps highlights aligned', (tester) async {
    await _startComputerGameWithEvaluationBar(
      tester,
      engineMoveProvider: (_, __, ___) async => null,
    );

    await _tapBoardSquare(tester, 'e2');
    var board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_chess_board_area')),
    );
    expect(board.selectedSquare, 'e2');
    expect(board.legalMoves, contains('e4'));

    await _tapBoardSquare(tester, 'e4');
    await tester.pump(const Duration(milliseconds: 100));
    board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_chess_board_area')),
    );

    expect(board.lastMoveFrom, 'e2');
    expect(board.lastMoveTo, 'e4');
    _expectPlayBoardInsideLayout(tester);
    _expectPlayBoardSquare(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('engine move with eval bar on keeps rail and board aligned',
      (tester) async {
    await _startComputerGameWithEvaluationBar(
      tester,
      engineMoveProvider: (_, __, ___) async => 'e7e5',
    );

    await _tapBoardSquare(tester, 'e2');
    await _tapBoardSquare(tester, 'e4');
    await tester.pump(const Duration(milliseconds: 100));

    final board = tester.widget<ChessBoardWidget>(
      find.byKey(const ValueKey('play_chess_board_area')),
    );
    expect(board.lastMoveFrom, 'e7');
    expect(board.lastMoveTo, 'e5');
    _expectPlayBoardInsideLayout(tester);
    _expectEvalBarAlignedWithBoard(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Max Power applies safe maximum engine settings and restores', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('max_power_toggle')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    var maxPowerTile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('max_power_toggle')),
    );
    expect(maxPowerTile.value, isFalse);
    expect(find.text('Max Power'), findsOneWidget);
    expect(
      find.text(
        'Recommended for powerful phones only. Uses more battery and processing power.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('max_power_toggle')));
    await tester.pumpAndSettle();

    maxPowerTile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('max_power_toggle')),
    );
    expect(maxPowerTile.value, isTrue);
    expect(find.text('Depth: 20'), findsOneWidget);
    expect(find.text('Move time: 3000ms'), findsOneWidget);
    expect(find.text('Skill: 20'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('max_power_toggle')));
    await tester.pumpAndSettle();

    maxPowerTile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('max_power_toggle')),
    );
    expect(maxPowerTile.value, isFalse);
    expect(find.text('Depth: 12'), findsOneWidget);
    expect(find.text('Move time: 800ms'), findsOneWidget);
    expect(find.text('Skill: 20'), findsOneWidget);
  });

  testWidgets('Recommended settings keeps default Skill 20', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.scrollUntilVisible(
      find.text('Recommended settings'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recommended settings'));
    await tester.pumpAndSettle();

    expect(find.text('Skill: 20'), findsOneWidget);
  });

  testWidgets('History icon opens empty history state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/history') {
            return MaterialPageRoute<void>(
              builder: (_) => const PlayComputerHistoryScreen(),
            );
          }
          return null;
        },
        home: const PlayVsComputerScreen(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('play_history_button')));
    await tester.pumpAndSettle();

    expect(find.text('No games yet'), findsOneWidget);
    expect(find.text('Finished games will appear here.'), findsOneWidget);
  });

  testWidgets('history icon shows centered board overlay during unfinished game',
      (tester) async {
    var historyOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/history') {
            historyOpened = true;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('History route')),
            );
          }
          return null;
        },
        home: const PlayVsComputerScreen(),
      ),
    );

    await _startComputerGame(tester);
    expect(find.text('White to move'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('play_history_button')));
    await tester.pump();

    expect(
      find.text('Finish or resign the current game to view history.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('play_history_blocked_overlay')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(historyOpened, isFalse);
    expect(find.text('History route'), findsNothing);
    expect(find.text('White to move'), findsOneWidget);

    final boardCenter =
        tester.getCenter(find.byKey(const ValueKey('play_chess_board_area')));
    final overlayCenter = tester
        .getCenter(find.byKey(const ValueKey('play_history_blocked_overlay')));
    expect((overlayCenter.dx - boardCenter.dx).abs(), lessThan(1));
    expect((overlayCenter.dy - boardCenter.dy).abs(), lessThan(1));

    await tester.tap(find.byKey(const ValueKey('play_history_button')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('play_history_blocked_overlay')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('play_history_blocked_overlay')),
      findsNothing,
    );
    expect(
      find.text('Finish or resign the current game to view history.'),
      findsNothing,
    );
  });

  testWidgets('paste FEN validates side to move', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.tap(find.text('Paste FEN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
    );
    await tester.pump();

    expect(find.text('White to move'), findsOneWidget);
  });

  testWidgets('invalid pasted FEN is rejected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );

    await tester.tap(find.text('Paste FEN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'invalid-fen');
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('play_setup_list')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('play_setup_list')),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid standard chess FEN.'), findsOneWidget);
    expect(find.text('Computer Setup'), findsOneWidget);
  });

  testWidgets('pasted FEN reset returns to pasted FEN, not starting board', (
    tester,
  ) async {
    const fen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    var board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen);

    await tester.scrollUntilVisible(
      find.text('Reset'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Reset game?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen);
    expect(board.board.toFen(), isNot(ChessBoard.standardStartingFen));
  });

  testWidgets('Play vs Computer move triggers sound service', (tester) async {
    const fen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen(initialFen: fen)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(soundService.debugSoundPlayCount, greaterThan(0));
  });

  testWidgets('Play vs Computer engine move triggers sound service',
      (tester) async {
    const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => 'e8e7',
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'e2');
    await _tapBoardSquare(tester, 'e3');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(soundService.debugSoundEvents, contains(TurboSoundEvent.move));
    expect(soundService.debugSoundPlayCount, greaterThanOrEqualTo(2));
  });

  testWidgets('promotion cancel does not move or play sound', (tester) async {
    const fen = '7k/P7/8/8/8/8/8/4K3 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          key: const ValueKey('active_save_screen'),
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'a7');
    await _tapBoardSquare(tester, 'a8');
    await tester.pumpAndSettle();

    expect(find.text('Promote pawn'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('promotion_cancel')));
    await tester.pumpAndSettle();

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen);
    expect(soundService.debugSoundPlayCount, 0);
  });

  testWidgets('promotion selection applies move once and plays sound',
      (tester) async {
    const fen = '7k/P7/8/8/8/8/8/4K3 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'a7');
    await _tapBoardSquare(tester, 'a8');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.pieces['a8']?.type, PieceType.queen);
    expect(soundService.debugSoundPlayCount, 1);
  });

  testWidgets('active game autosaves and resume restores current FEN',
      (tester) async {
    const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
    const activeStore = PlayComputerActiveGameStore();

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'e2');
    await _tapBoardSquare(tester, 'e3');
    await tester.pump(const Duration(milliseconds: 100));

    final saved = await activeStore.load();
    expect(saved, isNotNull);
    expect(saved!.startingFen, fen);
    expect(saved.moves, hasLength(1));
    expect(saved.engineSkill, 20);
    expect(saved.currentFen, isNot(fen));

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          key: const ValueKey('active_restore_screen'),
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume unfinished game?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume_active_play_game')));
    await tester.pumpAndSettle();

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), saved.currentFen);
  });

  testWidgets('resume route restores unfinished game without a second prompt',
      (tester) async {
    const activeStore = PlayComputerActiveGameStore();
    final afterE4 = ChessRules.applyUciMove(
      ChessBoard.fromFen(ChessBoard.standardStartingFen),
      'e2e4',
    )!;
    final afterE5 = ChessRules.applyUciMove(afterE4, 'e7e5')!;
    await activeStore.save(
      PlayComputerActiveGameSnapshot(
        startedAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
        startingFen: ChessBoard.standardStartingFen,
        currentFen: afterE5.toFen(),
        userColor: PieceColor.white,
        engineColor: PieceColor.black,
        engineProfileId: 'strong',
        engineDepth: 12,
        engineSkill: 20,
        engineMoveTimeMs: 800,
        engineThreads: 1,
        engineHashMb: 32,
        maxPowerEnabled: false,
        boardFlipped: false,
        timeControlLabel: 'No Time Control',
        timeControlEnabled: false,
        noTimeControl: true,
        timeControlBaseMs: null,
        timeControlIncrementMs: 0,
        whiteRemainingMs: null,
        blackRemainingMs: null,
        clockActiveSide: null,
        clockRunning: false,
        moves: const [],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PlayVsComputerScreen(resumeActiveOnOpen: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume unfinished game?'), findsNothing);
    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), afterE5.toFen());
  });

  testWidgets('discard active game clears unfinished save only',
      (tester) async {
    const activeStore = PlayComputerActiveGameStore();
    final after = ChessRules.applyUciMove(
      ChessBoard.fromFen(ChessBoard.standardStartingFen),
      'e2e4',
    )!;
    await activeStore.save(
      PlayComputerActiveGameSnapshot(
        startedAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
        startingFen: ChessBoard.standardStartingFen,
        currentFen: after.toFen(),
        userColor: PieceColor.white,
        engineColor: PieceColor.black,
        engineProfileId: 'strong',
        engineDepth: 12,
        engineSkill: 20,
        engineMoveTimeMs: 800,
        engineThreads: 1,
        engineHashMb: 32,
        maxPowerEnabled: false,
        boardFlipped: false,
        timeControlLabel: 'No Time Control',
        timeControlEnabled: false,
        noTimeControl: true,
        timeControlBaseMs: null,
        timeControlIncrementMs: 0,
        whiteRemainingMs: null,
        blackRemainingMs: null,
        clockActiveSide: null,
        clockRunning: false,
        moves: const [],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('discard_active_play_game')));
    await tester.pumpAndSettle();

    expect(await activeStore.load(), isNull);
  });

  testWidgets('corrupt unfinished save prompts for discard instead of crashing',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      PlayComputerActiveGameStore.preferencesKey: 'not json',
    });
    const activeStore = PlayComputerActiveGameStore();

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume unfinished game?'), findsOneWidget);
    expect(
      find.text('This unfinished game cannot be restored.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discard_active_play_game')));
    await tester.pumpAndSettle();

    expect(await activeStore.hasSavedSnapshotData(), isFalse);
  });

  testWidgets('illegal Play vs Computer tap does not trigger sound', (
    tester,
  ) async {
    const fen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen(initialFen: fen)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'a1');
    await tester.pump(const Duration(milliseconds: 50));

    expect(soundService.debugSoundPlayCount, 0);
  });

  testWidgets('Play vs Computer reset does not spam move sound', (
    tester,
  ) async {
    const fen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen(initialFen: fen)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reset'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset game?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(soundService.debugSoundPlayCount, 0);
  });

  testWidgets('Play vs Computer reset Cancel keeps current board', (
    tester,
  ) async {
    const fen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        home: PlayVsComputerScreen(
          initialFen: fen,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'e3');
    await _tapBoardSquare(tester, 'd3');
    await tester.pumpAndSettle();
    final movedFen = tester
        .widget<ChessBoardWidget>(find.byType(ChessBoardWidget))
        .board
        .toFen();
    expect(movedFen, isNot(fen));

    await tester.scrollUntilVisible(
      find.text('Reset'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Reset game?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), movedFen);
  });

  testWidgets('invalid initial FEN does not silently start from normal board', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen(initialFen: 'invalid-fen')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid standard chess FEN.'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsNothing);
  });

  testWidgets(
      'active game system back shows resign leave dialog and Cancel stays',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await _startComputerGame(tester);

    await _sendSystemBack(tester);

    expect(find.text('Resign game?'), findsOneWidget);
    expect(
      find.text(
        'You are currently playing against the computer. If you leave now, this game will end as a resignation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Resign & Leave'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Play vs Computer'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsOneWidget);
  });

  testWidgets('system back resigns and leaves once with correct white result',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await _startComputerGame(tester);

    await _sendSystemBack(tester);
    await tester.tap(find.text('Resign & Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Computer Setup'), findsOneWidget);

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.resultReason, 'Resignation');
    expect(records.single.winner, 'Black');
    expect(records.single.result, 'resign');
  });

  testWidgets('app bar back uses the resign leave flow', (tester) async {
    await _pumpRoutedPlayScreen(tester);
    await tester.tap(find.byKey(const ValueKey('open_play_screen')));
    await tester.pumpAndSettle();
    await _startComputerGame(tester);

    await tester.tap(find.byKey(const ValueKey('play_back_button')));
    await tester.pump();

    expect(find.text('Resign game?'), findsOneWidget);

    await tester.tap(find.text('Resign & Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Play launcher'), findsOneWidget);
    expect(find.text('Play vs Computer'), findsNothing);
  });

  testWidgets('setup screen back does not show resign confirmation',
      (tester) async {
    await _pumpRoutedPlayScreen(tester);
    await tester.tap(find.byKey(const ValueKey('open_play_screen')));
    await tester.pumpAndSettle();

    await _sendSystemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Resign game?'), findsNothing);
    expect(find.text('Play launcher'), findsOneWidget);
  });

  testWidgets('checkmate saves history and shows result panel', (tester) async {
    const mateFen = '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/history') {
            return MaterialPageRoute<void>(
              builder: (_) => const PlayComputerHistoryScreen(),
            );
          }
          return null;
        },
        home: const PlayVsComputerScreen(initialFen: mateFen),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('You Won'), findsOneWidget);
    expect(find.text('Checkmate'), findsWidgets);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
    expect(find.textContaining('Game Review'), findsNothing);

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.startingFen, mateFen);
    expect(records.single.resultReason, 'Checkmate');
    expect(records.single.finalFen, mateFen);
    expect(await const PlayComputerActiveGameStore().load(), isNull);
  });

  testWidgets('stalemate shows draw result panel', (tester) async {
    const stalemateFen = '7k/8/6Q1/5K2/8/8/8/8 b - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/history') {
            return MaterialPageRoute<void>(
              builder: (_) => const PlayComputerHistoryScreen(),
            );
          }
          return null;
        },
        home: const PlayVsComputerScreen(initialFen: stalemateFen),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Stalemate'), findsWidgets);
    expect(find.text('Draw by stalemate.'), findsWidgets);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.resultReason, 'Stalemate');
  });

  testWidgets('back after game over does not show resign confirmation',
      (tester) async {
    const mateFen = '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1';

    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen(initialFen: mateFen)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('You Won'), findsOneWidget);

    await _sendSystemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Resign game?'), findsNothing);
  });

  testWidgets('resign shows result panel and saves a record', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/history') {
            return MaterialPageRoute<void>(
              builder: (_) => const PlayComputerHistoryScreen(),
            );
          }
          return null;
        },
        home: const PlayVsComputerScreen(),
      ),
    );

    await _scrollSetupToStart(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Resign'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Resign'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Resign'));
    await tester.pumpAndSettle();

    expect(find.text('You Lost'), findsOneWidget);
    expect(find.text('Resignation'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.resultReason, 'Resignation');
    expect(await const PlayComputerActiveGameStore().load(), isNull);
  });

  testWidgets('black resignation records White as winner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await tester.tap(find.text('Black'));
    await tester.pump();
    await _startComputerGame(tester);

    await _sendSystemBack(tester);
    await tester.tap(find.text('Resign & Leave'));
    await tester.pumpAndSettle();

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.userColorLabel, 'Black');
    expect(records.single.winner, 'White');
    expect(records.single.resultReason, 'Resignation');
  });

  testWidgets('back while resign leave dialog is open cancels and stays',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVsComputerScreen()),
    );
    await _startComputerGame(tester);

    await _sendSystemBack(tester);

    expect(find.text('Resign game?'), findsOneWidget);

    await _sendSystemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Resign game?'), findsNothing);
    expect(find.text('Play vs Computer'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsOneWidget);

    const store = PlayComputerHistoryStore();
    final records = await store.load();
    expect(records, isEmpty);
  });

  test('user black triggers engine first move state', () {
    final game = PlayVsEngine(
      startingFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      userColor: PieceColor.black,
    );
    addTearDown(game.dispose);

    game.start();

    expect(game.state, PlayState.engineThinking);
  });

  test('engine timeout request forces a legal fallback move without game over',
      () async {
    final blockedEngine = Completer<String?>();
    final game = PlayVsEngine(
      startingFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      userColor: PieceColor.black,
      engineMoveProvider: (_, __, ___) => blockedEngine.future,
    );
    addTearDown(game.dispose);

    game.start();
    expect(game.state, PlayState.engineThinking);

    game.requestImmediateEngineMove();
    await pumpEventQueue();

    expect(game.isGameOver, isFalse);
    expect(game.state, PlayState.userTurn);
    expect(game.moves, hasLength(1));
    expect(game.moves.single.isUser, isFalse);
    expect(game.result?.reason, isNot('Timeout'));
  });

  test('resigning while engine is thinking ignores a late engine move',
      () async {
    final blockedEngine = Completer<String?>();
    final game = PlayVsEngine(
      startingFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      userColor: PieceColor.black,
      engineMoveProvider: (_, __, ___) => blockedEngine.future,
    );
    addTearDown(game.dispose);

    game.start();
    expect(game.state, PlayState.engineThinking);

    game.resign();
    blockedEngine.complete('e2e4');
    await pumpEventQueue();

    expect(game.isGameOver, isTrue);
    expect(game.result?.reason, 'Resignation');
    expect(game.moves, isEmpty);
  });
}

Future<void> _tapBoardSquare(WidgetTester tester, String square) async {
  final boardFinder = find.byType(ChessBoardWidget);
  final topLeft = tester.getTopLeft(boardFinder);
  final size = tester.getSize(boardFinder);
  final squareSize = size.width / 8;
  final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(square[1]);
  final row = 8 - rank;
  await tester.tapAt(
    topLeft + Offset((file + 0.5) * squareSize, (row + 0.5) * squareSize),
  );
  await tester.pump();
}

Future<void> _pumpSmallPhonePlayScreen(
  WidgetTester tester, {
  EngineMoveProvider? engineMoveProvider,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: PlayVsComputerScreen(
        engineMoveProvider: engineMoveProvider,
        evaluationProvider: (_, __) async => 40,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _startComputerGameWithEvaluationBar(
  WidgetTester tester, {
  EngineMoveProvider? engineMoveProvider,
}) async {
  await _pumpSmallPhonePlayScreen(
    tester,
    engineMoveProvider: engineMoveProvider,
  );
  await tester.scrollUntilVisible(
    find.text('Evaluation bar'),
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Evaluation bar'));
  await tester.pump();
  await _startComputerGame(tester);
}

Rect _globalRect(WidgetTester tester, Finder finder) {
  final topLeft = tester.getTopLeft(finder);
  final size = tester.getSize(finder);
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
}

void _expectPlayBoardSquare(WidgetTester tester) {
  final boardSize = tester.getSize(
    find.byKey(const ValueKey('play_chess_board_area')),
  );
  expect(boardSize.width, closeTo(boardSize.height, 1));
}

void _expectPlayBoardInsideLayout(WidgetTester tester) {
  final layoutRect =
      _globalRect(tester, find.byKey(const ValueKey('play_eval_board_layout')));
  final boardRect =
      _globalRect(tester, find.byKey(const ValueKey('play_chess_board_area')));

  expect(boardRect.left, greaterThanOrEqualTo(layoutRect.left - 1));
  expect(boardRect.right, lessThanOrEqualTo(layoutRect.right + 1));
}

void _expectEvalBarAlignedWithBoard(WidgetTester tester) {
  final evalRect =
      _globalRect(tester, find.byKey(const ValueKey('play_evaluation_bar')));
  final boardRect =
      _globalRect(tester, find.byKey(const ValueKey('play_chess_board_area')));

  expect(evalRect.top, closeTo(boardRect.top, 1));
  expect(evalRect.bottom, closeTo(boardRect.bottom, 1));
  expect(evalRect.height, closeTo(boardRect.height, 1));
}

Future<void> _scrollSetupToStart(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('play_setup_list')),
    const Offset(0, -1200),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('start_computer_game')));
}

Future<void> _startComputerGame(WidgetTester tester) async {
  await _scrollSetupToStart(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('start_computer_game')));
  await tester.pump();
}

Future<void> _sendSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

Future<void> _pumpRoutedPlayScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Play launcher'),
                  ElevatedButton(
                    key: const ValueKey('open_play_screen'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlayVsComputerScreen(),
                        ),
                      );
                    },
                    child: const Text('Open play'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  expect(find.text('Play launcher'), findsOneWidget);
}
