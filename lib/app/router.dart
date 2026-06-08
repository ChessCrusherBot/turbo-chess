import 'package:flutter/material.dart';

import '../core/design_system.dart';
import '../core/positions/position_category.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/learn/presentation/learn_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/play_computer/presentation/play_vs_computer_screen.dart';
import '../features/play_computer/presentation/play_computer_history_screen.dart';
import '../features/train/presentation/position_drill_screen.dart';
import '../features/train/presentation/position_grid_screen.dart';
import '../features/train/presentation/session_summary_screen.dart';
import '../features/train/presentation/train_screen.dart';
import 'app.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  final args = settings.arguments as Map<String, dynamic>? ?? {};

  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainShell(),
      );

    case '/home':
      return _SmoothPageRoute(
        settings: settings,
        child: const HomeScreen(),
      );

    case '/learn':
      return _SmoothPageRoute(
        settings: settings,
        child: const LearnScreen(),
      );

    case '/train':
      return _SmoothPageRoute(
        settings: settings,
        child: const TrainScreen(),
      );

    case '/more':
      return _SmoothPageRoute(
        settings: settings,
        child: const MoreScreen(),
      );

    case '/bookmarks':
      return _SmoothPageRoute(
        settings: settings,
        child: const BookmarksScreen(),
      );

    case '/play/computer':
      return _SmoothPageRoute(
        settings: settings,
        child: PlayVsComputerScreen(
          initialFen: args['fen']?.toString(),
          resumeActiveOnOpen: args['resumeActive'] == true,
        ),
      );

    case '/play/history':
      return _SmoothPageRoute(
        settings: settings,
        child: const PlayComputerHistoryScreen(),
      );

    case '/train/openings':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.opening),
      );

    case '/train/openings/subtopics':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.opening),
      );

    case '/train/openings/drill':
      final positionIndex = _tryPositionIndexFromArgs(args);
      if (positionIndex == null) {
        return _routeError(
          settings,
          title: 'Position route missing',
          message: 'Open this drill from the position grid.',
        );
      }
      return _SmoothPageRoute(
        settings: settings,
        child: PositionDrillScreen(
          category: PositionCategory.opening,
          positionIndex: positionIndex,
          resumeActiveOnOpen: args['resumeActive'] == true,
        ),
      );

    case '/train/middlegame':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.middlegame),
      );

    case '/train/middlegame/subtopics':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.middlegame),
      );

    case '/train/middlegame/drill':
      final positionIndex = _tryPositionIndexFromArgs(args);
      if (positionIndex == null) {
        return _routeError(
          settings,
          title: 'Position route missing',
          message: 'Open this drill from the position grid.',
        );
      }
      return _SmoothPageRoute(
        settings: settings,
        child: PositionDrillScreen(
          category: PositionCategory.middlegame,
          positionIndex: positionIndex,
          resumeActiveOnOpen: args['resumeActive'] == true,
        ),
      );

    case '/train/endgame':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.endgame),
      );

    case '/train/endgame/subtopics':
      return _SmoothPageRoute(
        settings: settings,
        child: const PositionGridScreen(category: PositionCategory.endgame),
      );

    case '/train/endgame/drill':
      final positionIndex = _tryPositionIndexFromArgs(args);
      if (positionIndex == null) {
        return _routeError(
          settings,
          title: 'Position route missing',
          message: 'Open this drill from the position grid.',
        );
      }
      return _SmoothPageRoute(
        settings: settings,
        child: PositionDrillScreen(
          category: PositionCategory.endgame,
          positionIndex: positionIndex,
          resumeActiveOnOpen: args['resumeActive'] == true,
        ),
      );

    case '/train/position/drill':
      final category = _tryCategoryFromArgs(args);
      final positionIndex = _tryPositionIndexFromArgs(args);
      if (category == null || positionIndex == null) {
        return _routeError(
          settings,
          title: 'Position route missing',
          message: 'Open this drill from the position grid.',
        );
      }
      return _SmoothPageRoute(
        settings: settings,
        child: PositionDrillScreen(
          category: category,
          positionIndex: positionIndex,
          resumeActiveOnOpen: args['resumeActive'] == true,
        ),
      );

    case '/train/session_summary':
      return _SmoothPageRoute(
        settings: settings,
        child: SessionSummaryScreen(
          topicName: args['topicName'] ?? '',
        ),
      );

    default:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainShell(),
      );
  }
}

PositionCategory? _tryCategoryFromArgs(Map<String, dynamic> args) {
  final rawCategory = args['category'];
  if (rawCategory is PositionCategory) return rawCategory;
  final rawId = rawCategory?.toString();
  for (final category in PositionCategory.values) {
    if (category.id == rawId) return category;
  }
  return null;
}

int? _tryPositionIndexFromArgs(Map<String, dynamic> args) {
  final rawIndex = args['positionIndex'];
  if (rawIndex is int && rawIndex >= 1 && rawIndex <= 10000) {
    return rawIndex;
  }
  final parsedIndex = int.tryParse(rawIndex?.toString() ?? '');
  if (parsedIndex == null || parsedIndex < 1 || parsedIndex > 10000) {
    return null;
  }
  return parsedIndex;
}

Route<dynamic> _routeError(
  RouteSettings settings, {
  required String title,
  required String message,
}) {
  return _SmoothPageRoute(
    settings: settings,
    child: _RouteErrorScreen(title: title, message: message),
  );
}

class _SmoothPageRoute extends PageRoute<void> {
  final Widget child;

  _SmoothPageRoute({required this.child, RouteSettings? settings})
      : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _RouteErrorScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: DesignSystem.warningLight,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: DesignSystem.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DesignSystem.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
