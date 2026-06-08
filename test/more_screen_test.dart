import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/features/more/presentation/more_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TurboSoundService.instance.debugResetForTesting();
  });

  testWidgets('More screen shows tools without monetization UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.byType(Icon), findsWidgets);

    for (final forbidden in <String>[
      'Access Status',
      'Ad-free access',
      'Free access',
      'Ads active',
      '72-Hour Rewarded Pass',
      'Watch rewarded ad',
      'Subscribe',
      'Restore Premium',
      'Manage subscription',
      'Google Play',
    ]) {
      expect(find.textContaining(forbidden), findsNothing);
    }
  });

  testWidgets('More screen tools layout fits small phones', (tester) async {
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
    expect(find.text('Subscribe'), findsNothing);

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
    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

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
      find.textContaining('Version 1.0.0'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Offline chess training with playable drills'),
      findsOneWidget,
    );
    expect(find.textContaining('free and ad-free'), findsOneWidget);
    expect(find.textContaining('does not use login, accounts'), findsOneWidget);
    expect(find.textContaining('analytics'), findsOneWidget);
    expect(find.textContaining('cloud sync'), findsOneWidget);
    expect(find.textContaining('in-app payments'), findsOneWidget);
    expect(find.textContaining('stored locally'), findsOneWidget);
  });

  testWidgets('More Legal notice is clean and keeps required notices',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MoreScreen(),
      ),
    );
    await tester.pumpAndSettle();

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

    for (final required in <String>[
      'Stockfish chess engine',
      'GPLv3',
      'Stockfish 18',
      'official Stockfish project',
      'Source code and licenses',
      'Source code',
      'https://github.com/ChessCrusherBot/turbo-chess',
      'Chess pieces',
      'Cburnett',
      'Chess sounds',
      'OpenGameArt',
      'Font Awesome Free',
      'Position/FEN files',
      'Lichess',
      'CC0',
      'does not use Lichess broadcast games',
      'Google Fonts',
      'Privacy and offline behavior',
      'offline Android app',
      'does not include ads',
      'does not request the INTERNET permission',
      'Android build libraries',
      'Turbo Chess branding assets',
    ]) {
      expect(find.textContaining(required), findsWidgets, reason: required);
    }

    for (final forbidden in <String>[
      'assets/legal/',
      'assets/sounds/',
      'assets/positions/',
      'THIRD_PARTY_NOTICES.md',
      'STOCKFISH_SOURCE.txt',
      'STOCKFISH_BUILDING.md',
      'TURBO_CHESS_SOURCE.md',
      '.md',
      '.txt',
      'Local files',
      'Included in the app/source package:',
      'Project generation notes',
      'Current project notes',
      'before Play Store upload',
      'pre-upload',
      'final review',
      'human/legal review',
      'TODO',
    ]) {
      expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
    }

    expect(find.textContaining('without warranty'), findsWidgets);
    expect(find.textContaining('No Font Awesome Pro icons'), findsOneWidget);
    expect(
        find.textContaining('stored locally on this device'), findsOneWidget);
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
