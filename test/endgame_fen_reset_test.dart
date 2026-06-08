import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/engine/play_vs_engine.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/train/presentation/position_drill_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TurboSoundService.instance.debugResetForTesting();
  });

  test('endgame position opens from asset FEN without starting fallback',
      () async {
    final repo = PositionFenRepository();
    final fen = await repo.loadFen(PositionCategory.endgame, 1);
    final board = ChessBoard.fromFen(fen);

    expect(fen, isNot(ChessBoard.standardStartingFen));
    expect(board.toFen(), fen);
  });

  test('endgame board remains selected position after user and engine moves',
      () async {
    SharedPreferences.setMockInitialValues({});
    const fen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
    final game = PlayVsEngine(startingFen: fen);
    addTearDown(game.dispose);

    game.start();
    final firstMove = ChessRules.getLegalMoveUcis(game.board).first;
    final accepted = await game.userMove(
      firstMove.substring(0, 2),
      firstMove.substring(2, 4),
      promotion: firstMove.length > 4 ? firstMove[4] : null,
    );

    expect(accepted, isTrue);
    expect(game.moves.length, greaterThanOrEqualTo(1));
    expect(game.board.toFen(), isNot(ChessBoard.standardStartingFen));
    expect(game.initialFen, fen);
  });

  test('reset returns to selected endgame FEN, not standard start', () async {
    SharedPreferences.setMockInitialValues({});
    const fen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
    final game = PlayVsEngine(startingFen: fen);
    addTearDown(game.dispose);

    game.start();
    final firstMove = ChessRules.getLegalMoveUcis(game.board).first;
    await game.userMove(
      firstMove.substring(0, 2),
      firstMove.substring(2, 4),
      promotion: firstMove.length > 4 ? firstMove[4] : null,
    );

    game.reset();

    expect(game.board.toFen(), fen);
    expect(game.board.toFen(), isNot(ChessBoard.standardStartingFen));
    expect(game.moves, isEmpty);
    expect(game.state, PlayState.idle);
  });

  testWidgets(
      'completion dialog next position opens position 2 with fresh FEN identity',
      (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _setSurface(tester, const Size(430, 900));
    const fen1 = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    const fen2 = '8/8/8/3k4/8/3K4/3P4/8 w - - 0 1';
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.endgame.assetPath: '$fen1\n$fen2',
      }),
    );
    const progressStore = PositionProgressStore();
    await progressStore.markCompleted(PositionCategory.endgame, 1);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute<void>(
              builder: (_) => PositionDrillScreen(
                category: PositionCategory.endgame,
                positionIndex: args['positionIndex'] as int,
                repository: repo,
                progressStore: progressStore,
              ),
            );
          }
          return null;
        },
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 1,
          repository: repo,
          progressStore: progressStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsOneWidget);
    var board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen1);
    expect(find.text('Next'), findsNothing);

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pumpAndSettle();

    expect(find.text('Position completed'), findsOneWidget);
    expect(find.text('Next Position'), findsOneWidget);

    await tester.tap(find.text('Next Position'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 2'), findsOneWidget);
    expect(find.text('Endgame Position 1'), findsNothing);
    board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen2);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    board = tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), fen2);
  });

  test('opening middlegame and endgame position 5 keep their own reset FEN',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PositionFenRepository();

    for (final category in PositionCategory.values) {
      final fen = await repo.loadFen(category, 5);
      final board = ChessBoard.fromFen(fen);
      final game = PlayVsEngine(startingFen: fen, userColor: board.turn);
      addTearDown(game.dispose);

      game.start();
      final legalMoves = ChessRules.getLegalMoveUcis(game.board);
      if (legalMoves.isNotEmpty && game.state == PlayState.userTurn) {
        final firstMove = legalMoves.first;
        await game.userMove(
          firstMove.substring(0, 2),
          firstMove.substring(2, 4),
          promotion: firstMove.length > 4 ? firstMove[4] : null,
        );
      }
      expect(game.initialFen, fen);
      expect(game.initialFen, isNot(ChessBoard.standardStartingFen));

      game.reset();
      expect(game.board.toFen(), fen);
    }
  });

  testWidgets('invalid selected FEN shows an error instead of starting board',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.endgame.assetPath: 'invalid-fen',
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 1,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Position unavailable'), findsOneWidget);
    expect(find.textContaining('selected FEN is invalid'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsNothing);
  });

  testWidgets('drill user move triggers sound service', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const fen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    final soundService = TurboSoundService.instance;
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.endgame.assetPath: fen,
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 1,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pump(const Duration(milliseconds: 50));

    expect(soundService.debugSoundPlayCount, greaterThan(0));
  });

  test('invalid FEN is rejected explicitly', () {
    expect(
      () => ChessBoard.fromFen('invalid-fen'),
      throwsA(isA<FormatException>()),
    );
    expect(ChessBoard.tryFromFen('invalid-fen'), isNull);
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

Future<void> _setSurface(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _FakePositionAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _FakePositionAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    final asset = assets[key];
    if (asset == null) {
      throw StateError('Missing fake asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(asset)));
  }
}
