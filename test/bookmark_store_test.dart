import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/bookmarks/bookmark_store.dart';
import 'package:turbo_chess/core/bookmarks/chess_bookmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fen = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('add bookmark stores a local position', () async {
    const store = BookmarkStore();
    final bookmark = _bookmark(id: 'one', fen: fen);

    await store.add(bookmark);
    final bookmarks = await store.load();

    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.fen, fen);
  });

  test('remove bookmark deletes it', () async {
    const store = BookmarkStore();
    final bookmark = _bookmark(id: 'one', fen: fen);

    await store.add(bookmark);
    await store.remove(bookmark.id);

    expect(await store.load(), isEmpty);
  });

  test('duplicate bookmark is prevented', () async {
    const store = BookmarkStore();

    await store.add(_bookmark(id: 'one', fen: fen));
    await store.add(_bookmark(id: 'two', fen: fen));

    final bookmarks = await store.load();
    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.id, 'one');
  });

  test('toggle removes an existing bookmark', () async {
    const store = BookmarkStore();
    final bookmark = _bookmark(id: 'one', fen: fen);

    expect(await store.toggle(bookmark), isNotNull);
    expect(await store.toggle(_bookmark(id: 'two', fen: fen)), isNull);

    expect(await store.load(), isEmpty);
  });

  test('play vs computer bookmarks cannot be created', () async {
    const store = BookmarkStore();

    await expectLater(
      store.add(
        ChessBookmark(
          id: 'play',
          fen: fen,
          sourceType: 'play_vs_computer',
          title: 'Computer game',
          savedAt: DateTime.utc(2026, 1, 1, 12),
        ),
      ),
      throwsArgumentError,
    );
  });
}

ChessBookmark _bookmark({
  required String id,
  required String fen,
}) {
  return ChessBookmark(
    id: id,
    fen: fen,
    sourceType: 'endgame',
    module: 'endgame',
    positionIndex: 1,
    title: 'Endgame Position 1',
    difficulty: 'Beginner',
    savedAt: DateTime.utc(2026, 1, 1, 12),
  );
}
