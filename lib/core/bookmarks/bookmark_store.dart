import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../chess/chess_board.dart';
import 'chess_bookmark.dart';

class BookmarkStore {
  static const String preferencesKey = 'turbo_chess_bookmarks_v1';
  static const Set<String> drillSourceTypes = {
    'opening',
    'middlegame',
    'endgame',
  };

  const BookmarkStore();

  static bool isDrillBookmark(ChessBookmark bookmark) {
    return drillSourceTypes.contains(bookmark.sourceType);
  }

  Future<List<ChessBookmark>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(preferencesKey) ?? const <String>[];
    final bookmarks = <ChessBookmark>[];
    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final bookmark = ChessBookmark.fromJson(decoded);
        if (bookmark.id.isEmpty ||
            !isDrillBookmark(bookmark) ||
            ChessBoard.tryFromFen(bookmark.fen) == null) {
          continue;
        }
        bookmarks.add(bookmark);
      } catch (_) {
        continue;
      }
    }
    bookmarks.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return bookmarks;
  }

  Future<ChessBookmark> add(ChessBookmark bookmark) async {
    if (!isDrillBookmark(bookmark)) {
      throw ArgumentError.value(
        bookmark.sourceType,
        'sourceType',
        'Only drill positions can be bookmarked.',
      );
    }
    if (ChessBoard.tryFromFen(bookmark.fen) == null) {
      throw FormatException('Bookmark FEN is invalid.', bookmark.fen);
    }

    final bookmarks = await load();
    final existing = findDuplicate(bookmarks, bookmark);
    if (existing != null) return existing;

    final updated = [bookmark, ...bookmarks];
    await _save(updated);
    return bookmark;
  }

  Future<void> remove(String id) async {
    final bookmarks = await load();
    await _save(bookmarks.where((bookmark) => bookmark.id != id).toList());
  }

  Future<ChessBookmark?> toggle(ChessBookmark bookmark) async {
    if (!isDrillBookmark(bookmark)) {
      throw ArgumentError.value(
        bookmark.sourceType,
        'sourceType',
        'Only drill positions can be bookmarked.',
      );
    }
    final bookmarks = await load();
    final existing = findDuplicate(bookmarks, bookmark);
    if (existing != null) {
      await _save(
        bookmarks.where((item) => item.id != existing.id).toList(),
      );
      return null;
    }
    final updated = [bookmark, ...bookmarks];
    await _save(updated);
    return bookmark;
  }

  ChessBookmark? findDuplicate(
    List<ChessBookmark> bookmarks,
    ChessBookmark bookmark,
  ) {
    for (final existing in bookmarks) {
      if (existing.duplicateKey == bookmark.duplicateKey) return existing;
    }
    return null;
  }

  Future<void> _save(List<ChessBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = <String>{};
    final encoded = <String>[];
    for (final bookmark in bookmarks) {
      if (!isDrillBookmark(bookmark)) continue;
      if (!seen.add(bookmark.duplicateKey)) continue;
      encoded.add(jsonEncode(bookmark.toJson()));
    }
    await prefs.setStringList(preferencesKey, encoded);
  }
}
