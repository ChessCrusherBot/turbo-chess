import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/engine_power_profile.dart';
import 'package:turbo_chess/core/engine/play_vs_engine.dart';
import 'package:turbo_chess/core/models/models.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/features/train/presentation/drill_detail_base.dart';

const _subtopic = 'Engine Profile Test';

const _testDrill = ChessDrill(
  id: 'engine_profile_test_drill',
  fen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
  sideToMove: 'White',
  task: 'Play against the engine.',
  bestMove: '',
  bestMoveUci: '',
  hint: '',
  explanation: '',
  conceptTag: 'Test',
  difficulty: 3,
);

const _testTopic = OpeningTopic(
  id: 'engine_profile_test_topic',
  label: 'Test Topic',
  icon: 'memory',
  subtopics: [_subtopic],
  drillsBySubtopic: {
    _subtopic: [_testDrill],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TurboSoundService.instance.debugResetForTesting();
  });

  test('drill screen does not render removed prototype copy', () {
    final source = File(
      'lib/features/train/presentation/drill_detail_base.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Playable board')));
    expect(source, isNot(contains('Tap a legal move')));
    expect(source, isNot(contains('Engine strength')));
    expect(source, isNot(contains('Engine Strength Easy')));
    expect(source, isNot(contains('Easy')));
    expect(source, isNot(contains('PlayModePanelWidget')));
  });

  test('engine default profile is Strong', () {
    final game = PlayVsEngine(
      startingFen: _testDrill.fen,
    );

    expect(game.engineProfile, EnginePowerProfile.strong);
  });

  test('engine profiles map to requested mobile-safe search configs', () {
    const lowEnd = EngineDeviceProfile(
      isLowRamDevice: true,
      processorCount: 4,
      memoryClassMb: 128,
      totalMemoryMb: 2048,
    );
    const flagship = EngineDeviceProfile(
      isLowRamDevice: false,
      processorCount: 8,
      memoryClassMb: 512,
      totalMemoryMb: 8192,
    );

    final strong = EnginePowerProfile.strong.resolve(device: lowEnd);
    final master = EnginePowerProfile.master.resolve(device: lowEnd);
    final maxLowEnd = EnginePowerProfile.max.resolve(device: lowEnd);
    final maxFlagship = EnginePowerProfile.max.resolve(device: flagship);

    expect(strong.depth, 14);
    expect(strong.skillLevel, 20);
    expect(strong.limitStrength, isFalse);
    expect(strong.ponder, isFalse);
    expect(strong.threads, 1);
    expect(strong.hashMb, 32);

    expect(master.depth, 18);
    expect(master.skillLevel, 20);
    expect(master.limitStrength, isFalse);
    expect(master.ponder, isFalse);
    expect(master.threads, 1);
    expect(master.hashMb, 32);

    expect(maxLowEnd.depth, 22);
    expect(maxLowEnd.threads, 1);
    expect(maxLowEnd.hashMb, 48);
    expect(maxFlagship.depth, 26);
    expect(maxFlagship.hashMb, 128);
  });

  test('stockfish wrapper applies full-strength UCI options without Elo limit',
      () {
    final stockfishSource = File(
      'lib/core/engine/stockfish_engine.dart',
    ).readAsStringSync();

    expect(stockfishSource, contains('UCI_LimitStrength'));
    expect(stockfishSource, contains('Skill Level'));
    expect(stockfishSource, contains('Ponder'));
    expect(stockfishSource, contains('Hash'));
    expect(stockfishSource, contains('Threads'));
    expect(stockfishSource, isNot(contains('UCI_Elo')));
    expect(stockfishSource, isNot(contains('getBestMoveWithDifficulty')));
  });

  test('invalid saved engine profile falls back to Strong', () {
    expect(EnginePowerProfile.fromId('invalid'), EnginePowerProfile.strong);
    expect(EnginePowerProfile.fromId(null), EnginePowerProfile.strong);
  });

  testWidgets('engine selector shows premium profile options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpDrill(tester);

    expect(find.text('Engine: Strong'), findsOneWidget);
    expect(find.text('Engine Strength Easy'), findsNothing);
    expect(find.text('Easy'), findsNothing);
    expect(find.text('+'), findsNothing);
    expect(find.text('-'), findsNothing);
    expect(find.textContaining('Game Review'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Streak'), findsNothing);
    expect(find.textContaining('Coins'), findsNothing);

    await tester.tap(find.text('Engine: Strong'));
    await tester.pumpAndSettle();

    expect(find.text('Engine Power'), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.textContaining('Depth 14'), findsOneWidget);
    expect(find.textContaining('Depth 18'), findsOneWidget);
    expect(find.textContaining('Adaptive Depth 22-26+'), findsOneWidget);
    expect(find.textContaining('powerful phones only'), findsOneWidget);
  });

  testWidgets('position drill header hides visible difficulty labels',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DrillDetailBaseScreen.position(
          category: PositionCategory.middlegame,
          positionIndex: 1,
          fen: _testDrill.fen,
          totalPositions: 10,
          color: Colors.teal,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Middlegame Position 1'), findsOneWidget);
    expect(find.text('Middlegame Drills'), findsOneWidget);
    expect(find.text('Beginner'), findsNothing);
    expect(find.text('Intermediate'), findsNothing);
    expect(find.text('Advanced'), findsNothing);
    expect(find.text('Master'), findsNothing);
    expect(find.text('You are White'), findsOneWidget);
  });

  testWidgets('active drill controls hide standalone Next button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DrillDetailBaseScreen.position(
          category: PositionCategory.opening,
          positionIndex: 1,
          fen: _testDrill.fen,
          totalPositions: 2,
          color: Colors.deepPurple,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Engine: Strong'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Flip'), findsOneWidget);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('Resign'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Next Position'), findsNothing);
  });

  testWidgets('engine thinking chip animates dots safely', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final blockedEngine = Completer<String?>();

    await tester.pumpWidget(
      MaterialApp(
        home: DrillDetailBaseScreen.position(
          category: PositionCategory.opening,
          positionIndex: 1,
          fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
          totalPositions: 10,
          color: Colors.teal,
          engineMoveProvider: (_, __, ___) => blockedEngine.future,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'e2');
    await _tapBoardSquare(tester, 'e3');
    await tester.pump();

    expect(find.textContaining('Engine thinking'), findsOneWidget);
    final first = tester.widget<Text>(
      find.textContaining('Engine thinking'),
    );

    await tester.pump(const Duration(milliseconds: 450));
    final second = tester.widget<Text>(
      find.textContaining('Engine thinking'),
    );
    expect(second.data, isNot(first.data));

    blockedEngine.complete(null);
  });

  testWidgets('drill promotion cancel leaves board and sound untouched',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const fen = '7k/P7/8/8/8/8/8/4K3 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: DrillDetailBaseScreen.position(
          category: PositionCategory.endgame,
          positionIndex: 1,
          fen: fen,
          totalPositions: 10,
          color: Colors.teal,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
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

  testWidgets('drill promotion selection applies chosen piece once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const fen = '7k/P7/8/8/8/8/8/4K3 w - - 0 1';
    final soundService = TurboSoundService.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: DrillDetailBaseScreen.position(
          category: PositionCategory.endgame,
          positionIndex: 1,
          fen: fen,
          totalPositions: 10,
          color: Colors.teal,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'a7');
    await _tapBoardSquare(tester, 'a8');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knight'));
    await tester.pump(const Duration(milliseconds: 100));

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.pieces['a8']?.type, PieceType.knight);
    expect(soundService.debugSoundPlayCount, 1);
  });

  testWidgets('selecting Tournament updates the current drill profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpDrill(tester);

    await tester.tap(find.text('Engine: Strong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tournament'));
    await tester.pumpAndSettle();

    expect(find.text('Engine: Tournament'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(EnginePowerProfile.preferencesKey),
      EnginePowerProfile.master.id,
    );
  });

  testWidgets('selecting Max shows power warning text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpDrill(tester);

    await tester.tap(find.text('Engine: Strong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Max'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Engine: Max'), findsOneWidget);
    expect(
      find.textContaining('deeper Stockfish search'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('saved Tournament profile is restored', (tester) async {
    SharedPreferences.setMockInitialValues({
      EnginePowerProfile.preferencesKey: EnginePowerProfile.master.id,
    });
    await _pumpDrill(tester);

    expect(find.text('Engine: Tournament'), findsOneWidget);
  });

  testWidgets('invalid saved profile renders Strong', (tester) async {
    SharedPreferences.setMockInitialValues({
      EnginePowerProfile.preferencesKey: 'broken-profile',
    });
    await _pumpDrill(tester);

    expect(find.text('Engine: Strong'), findsOneWidget);
  });
}

Future<void> _pumpDrill(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: DrillDetailBaseScreen(
        screenTitle: 'Test Drill',
        topic: _testTopic,
        subtopic: _subtopic,
        color: Colors.teal,
        difficulty: 3,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
