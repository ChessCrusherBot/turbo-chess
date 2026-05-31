import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/audio/turbo_sound_service.dart';
import 'package:turbo_chess/core/bookmarks/bookmark_store.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/features/bookmarks/presentation/bookmarks_screen.dart';
import 'package:turbo_chess/features/play_computer/presentation/play_vs_computer_screen.dart';
import 'package:turbo_chess/features/train/presentation/position_drill_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pieceFiles = <String>[
    'wK.svg',
    'wQ.svg',
    'wR.svg',
    'wB.svg',
    'wN.svg',
    'wP.svg',
    'bK.svg',
    'bQ.svg',
    'bR.svg',
    'bB.svg',
    'bN.svg',
    'bP.svg',
  ];

  const simpleFen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TurboSoundService.instance.debugResetForTesting();
  });

  test('all Cburnett BSD SVG and license assets exist', () {
    for (final fileName in pieceFiles) {
      final file = File('assets/pieces/cburnett_bsd/svg/$fileName');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(0), reason: file.path);
      expect(file.readAsStringSync(), contains('<svg'), reason: file.path);
    }

    for (final fileName in <String>[
      'LICENSE.txt',
      'SOURCE.md',
      'VERIFICATION.md',
    ]) {
      final file = File('assets/pieces/cburnett_bsd/$fileName');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(0), reason: file.path);
    }
  });

  test('pubspec registers Cburnett piece and legal assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/pieces/cburnett_bsd/svg/'));
    expect(pubspec, contains('assets/pieces/cburnett_bsd/LICENSE.txt'));
    expect(pubspec, contains('assets/pieces/cburnett_bsd/SOURCE.md'));
    expect(pubspec, contains('assets/pieces/cburnett_bsd/VERIFICATION.md'));
  });

  test('piece asset mapping uses only Cburnett BSD asset paths', () {
    const expected = <String, String>{
      'K': 'assets/pieces/cburnett_bsd/svg/wK.svg',
      'Q': 'assets/pieces/cburnett_bsd/svg/wQ.svg',
      'R': 'assets/pieces/cburnett_bsd/svg/wR.svg',
      'B': 'assets/pieces/cburnett_bsd/svg/wB.svg',
      'N': 'assets/pieces/cburnett_bsd/svg/wN.svg',
      'P': 'assets/pieces/cburnett_bsd/svg/wP.svg',
      'k': 'assets/pieces/cburnett_bsd/svg/bK.svg',
      'q': 'assets/pieces/cburnett_bsd/svg/bQ.svg',
      'r': 'assets/pieces/cburnett_bsd/svg/bR.svg',
      'b': 'assets/pieces/cburnett_bsd/svg/bB.svg',
      'n': 'assets/pieces/cburnett_bsd/svg/bN.svg',
      'p': 'assets/pieces/cburnett_bsd/svg/bP.svg',
    };

    for (final entry in expected.entries) {
      expect(ChessPieceAssets.assetForFenChar(entry.key), entry.value);
    }
  });

  testWidgets('ChessBoard renders starting position with SVG pieces', (
    tester,
  ) async {
    await _pumpBoard(tester, ChessBoard.starting());

    expect(find.byType(ChessBoardWidget), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(32));
  });

  testWidgets('ChessBoard renders a FEN containing all piece types', (
    tester,
  ) async {
    final board = ChessBoard.fromFen(
      'kqrbnp2/8/8/8/8/8/8/KQRBNP2 w - - 0 1',
    );

    await _pumpBoard(tester, board);

    expect(find.byType(ChessBoardWidget), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(12));
  });

  testWidgets('Opening, middlegame, and endgame Position 1 boards open', (
    tester,
  ) async {
    for (final category in PositionCategory.values) {
      await _pumpPositionDrill(tester, category, simpleFen);

      expect(find.byType(ChessBoardWidget), findsOneWidget);
      expect(find.byType(SvgPicture), findsAtLeastNWidgets(3));
    }
  });

  testWidgets('Play vs Computer opens a board with SVG pieces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlayVsComputerScreen()));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('start_computer_game')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ChessBoardWidget), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(32));
    expect(find.textContaining('Chess960'), findsNothing);
    expect(find.textContaining('variant'), findsNothing);
  });

  testWidgets('Paste FEN opens a board with SVG pieces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlayVsComputerScreen()));
    await tester.tap(find.text('Paste FEN'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), simpleFen);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('play_setup_list')),
      const Offset(0, -1200),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('start_computer_game')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start_computer_game')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ChessBoardWidget), findsOneWidget);
    expect(find.byType(SvgPicture), findsAtLeastNWidgets(3));
  });

  testWidgets('Bookmarks ignore old computer bookmarks after SVG integration', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      BookmarkStore.preferencesKey: [
        '{"id":"saved-cburnett-fen","fen":"$simpleFen","sourceType":"play_vs_computer","title":"Computer game","savedAt":"2026-01-01T12:00:00.000Z"}',
      ],
    });

    await tester.pumpWidget(
      const MaterialApp(home: BookmarksScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Computer game'), findsNothing);
    expect(find.text('No bookmarks yet'), findsOneWidget);
  });
}

Future<void> _pumpBoard(WidgetTester tester, ChessBoard board) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChessBoardWidget(board: board),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpPositionDrill(
  WidgetTester tester,
  PositionCategory category,
  String fen,
) async {
  final repo = PositionFenRepository(
    bundle: _FakePositionAssetBundle({
      category.assetPath: fen,
    }),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: PositionDrillScreen(
        category: category,
        positionIndex: 1,
        repository: repo,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
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
