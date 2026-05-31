import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/bookmarks/bookmark_store.dart';
import 'package:turbo_chess/core/bookmarks/chess_bookmark.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
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
        'Your current attempt will be lost. This position will not be marked complete unless you checkmate the engine.',
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
        'Your current attempt will be lost. This position will not be marked complete unless you checkmate the engine.',
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
      isFalse,
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
