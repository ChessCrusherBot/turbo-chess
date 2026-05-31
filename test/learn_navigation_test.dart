import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/app/app.dart';
import 'package:turbo_chess/features/learn/presentation/learn_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('top navigation exposes Home Learn Train More and opens tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Turbo Chess'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Coming Soon'), findsAtLeastNWidgets(1));
    expect(find.text('Chess Basics Mastery'), findsOneWidget);

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Opening Drills'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Premium Status'), findsOneWidget);
    expect(find.text('Ad-free access'), findsNothing);
    expect(find.text('Free access'), findsOneWidget);
    expect(find.text('Ads active'), findsOneWidget);

    for (final forbidden in <String>[
      'Game Review',
      'XP',
      'Streak',
      'Coins',
      'Chess960',
      'Variants',
    ]) {
      expect(find.textContaining(forbidden), findsNothing);
    }
  });

  testWidgets('Learn page shows all coming soon mastery cards', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Coming Soon'), findsAtLeastNWidgets(1));
    expect(find.text('Chess Basics Mastery'), findsOneWidget);
    expect(find.text('Openings Mastery'), findsOneWidget);
    expect(find.text('Middlegame Mastery'), findsOneWidget);
    expect(find.text('Endgame Mastery'), findsOneWidget);
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));

    await tester.scrollUntilVisible(
      find.text('ROAD TO BECOMING A GM'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('ROAD TO BECOMING A GM'), findsOneWidget);
    expect(find.byType(FaIcon), findsAtLeastNWidgets(4));
    expect(find.textContaining('Chess960'), findsNothing);
    expect(find.textContaining('variant'), findsNothing);
  });

  testWidgets('Learn mastery cards are disabled and do not navigate', (
    tester,
  ) async {
    final observer = _PushCountingObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: const LearnScreen(),
      ),
    );
    await tester.pumpAndSettle();
    final initialPushes = observer.pushCount;

    for (final label in <String>[
      'Chess Basics Mastery',
      'Openings Mastery',
      'Middlegame Mastery',
      'Endgame Mastery',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(LearnScreen), findsOneWidget);
      expect(observer.pushCount, initialPushes);
    }

    await tester.scrollUntilVisible(
      find.text('ROAD TO BECOMING A GM'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROAD TO BECOMING A GM'));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(observer.pushCount, initialPushes);
  });

  testWidgets('Learn tab layout fits a small Android viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();

    expect(find.text('Coming Soon'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}

class _PushCountingObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}
