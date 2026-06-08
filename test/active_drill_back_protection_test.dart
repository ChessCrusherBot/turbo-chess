import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/bookmarks/bookmark_store.dart';
import 'package:turbo_chess/core/bookmarks/chess_bookmark.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/design_system.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/train/data/active_drill_store.dart';
import 'package:turbo_chess/features/train/presentation/position_drill_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TurboSoundService.instance.debugResetForTesting();
  });

  testWidgets('active drill system back shows leave dialog and Cancel stays',
      (tester) async {
    await _setSurface(tester, const Size(320, 568));
    const progressStore = PositionProgressStore();

    await _pumpRoutedDrill(tester, progressStore: progressStore);
    await _sendSystemBack(tester);

    expect(find.text('Leave drill?'), findsOneWidget);
    expect(
      find.text(
        'Your current attempt will stay available from Home. This position will not be marked complete unless you checkmate the engine.',
      ),
      findsOneWidget,
    );
    expect(find.text('Leave Drill'), findsOneWidget);
    expect(find.text('Leave completed drill?'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsOneWidget);

    final progress = await progressStore.snapshot(PositionCategory.endgame);
    expect(progress.completedCount, 0);
    expect(progress.highestUnlockedIndex, 1);
  });

  testWidgets(
      'previously completed drill back shows completed copy and preserves state',
      (tester) async {
    const progressStore = PositionProgressStore();
    const bookmarkStore = BookmarkStore();
    await progressStore.markCompleted(PositionCategory.endgame, 1);
    await bookmarkStore.add(
      ChessBookmark(
        id: 'bookmark-completed-position-one',
        fen: _activeFen,
        sourceType: 'endgame',
        module: 'endgame',
        positionIndex: 1,
        title: 'Endgame Position 1',
        difficulty: 'Beginner',
        savedAt: DateTime(2026),
      ),
    );

    await _pumpRoutedDrill(tester, progressStore: progressStore);
    await _sendSystemBack(tester);

    expect(find.text('Leave completed drill?'), findsOneWidget);
    expect(
      find.text(
        'Your completion is already saved. Leaving will not change your progress.',
      ),
      findsOneWidget,
    );
    expect(find.text('Leave'), findsOneWidget);
    expect(
      find.text(
        'Your current attempt will stay available from Home. This position will not be marked complete unless you checkmate the engine.',
      ),
      findsNothing,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsOneWidget);

    await _sendSystemBack(tester);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Drill launcher'), findsOneWidget);
    expect(find.text('Endgame Position 1'), findsNothing);

    final progress = await progressStore.snapshot(PositionCategory.endgame);
    expect(progress.completedCount, 1);
    expect(progress.highestUnlockedIndex, 2);
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 3,
        highestUnlockedIndex: progress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );

    final bookmarks = await bookmarkStore.load();
    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.id, 'bookmark-completed-position-one');
  });

  testWidgets('header back leaves drill without changing progress or bookmark',
      (tester) async {
    const progressStore = PositionProgressStore();
    const bookmarkStore = BookmarkStore();
    await bookmarkStore.add(
      ChessBookmark(
        id: 'bookmark-position-one',
        fen: _activeFen,
        sourceType: 'endgame',
        module: 'endgame',
        positionIndex: 1,
        title: 'Endgame Position 1',
        difficulty: 'Beginner',
        savedAt: DateTime(2026),
      ),
    );

    await _pumpRoutedDrill(tester, progressStore: progressStore);

    await tester.tap(find.byTooltip('Back to training'));
    await tester.pump();

    expect(find.text('Leave drill?'), findsOneWidget);

    await tester.tap(find.text('Leave Drill'));
    await tester.pumpAndSettle();

    expect(find.text('Drill launcher'), findsOneWidget);
    expect(find.text('Endgame Position 1'), findsNothing);

    final progress = await progressStore.snapshot(PositionCategory.endgame);
    expect(progress.completedCount, 0);
    expect(progress.highestUnlockedIndex, 1);

    final bookmarks = await bookmarkStore.load();
    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.id, 'bookmark-position-one');
  });

  testWidgets('back while leave drill dialog is open cancels and stays',
      (tester) async {
    await _pumpRoutedDrill(
      tester,
      progressStore: const PositionProgressStore(),
    );

    await _sendSystemBack(tester);

    expect(find.text('Leave drill?'), findsOneWidget);

    await _sendSystemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Leave drill?'), findsNothing);
    expect(find.text('Endgame Position 1'), findsOneWidget);
  });

  testWidgets('completed drill result back does not show leave confirmation',
      (tester) async {
    const progressStore = PositionProgressStore();
    await _pumpRoutedDrill(
      tester,
      progressStore: progressStore,
      fen: _mateInOneFen,
    );

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pumpAndSettle();

    expect(find.text('Position completed'), findsOneWidget);
    final progress = await progressStore.snapshot(PositionCategory.endgame);
    expect(progress.isCompleted(1), isTrue);

    await _sendSystemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('Leave drill?'), findsNothing);
  });

  testWidgets('completed dialog keeps Next Position and readable Back button',
      (tester) async {
    await _setSurface(tester, const Size(430, 900));
    const progressStore = PositionProgressStore();
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.endgame.assetPath: '$_mateInOneFen\n$_activeFen',
      }),
    );

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

    expect(find.text('Next'), findsNothing);

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pumpAndSettle();

    expect(find.text('Position completed'), findsOneWidget);
    expect(find.text('Next Position'), findsOneWidget);
    expect(find.text('Retry Drill'), findsOneWidget);
    expect(find.text('Back to Training'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    final backButtonFinder = find.widgetWithText(OutlinedButton, 'Back');
    expect(backButtonFinder, findsOneWidget);
    final backButton = tester.widget<OutlinedButton>(backButtonFinder);
    expect(backButton.onPressed, isNotNull);
    expect(
      backButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      DesignSystem.textPrimary,
    );

    await tester.tap(find.text('Next Position'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 2'), findsOneWidget);
    expect(find.text('Position completed'), findsNothing);
    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), _activeFen);
  });

  testWidgets('drill completed during session uses completed copy after retry',
      (tester) async {
    const progressStore = PositionProgressStore();
    await _pumpRoutedDrill(
      tester,
      progressStore: progressStore,
      fen: _mateInOneFen,
    );

    await _tapBoardSquare(tester, 'g6');
    await _tapBoardSquare(tester, 'g7');
    await tester.pumpAndSettle();

    expect(find.text('Position completed'), findsOneWidget);

    await tester.tap(find.text('Retry Drill'));
    await tester.pumpAndSettle();
    await _sendSystemBack(tester);

    expect(find.text('Leave completed drill?'), findsOneWidget);
    expect(
      find.text(
        'Your completion is already saved. Leaving will not change your progress.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'This position will not be marked complete unless you checkmate the engine.',
        findRichText: true,
      ),
      findsNothing,
    );
  });

  testWidgets('unfinished drill saves and resume route restores current FEN',
      (tester) async {
    const activeStore = ActiveDrillStore();
    final after = ChessRules.applyUciMove(
      ChessBoard.fromFen(_activeFen),
      'e3d3',
    )!;
    await activeStore.save(
      ActiveDrillSnapshot(
        startedAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
        category: PositionCategory.endgame,
        positionIndex: 1,
        startingFen: _activeFen,
        currentFen: after.toFen(),
        userColor: PieceColor.white,
        engineProfileId: 'strong',
        boardFlipped: false,
        moves: const [],
      ),
    );

    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.endgame.assetPath: _activeFen,
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 1,
          repository: repo,
          progressStore: const PositionProgressStore(),
          resumeActiveOnOpen: true,
          engineMoveProvider: (_, __, ___) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final board =
        tester.widget<ChessBoardWidget>(find.byType(ChessBoardWidget));
    expect(board.board.toFen(), after.toFen());
    expect(await activeStore.load(), isNotNull);
  });

  testWidgets('unfinished drill appears in active store after opening',
      (tester) async {
    const activeStore = ActiveDrillStore();

    await _pumpRoutedDrill(
      tester,
      progressStore: const PositionProgressStore(),
    );

    final saved = await activeStore.load();
    expect(saved, isNotNull);
    expect(saved!.category, PositionCategory.endgame);
    expect(saved.positionIndex, 1);
    expect(saved.currentFen, _activeFen);
  });

  testWidgets('drill reset requires confirmation and Cancel keeps attempt',
      (tester) async {
    await _pumpRoutedDrill(
      tester,
      progressStore: const PositionProgressStore(),
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset drill?'), findsOneWidget);
    expect(
      find.text('This will restart the current drill and clear this attempt.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset drill?'), findsNothing);
    expect(find.byType(ChessBoardWidget), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset drill?'), findsNothing);
    expect(find.byType(ChessBoardWidget), findsOneWidget);
  });
}

const _activeFen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
const _mateInOneFen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';

Future<void> _pumpRoutedDrill(
  WidgetTester tester, {
  required PositionProgressStore progressStore,
  String fen = _activeFen,
}) async {
  final repo = PositionFenRepository(
    bundle: _FakePositionAssetBundle({
      PositionCategory.endgame.assetPath: fen,
    }),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Drill launcher'),
                  ElevatedButton(
                    key: const ValueKey('open_drill_screen'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PositionDrillScreen(
                            category: PositionCategory.endgame,
                            positionIndex: 1,
                            repository: repo,
                            progressStore: progressStore,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open drill'),
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
  await tester.tap(find.byKey(const ValueKey('open_drill_screen')));
  await tester.pumpAndSettle();
}

Future<void> _sendSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
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
