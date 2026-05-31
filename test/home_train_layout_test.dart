import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/engine/chess_rules.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_progress_store.dart';
import 'package:turbo_chess/features/home/presentation/home_screen.dart';
import 'package:turbo_chess/features/play_computer/data/play_computer_active_game_store.dart';
import 'package:turbo_chess/features/train/presentation/train_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows vertical bars in the requested order', (
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
    expect(find.byKey(const ValueKey('home_safe_top_banner_slot')),
        findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('home_safe_top_banner_slot')))
          .dy,
      greaterThan(tester.getTopLeft(find.text('Turbo Chess')).dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('home_safe_top_banner_slot')))
          .dy,
      lessThan(tester.getTopLeft(find.text('Quick Start')).dy),
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

  testWidgets('Premium-style unlock state does not fake progress completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'subscription_active': true,
      'rewarded_pass_active': true,
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

  testWidgets('Train discard button clears unfinished Play vs Computer save', (
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
