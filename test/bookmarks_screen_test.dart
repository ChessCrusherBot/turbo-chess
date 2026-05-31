import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/bookmarks/bookmark_store.dart';
import 'package:turbo_chess/core/bookmarks/chess_bookmark.dart';
import 'package:turbo_chess/features/bookmarks/presentation/bookmarks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bookmark list opens a saved drill position', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const store = BookmarkStore();
    await store.add(
      ChessBookmark(
        id: 'saved-fen',
        fen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
        sourceType: 'endgame',
        module: 'endgame',
        positionIndex: 1,
        title: 'Endgame Position 1',
        savedAt: DateTime.utc(2026, 1, 1, 12),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/train/position/drill') {
            final args = settings.arguments as Map<String, dynamic>;
            expect(args['category'], 'endgame');
            expect(args['positionIndex'], 1);
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const Placeholder(key: ValueKey('opened_drill_bookmark')),
            );
          }
          return null;
        },
        home: const BookmarksScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark_saved-fen')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('opened_drill_bookmark')), findsOneWidget);
  });

  testWidgets('old play vs computer bookmarks are hidden', (tester) async {
    SharedPreferences.setMockInitialValues({
      BookmarkStore.preferencesKey: [
        jsonEncode({
          'id': 'old-play',
          'fen': '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
          'sourceType': 'play_vs_computer',
          'title': 'Computer game',
          'savedAt': DateTime.utc(2026, 1, 1, 12).toIso8601String(),
        }),
      ],
    });

    await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Computer game'), findsNothing);
    expect(find.text('No bookmarks yet'), findsOneWidget);
  });

  testWidgets('bookmark remove asks for confirmation and cancel keeps item',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const store = BookmarkStore();
    await store.add(
      ChessBookmark(
        id: 'saved-fen',
        fen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
        sourceType: 'endgame',
        module: 'endgame',
        positionIndex: 1,
        title: 'Endgame Position 1',
        difficulty: 'Beginner',
        savedAt: DateTime.utc(2026, 1, 1, 12),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Beginner'), findsNothing);
    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pumpAndSettle();

    expect(find.text('Remove bookmark?'), findsOneWidget);
    expect(
      find.text(
        'This position will be removed from your bookmarks. Your drill progress will not be affected.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsOneWidget);
    expect(await store.load(), hasLength(1));
  });

  testWidgets('bookmark remove confirmation deletes item', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const store = BookmarkStore();
    await store.add(
      ChessBookmark(
        id: 'saved-fen',
        fen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
        sourceType: 'endgame',
        module: 'endgame',
        positionIndex: 1,
        title: 'Endgame Position 1',
        savedAt: DateTime.utc(2026, 1, 1, 12),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: BookmarksScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_remove_bookmark')));
    await tester.pumpAndSettle();

    expect(find.text('Endgame Position 1'), findsNothing);
    expect(find.text('No bookmarks yet'), findsOneWidget);
    expect(await store.load(), isEmpty);
  });
}
