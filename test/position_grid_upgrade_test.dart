import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/design_system.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/train/presentation/position_drill_screen.dart';
import 'package:turbo_chess/features/train/presentation/position_grid_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('all drill grids show permanent jump card without old info card',
      (
    tester,
  ) async {
    for (final category in PositionCategory.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: PositionGridScreen(
            category: category,
            repository: _repo(category, count: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('permanent_jump_position_card')),
        findsOneWidget,
      );
      expect(find.text('Jump to Position'), findsOneWidget);
      expect(find.byKey(const ValueKey('jump_position_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('jump_position_go')), findsOneWidget);
      expect(find.text('Fast navigation'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('open_jump_position_dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('position_quick_jump_controls')),
        findsOneWidget,
      );
      expect(find.text('All positions unlocked for version 1.'), findsNothing);
      expect(find.text('Completed 0 / 3'), findsNothing);
      expect(find.text('Locked'), findsNothing);
      expect(find.text('Position locked'), findsNothing);
      expect(find.textContaining('Beginner to Master'), findsNothing);
      expect(find.text('Beginner'), findsNothing);
      expect(find.text('Club'), findsNothing);
      expect(find.text('Intermediate'), findsNothing);
      expect(find.text('Advanced'), findsNothing);
      expect(find.text('Master'), findsNothing);
    }
  });

  testWidgets('permanent jump card handles exact positions and invalid input', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 10000),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('jump_position_input')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 10000.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      'abc',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 10000.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '5000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('position_tile_5000')), findsOneWidget);
    _expectTileHighlighted(tester, 5000);

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '10000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('position_tile_10000')), findsOneWidget);
  });

  testWidgets('user can jump to and open a high position immediately', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    var navigated = false;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            navigated = true;
            return MaterialPageRoute<void>(
              builder: (_) => const Placeholder(),
            );
          }
          return null;
        },
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 10000),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('jump_position_input')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('jump_position_input')),
      '5000',
    );
    await tester.tap(find.byKey(const ValueKey('jump_position_go')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(navigated, isFalse);
    expect(find.byType(Placeholder), findsNothing);
    _expectTileHighlighted(tester, 5000);

    await tester.tap(find.byKey(const ValueKey('position_tile_5000')));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.text('Position locked'), findsNothing);
  });

  testWidgets('position 2 opens without completing position 1', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    var navigated = false;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments as Map<String, dynamic>;
            navigated = args['positionIndex'] == 2;
            return MaterialPageRoute<void>(
              builder: (_) => const Placeholder(),
            );
          }
          return null;
        },
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: _repo(PositionCategory.opening, count: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('position_tile_2')));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.text('Position locked'), findsNothing);
    expect(find.text('Complete earlier positions to unlock this one.'),
        findsNothing);

    for (final forbidden in <String>[
      'Unlock all positions',
      '72-hour',
      'rewarded',
      'Subscribe',
      'Restore Premium',
      'subscription',
      'purchase',
      'Google Play',
    ]) {
      expect(find.textContaining(forbidden), findsNothing);
    }

    const store = PositionProgressStore();
    final progress = await store.snapshot(PositionCategory.opening);
    expect(progress.completedCount, 0);
    expect(progress.highestUnlockedIndex, 1);
  });

  testWidgets('completed styling changes only for Endgame grid visibility', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));

    for (final category in PositionCategory.values) {
      SharedPreferences.setMockInitialValues({});
      const store = PositionProgressStore();
      await store.markCompleted(category, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: PositionGridScreen(
            category: category,
            repository: _repo(category, count: 2),
            progressStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final completedColor = _tileStatusColor(tester, 1, 'Completed');
      if (category == PositionCategory.endgame) {
        expect(completedColor, DesignSystem.warningLight);
        expect(_tileStatusColor(tester, 2, 'Open'), DesignSystem.tertiary);
      } else {
        expect(completedColor, DesignSystem.successLight);
      }
    }
  });

  testWidgets(
    'position drill opens a valid position with only legacy position 1 progress',
    (tester) async {
      await _setSurface(tester, const Size(430, 900));
      const store = PositionProgressStore();

      await tester.pumpWidget(
        MaterialApp(
          home: PositionDrillScreen(
            category: PositionCategory.middlegame,
            positionIndex: 2,
            repository: _repo(PositionCategory.middlegame, count: 3),
            progressStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChessBoardWidget), findsOneWidget);
      expect(find.text('Position locked'), findsNothing);

      final progress = await store.snapshot(PositionCategory.middlegame);
      expect(progress.completedCount, 0);
      expect(progress.highestUnlockedIndex, 1);
      expect(progress.lastPlayedIndex, 2);
    },
  );

  testWidgets('invalid position index still fails safely', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: 0,
          repository: _repo(PositionCategory.endgame, count: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Position not found'), findsOneWidget);
    expect(find.text('Position not found.'), findsOneWidget);
    expect(find.byType(ChessBoardWidget), findsNothing);
  });

  test('completion progress stays category-local while access is open',
      () async {
    const store = PositionProgressStore();
    await store.markCompleted(PositionCategory.opening, 1);

    final openingProgress = await store.snapshot(PositionCategory.opening);
    expect(openingProgress.isCompleted(1), isTrue);
    expect(openingProgress.highestUnlockedIndex, 2);
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 2,
        highestUnlockedIndex: openingProgress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 3,
        highestUnlockedIndex: openingProgress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );

    for (final category in PositionCategory.values) {
      final progress = await store.snapshot(category);
      expect(
        PositionProgressStore.isUnlocked(
          positionIndex: 10000,
          highestUnlockedIndex: progress.highestUnlockedIndex,
          hasPremiumAccess: false,
        ),
        isTrue,
        reason: '${category.id} should be open without progress',
      );
    }

    final middlegameProgress =
        await store.snapshot(PositionCategory.middlegame);
    expect(
      PositionProgressStore.isUnlocked(
        positionIndex: 2,
        highestUnlockedIndex: middlegameProgress.highestUnlockedIndex,
        hasPremiumAccess: false,
      ),
      isTrue,
    );
    expect(middlegameProgress.completedCount, 0);
  });
}

PositionFenRepository _repo(PositionCategory _category, {required int count}) {
  return _FakeCountPositionRepository(count);
}

Future<void> _setSurface(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void _expectTileHighlighted(WidgetTester tester, int positionIndex) {
  final tileFinder = find.byKey(ValueKey('position_tile_$positionIndex'));
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: tileFinder,
      matching: find.byType(AnimatedContainer),
    ),
  );
  final decoration = container.decoration as BoxDecoration;
  final border = decoration.border as Border;
  expect(border.top.width, 2);
}

Color? _tileStatusColor(
  WidgetTester tester,
  int positionIndex,
  String statusText,
) {
  final tileFinder = find.byKey(ValueKey('position_tile_$positionIndex'));
  final statusFinder = find.descendant(
    of: tileFinder,
    matching: find.text(statusText),
  );
  final status = tester.widget<Text>(statusFinder);
  return status.style?.color;
}

class _FakeCountPositionRepository extends PositionFenRepository {
  final int count;

  _FakeCountPositionRepository(this.count);

  @override
  Future<int> availableCount(PositionCategory category) async => count;

  @override
  Future<String> loadFen(PositionCategory category, int positionIndex) async =>
      '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';
}
