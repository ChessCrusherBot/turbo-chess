import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/ad_shell.dart';
import '../../../core/bookmarks/bookmark_store.dart';
import '../../../core/bookmarks/chess_bookmark.dart';
import '../../../core/design/turbo_icons.dart';
import '../../../core/design_system.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkStore _store = const BookmarkStore();
  late Future<List<ChessBookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _store.load();
  }

  void _refresh() {
    setState(() {
      _bookmarksFuture = _store.load();
    });
  }

  Future<void> _remove(ChessBookmark bookmark) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove bookmark?'),
        content: const Text(
          'This position will be removed from your bookmarks. Your drill progress will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_remove_bookmark'),
            style: FilledButton.styleFrom(
              backgroundColor: DesignSystem.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;

    await _store.remove(bookmark.id);
    if (mounted) _refresh();
  }

  void _open(ChessBookmark bookmark) {
    final source = bookmark.sourceType;
    final positionIndex = bookmark.positionIndex;
    if ((source == 'opening' ||
            source == 'middlegame' ||
            source == 'endgame') &&
        positionIndex != null) {
      Navigator.pushNamed(
        context,
        '/train/position/drill',
        arguments: {
          'category': source,
          'positionIndex': positionIndex,
        },
      ).then((_) {
        if (mounted) _refresh();
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only drill bookmarks can be opened here.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundBase,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.transparent,
      ),
      body: AdScreenFrame(
        child: FutureBuilder<List<ChessBookmark>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookmarks = snapshot.data ?? const <ChessBookmark>[];
            if (bookmarks.isEmpty) {
              return const _EmptyBookmarks();
            }
            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return _BookmarkTile(
                  bookmark: bookmark,
                  onOpen: () => _open(bookmark),
                  onRemove: () => _remove(bookmark),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TurboIconBadge(
              kind: TurboIconKind.bookmarks,
              color: DesignSystem.secondary,
              size: 58,
              iconSize: 32,
            ),
            SizedBox(height: 14),
            Text(
              'No bookmarks yet',
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Save a position from a drill.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignSystem.textMuted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy h:mm a');

  final ChessBookmark bookmark;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _BookmarkTile({
    required this.bookmark,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sourceLabel = _sourceLabel(bookmark.sourceType);
    final subtitleParts = [
      if (bookmark.module != null) sourceLabel,
      _dateFormat.format(bookmark.savedAt.toLocal()),
    ];

    return Semantics(
      button: true,
      label: 'Open bookmark ${bookmark.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('bookmark_${bookmark.id}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignSystem.backgroundRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DesignSystem.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const TurboIconBadge(
                    kind: TurboIconKind.bookmarks,
                    color: DesignSystem.secondary,
                    size: 46,
                    iconSize: 25,
                    glow: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DesignSystem.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitleParts.join(' | '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DesignSystem.textMuted,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove bookmark',
                    onPressed: onRemove,
                    icon: const Icon(Icons.bookmark_remove_rounded),
                    color: DesignSystem.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sourceLabel(String sourceType) {
    switch (sourceType) {
      case 'opening':
        return 'Opening';
      case 'middlegame':
        return 'Middlegame';
      case 'endgame':
        return 'Endgame';
      default:
        return 'Drill';
    }
  }
}
