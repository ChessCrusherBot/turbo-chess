import 'package:flutter/material.dart';

import '../core/design_system.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/learn/presentation/learn_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/train/presentation/train_screen.dart';
import 'router.dart';
import 'theme.dart';

const String _initialAppRoute =
    String.fromEnvironment('TURBO_CHESS_INITIAL_ROUTE', defaultValue: '/');

class TurboChessApp extends StatelessWidget {
  const TurboChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo Chess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: generateRoute,
      initialRoute: _initialAppRoute,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(isVisible: _selectedIndex == 0),
          LearnScreen(isVisible: _selectedIndex == 1),
          TrainScreen(isVisible: _selectedIndex == 2),
          MoreScreen(isVisible: _selectedIndex == 3),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: DesignSystem.backgroundBase.withAlpha(240),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: const Border(
              top: BorderSide(color: DesignSystem.border, width: 1),
            ),
            boxShadow: DesignSystem.shadowLg,
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_rounded,
                  color: DesignSystem.textMuted,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: DesignSystem.primaryLight,
                  size: 24,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.menu_book_rounded,
                  color: DesignSystem.textMuted,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.menu_book_rounded,
                  color: DesignSystem.primaryLight,
                  size: 24,
                ),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.school_rounded,
                  color: DesignSystem.textMuted,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.school_rounded,
                  color: DesignSystem.primaryLight,
                  size: 24,
                ),
                label: 'Train',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: DesignSystem.textMuted,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.more_horiz_rounded,
                  color: DesignSystem.primaryLight,
                  size: 24,
                ),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
