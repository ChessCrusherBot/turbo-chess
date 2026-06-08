import 'package:flutter/material.dart';

import '../../../core/audio/turbo_sound_service.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/engine_manager.dart';
import '../../../core/ui/turbo_chess_icons.dart';

class MoreScreen extends StatelessWidget {
  final bool isVisible;

  const MoreScreen({
    super.key,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tools & Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: DesignSystem.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore additional chess tools.',
                  style: TextStyle(color: DesignSystem.textMuted),
                ),
              ],
            ),
          ),
          _MoreToolsList(
            onSettings: () => showSettingsSheet(context),
            onHowToPlay: () => showHowToDialog(context),
            onLegal: () => _showLegalNotices(context),
            onAbout: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  static const String _legalNotice = '''
Stockfish chess engine

Turbo Chess includes Stockfish, a free and open-source chess engine licensed under the GNU General Public License version 3 (GPLv3).

Stockfish version recorded for this build: Stockfish 18.

Source: https://github.com/official-stockfish/Stockfish

License: GNU GPLv3.

GPLv3 license text, Stockfish source information, Stockfish build notes, and third-party notices are included with the app/source package. Stockfish source code and license information are also available from the official Stockfish project.

This software is provided without warranty to the extent permitted by the applicable licenses.

Source code and licenses

Turbo Chess source and license information is documented in the app/source package and third-party notices.

Source code

Turbo Chess source code, license notices, and release source information are available at:

https://github.com/ChessCrusherBot/turbo-chess

Chess pieces

Turbo Chess uses Cburnett SVG chess pieces from Wikimedia Commons.

Author: Cburnett.

Source: Wikimedia Commons.

License selected: BSD license.

Turbo Chess does not imply endorsement by the author or contributors.

The BSD license permits redistribution and use in source and binary forms, with or without modification, provided that the license conditions and disclaimer are retained.

Chess sounds

Turbo Chess uses selected click sound files from OpenGameArt "Click sounds(6)" by pauliuw.

License selected: CC0 1.0 Universal.

The sound source and license notice are included with the app/source package.

Font Awesome Free / font_awesome_flutter

Turbo Chess uses Font Awesome Free icons through the font_awesome_flutter Flutter package.

Font Awesome Free icons/fonts are by Fonticons, Inc. Font Awesome Free is distributed under its published free license terms, including CC BY 4.0 for SVG/JS icons, SIL OFL 1.1 for fonts, and MIT for code as applicable.

The font_awesome_flutter package is distributed under the MIT license by its contributors.

Only Font Awesome Free icons are used. No Font Awesome Pro icons are bundled.

Position/FEN files

Turbo Chess includes bundled opening, middlegame, and endgame FEN training files for offline chess practice.

Turbo Chess includes bundled FEN training positions derived from Lichess open database material for offline chess practice.

Lichess publishes its standard open database exports under CC0. Turbo Chess does not use Lichess broadcast games.

Google Fonts / google_fonts

Turbo Chess uses the google_fonts Flutter package for Inter text styles. The runtime font fetching path is disabled in app startup, and the Android release app does not request the INTERNET permission.

Privacy and offline behavior

Turbo Chess is designed as an offline Android app. It does not include ads, login/accounts, analytics, crash reporting, cloud sync, or in-app payments.

Training progress, settings, bookmarks, active games, and game history are stored locally on this device. The Android release manifest does not request INTERNET, location, camera, microphone, contacts, photos, or file-storage permissions.

Android build libraries

Turbo Chess declares Android Play Core and AndroidX multidex Gradle libraries. These are Android support libraries and are not monetization features.

Turbo Chess branding assets

Turbo Chess launcher icon is included as part of the Turbo Chess project assets.
''';

  Future<void> showSettingsSheet(BuildContext context) async {
    final soundService = TurboSoundService.instance;
    await soundService.initialize();
    final soundEnabled = soundService.isEnabled;
    final hapticEnabled = await soundService.isHapticEnabled();
    if (!context.mounted) return;

    var localSound = soundEnabled;
    var localHaptic = hapticEnabled;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignSystem.backgroundRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final mediaQuery = MediaQuery.of(sheetContext);
            final bottomSafeMinimum = mediaQuery.viewPadding.bottom >
                    mediaQuery.systemGestureInsets.bottom
                ? mediaQuery.viewPadding.bottom
                : mediaQuery.systemGestureInsets.bottom;

            return SafeArea(
              top: false,
              bottom: true,
              minimum: EdgeInsets.only(bottom: bottomSafeMinimum),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: mediaQuery.size.height * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: DesignSystem.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              SwitchListTile(
                                value: localSound,
                                onChanged: (value) async {
                                  await soundService.setEnabled(value);
                                  setSheetState(() => localSound = value);
                                },
                                title: const Text('Sound'),
                                subtitle: const Text('Move and game sounds'),
                                secondary: const Icon(Icons.volume_up_rounded),
                              ),
                              SwitchListTile(
                                value: localHaptic,
                                onChanged: (value) async {
                                  await soundService.setHapticEnabled(value);
                                  setSheetState(() => localHaptic = value);
                                },
                                title: const Text('Haptic Feedback'),
                                secondary: const Icon(Icons.vibration_rounded),
                              ),
                              ListTile(
                                leading: const Icon(Icons.refresh_rounded),
                                title: const Text('Reset Engine'),
                                subtitle: const Text(
                                  'Retry Stockfish initialization',
                                ),
                                onTap: () async {
                                  await EngineManager().resetEngineFlag();
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showHowToDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('How to Use Turbo Chess'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Tap a piece on the board to select it. Green dots show where it can move.',
            ),
            SizedBox(height: 8),
            Text(
              '2. Tap a destination to make your move. The app validates it automatically.',
            ),
            SizedBox(height: 8),
            Text(
              '3. Open any drill to play a full engine-backed game from that position.',
            ),
            SizedBox(height: 8),
            Text(
              '4. After the game ends, choose next drill, retry, or back to training from the result dialog.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLegalNotices(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('Legal'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.65,
            ),
            child: const SingleChildScrollView(
              child: Text(
                _legalNotice,
                style: TextStyle(height: 1.35),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('Turbo Chess'),
        content: const Text(
          'Version 1.0.0\n\n'
          'Offline chess training with playable drills and engine replies.\n\n'
          'Turbo Chess is free and ad-free. It does not use login, accounts, '
          'analytics, cloud sync, or in-app payments.\n\n'
          'Progress, settings, bookmarks, and game history are stored locally '
          'on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MoreToolsList extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onHowToPlay;
  final VoidCallback onLegal;
  final VoidCallback onAbout;

  const _MoreToolsList({
    required this.onSettings,
    required this.onHowToPlay,
    required this.onLegal,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignSystem.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _MoreToolRow(
              icon: TurboChessIconGlyph.settings,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Settings',
              subtitle: 'Sound, haptics, and display preferences',
              onTap: onSettings,
            ),
            const _MoreToolDivider(),
            _MoreToolRow(
              icon: TurboChessIconGlyph.howToPlay,
              iconColor: DesignSystem.tertiary,
              title: 'How to Play',
              subtitle: 'Learn how to use Turbo Chess training',
              onTap: onHowToPlay,
            ),
            const _MoreToolDivider(),
            _MoreToolRow(
              icon: TurboChessIconGlyph.legal,
              iconColor: DesignSystem.tertiaryLight,
              title: 'Legal',
              subtitle: 'Open-source notices and asset licenses',
              onTap: onLegal,
            ),
            const _MoreToolDivider(),
            _MoreToolRow(
              icon: TurboChessIconGlyph.about,
              iconColor: DesignSystem.textMuted,
              title: 'About',
              subtitle: 'Turbo Chess v1.0.0',
              onTap: onAbout,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreToolRow extends StatelessWidget {
  final TurboChessIconGlyph icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreToolRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: iconColor.withAlpha(44)),
                ),
                child: TurboChessIconSymbol(
                  glyph: icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignSystem.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignSystem.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreToolDivider extends StatelessWidget {
  const _MoreToolDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 14,
      color: DesignSystem.border,
    );
  }
}
