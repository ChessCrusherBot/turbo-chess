import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/features/more/presentation/more_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TurboSoundService.instance.debugResetForTesting();
  });

  testWidgets('More screen shows ad-free options without crashing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Premium Status'), findsOneWidget);
    expect(find.text('Ad-free access'), findsNothing);
    expect(find.text('Free access'), findsOneWidget);
    expect(find.text('Ads active'), findsOneWidget);
    expect(find.text('Subscribe ad-free'), findsOneWidget);
    expect(find.text('3-Day Premium Pass'), findsOneWidget);
    expect(find.text('24-Hour Premium Pass'), findsNothing);
    expect(find.byType(Icon), findsWidgets);
    expect(
      find.text(
        'Unlock all positions and remove ads for 3 days.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('24 hours'), findsNothing);
    expect(find.text('Restore Premium'), findsOneWidget);
    expect(find.text('How restore works'), findsOneWidget);
    expect(
      find.text(
        'Google Play Billing is unavailable right now. Please try again later.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('linked to your Google Account'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Turbo Chess does not create a separate app account'),
      findsOneWidget,
    );
    expect(find.textContaining('one phone only'), findsNothing);
    expect(find.textContaining('one device only'), findsNothing);
    expect(find.textContaining('7' + '-day'), findsNothing);
    expect(find.textContaining('7 ' + 'days'), findsNothing);
    expect(find.textContaining('seven ' + 'days'), findsNothing);
  });

  testWidgets('More screen premium layout fits small phones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Premium Status'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('3-Day Premium Pass'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('More screen has no review or gamification UI', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pump();

    for (final forbidden in <String>[
      'Game Review',
      'XP',
      'Streak',
      'Coins',
      'Achievements',
    ]) {
      expect(find.textContaining(forbidden), findsNothing);
    }
  });

  testWidgets('More page option order is Settings, How to Play, Legal, About',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final labels = ['Settings', 'How to Play', 'Legal', 'About'];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }

    final yPositions = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(yPositions, orderedEquals([...yPositions]..sort()));
  });

  testWidgets('How to Play and About still open from More', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('How to Play'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('How to Play'));
    await tester.pump();
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('How to Use Turbo Chess'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('About'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('About'));
    await tester.pump();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Turbo Chess'), findsOneWidget);
    expect(
      find.text(
          'Offline chess training with playable drills and engine replies.'),
      findsOneWidget,
    );
  });

  testWidgets('More Legal notice includes GPLv3 and asset notices',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Legal'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Legal'));
    await tester.pump();
    await tester.tap(find.text('Legal'));
    await tester.pumpAndSettle();

    expect(find.text('Legal'), findsWidgets);
    expect(find.textContaining('Stockfish chess engine'), findsOneWidget);
    expect(find.textContaining('GPLv3'), findsWidgets);
    expect(
      find.textContaining('GNU General Public License version 3'),
      findsWidgets,
    );
    expect(find.textContaining('source code'), findsWidgets);
    expect(find.textContaining('without warranty'), findsWidgets);
    expect(find.textContaining('Cburnett SVG chess pieces'), findsOneWidget);
    expect(
        find.textContaining('License selected: BSD license'), findsOneWidget);
    expect(
      find.textContaining('does not imply endorsement'),
      findsOneWidget,
    );
    expect(find.textContaining('Click sounds(6)'), findsOneWidget);
    expect(find.textContaining('License selected: CC0'), findsOneWidget);
    expect(find.textContaining('Font Awesome Free'), findsOneWidget);
    expect(find.textContaining('No Font Awesome Pro icons'), findsOneWidget);
    expect(find.textContaining('Turbo Chess launcher icon'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  test('pubspec bundles GPL and Stockfish legal assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/legal/'));
    expect(pubspec, contains('assets/stockfish/LICENSE.txt'));
    expect(pubspec, contains('assets/stockfish/STOCKFISH_SOURCE.txt'));
    expect(pubspec, contains('assets/pieces/cburnett_bsd/LICENSE.txt'));
    expect(pubspec, contains('assets/sounds/chess/'));
  });

  testWidgets('Settings sheet keeps Close button above gesture area', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 560);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    tester.view.systemGestureInsets = const FakeViewPadding(bottom: 34);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      tester.view.resetViewPadding();
      tester.view.resetSystemGestureInsets();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Settings'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Settings'));
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Move and game sounds'), findsOneWidget);
    expect(find.text('Haptic Feedback'), findsOneWidget);
    expect(find.text('Reset Engine'), findsOneWidget);

    final closeButton = find.widgetWithText(ElevatedButton, 'Close');
    expect(closeButton, findsOneWidget);

    final screenBottom = tester.view.physicalSize.height;
    final unsafeBottom = tester.view.systemGestureInsets.bottom;
    final closeRect = tester.getRect(closeButton);
    expect(closeRect.bottom, lessThanOrEqualTo(screenBottom - unsafeBottom));

    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(closeButton, findsNothing);
  });

  testWidgets('Settings Sound toggle persists off and on', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Settings'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Settings'));
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TurboSoundService.soundEnabledKey), isFalse);

    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TurboSoundService.soundEnabledKey), isTrue);
  });
}
