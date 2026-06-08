import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/engine/engine_power_profile.dart';
import 'package:turbo_chess/core/models/play_mode.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/home/presentation/home_screen.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_active_game_store.dart';
import 'package:turbo_chess/features/train/data/active_drill_store.dart';
import 'package:turbo_chess/features/train/presentation/train_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows vertical bars in the requested order without ad slot',
      (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final labels = [
      'Opening Drills',
      'Middlegame Drills',
      'Endgame Drills',
      'Play vs Computer',
      'Bookmarks',
    ];

    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));
    expect(
        find.byKey(const ValueKey('home_safe_top_banner_slot')), findsNothing);
    expect(
      tester.getTopLeft(find.text('Quick Start')).dy,
      greaterThan(tester.getTopLeft(find.text('Turbo Chess')).dy),
    );

    final yPositions = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(yPositions, orderedEquals([...yPositions]..sort()));
  });

  testWidgets('Home bar layout is small-screen safe', (tester) async {
    await _setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Opening Drills'), findsOneWidget);
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));
    expect(find.textContaining('Game Review'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Chess960'), findsNothing);
    expect(find.textContaining('Beginner to Master'), findsNothing);
  });

  testWidgets('Home header uses the real launcher icon asset', (tester) async {
    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final iconFinder =
        find.byKey(const ValueKey('home_turbo_chess_launcher_icon'));
    expect(iconFinder, findsOneWidget);

    final image = tester.widget<Image>(iconFinder);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/turbo_chess_launcher_icon.png',
    );
  });

  testWidgets('Train shows vertical bars in the requested order', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: TrainScreen()));
    await tester.pumpAndSettle();

    final labels = [
      'Opening Drills',
      'Middlegame Drills',
      'Endgame Drills',
      'Play vs Computer',
    ];

    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Bookmarks'), findsNothing);
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));

    final yPositions = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(yPositions, orderedEquals([...yPositions]..sort()));
  });

  testWidgets('Train bar layout is small-screen safe and has no Bookmarks bar',
      (
    tester,
  ) async {
    await _setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(const MaterialApp(home: TrainScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Opening Drills'), findsOneWidget);
    expect(find.text('Bookmarks'), findsNothing);
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));
    expect(find.textContaining('Game Review'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Chess960'), findsNothing);
    expect(find.textContaining('Beginner to Master'), findsNothing);
  });

  testWidgets('Home and Train show real completed progress counts', (
    tester,
  ) async {
    const store = PositionProgressStore();
    await store.markCompleted(PositionCategory.opening, 1);

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10,000 completed'), findsOneWidget);
    expect(find.text('0 / 10,000 completed'), findsNWidgets(2));

    await tester.pumpWidget(const MaterialApp(home: TrainScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10,000 completed'), findsOneWidget);
    expect(find.text('0 / 10,000 completed'), findsNWidgets(2));
  });

  testWidgets('legacy access state does not fake progress completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'legacy_access_active': true,
    });

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('10,000 / 10,000 completed'), findsNothing);
    expect(find.text('0 / 10,000 completed'), findsNWidgets(3));
  });

  testWidgets('Home shows unfinished Play vs Computer resume card', (
    tester,
  ) async {
    await _saveActiveComputerGame();
    bool resumeArgumentSeen = false;

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/play/computer') {
            final args = settings.arguments as Map<String, dynamic>?;
            resumeArgumentSeen = args?['resumeActive'] == true;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Resume route')),
            );
          }
          return null;
        },
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('active_play_resume_card')), findsOneWidget);
    expect(find.text('Resume unfinished game?'), findsOneWidget);
    expect(
      find.text('You have an unfinished game against the computer.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('resume_active_play_card')));
    await tester.pumpAndSettle();

    expect(find.text('Resume route'), findsOneWidget);
    expect(resumeArgumentSeen, isTrue);
  });

  testWidgets('Home shows unfinished drill resume card', (
    tester,
  ) async {
    await _saveActiveDrill();
    bool resumeArgumentSeen = false;
    PositionCategory? routedCategory;
    int? routedPositionIndex;

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments as Map<String, dynamic>?;
            resumeArgumentSeen = args?['resumeActive'] == true;
            routedCategory = PositionCategory.fromId(
              args?['category']?.toString(),
            );
            routedPositionIndex = args?['positionIndex'] as int?;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Drill route')),
            );
          }
          return null;
        },
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('active_drill_resume_card')),
      findsOneWidget,
    );
    expect(find.text('Resume unfinished drill?'), findsOneWidget);
    expect(
      find.text('You have an unfinished Endgame drill at position 7.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('resume_active_drill_card')));
    await tester.pumpAndSettle();

    expect(find.text('Drill route'), findsOneWidget);
    expect(resumeArgumentSeen, isTrue);
    expect(routedCategory, PositionCategory.endgame);
    expect(routedPositionIndex, 7);
  });

  testWidgets('Home drill discard confirms before clearing unfinished save', (
    tester,
  ) async {
    const activeStore = ActiveDrillStore();
    await _saveActiveDrill();

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('active_drill_resume_card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discard_active_drill_card')));
    await tester.pumpAndSettle();

    expect(find.text('Discard unfinished drill?'), findsOneWidget);
    expect(await activeStore.load(), isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await activeStore.load(), isNotNull);
    expect(
      find.byKey(const ValueKey('active_drill_resume_card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discard_active_drill_card')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(await activeStore.load(), isNull);
    expect(
        find.byKey(const ValueKey('active_drill_resume_card')), findsNothing);
  });

  testWidgets('Train discard button confirms unfinished Play vs Computer save',
      (
    tester,
  ) async {
    const activeStore = PlayComputerActiveGameStore();
    await _saveActiveComputerGame();

    await _setSurface(tester, const Size(430, 900));
    await tester.pumpWidget(const MaterialApp(home: TrainScreen()));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('active_play_resume_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('discard_active_play_card')));
    await tester.pumpAndSettle();

    expect(find.text('Discard unfinished game?'), findsOneWidget);
    expect(await activeStore.load(), isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await activeStore.load(), isNotNull);
    expect(
        find.byKey(const ValueKey('active_play_resume_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('discard_active_play_card')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();

    expect(await activeStore.load(), isNull);
    expect(find.byKey(const ValueKey('active_play_resume_card')), findsNothing);
  });
}

Future<void> _setSurface(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _saveActiveComputerGame() async {
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
}

Future<void> _saveActiveDrill() async {
  const activeStore = ActiveDrillStore();
  final after = ChessRules.applyUciMove(
    ChessBoard.fromFen('8/8/8/4k3/8/4K3/4P3/8 w - - 0 1'),
    'e3d3',
  )!;
  await activeStore.save(
    ActiveDrillSnapshot(
      startedAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
      category: PositionCategory.endgame,
      positionIndex: 7,
      startingFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
      currentFen: after.toFen(),
      userColor: PieceColor.white,
      engineProfileId: EnginePowerProfile.strong.id,
      boardFlipped: false,
      moves: [
        MoveRecord(
          move: 'e3d3',
          fenBefore: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
          fenAfter: after.toFen(),
          isUser: true,
          moveNumber: 1,
          sideToMoveBefore: PieceColor.white,
          sideToMoveAfter: PieceColor.black,
          moveSan: 'Kd3',
        ),
      ],
    ),
  );
}
