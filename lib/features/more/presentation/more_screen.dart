import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/ad_free_service.dart';
import '../../../core/ads/ad_free_status_widgets.dart';
import '../../../core/ads/ad_runtime.dart';
import '../../../core/ads/ad_shell.dart';
import '../../../core/ads/premium_pass_duration.dart';
import '../../../core/audio/turbo_sound_service.dart';
import '../../../core/design_system.dart';
import '../../../core/engine/engine_manager.dart';
import '../../../core/ui/turbo_chess_icons.dart';
import '../../../core/ui_components.dart';

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
      body: AdScreenFrame(
        isVisible: isVisible,
        bottomBannerUsesSafeArea: false,
        child: ListView(
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
            const _MorePremiumSection(),
            const SizedBox(height: 16),
            _MoreToolsList(
              onSettings: () => showSettingsSheet(context),
              onHowToPlay: () => showHowToDialog(context),
              onLegal: () => _showLegalNotices(context),
              onAbout: () => _showAbout(context),
            ),
          ],
        ),
      ),
    );
  }

  static const String _stockfishLegalNotice = '''
Stockfish chess engine

Turbo Chess includes Stockfish, a free open-source chess engine licensed under the GNU General Public License version 3 (GPLv3).

Stockfish version recorded for this build: Stockfish 18.
Source: https://github.com/official-stockfish/Stockfish
License: GNU GPLv3.

Turbo Chess is prepared for GPLv3/open-source release from an engineering perspective. GPLv3 license text and third-party notices are included in the app/source package.

Local files:
- assets/legal/GPL-3.0.txt
- assets/legal/THIRD_PARTY_NOTICES.md
- assets/legal/STOCKFISH_SOURCE.txt
- assets/legal/STOCKFISH_BUILDING.md

This software is provided without warranty to the extent permitted by the applicable licenses.
''';

  static const String _cburnettLegalNotice = '''
Chess pieces: Cburnett SVG chess pieces from Wikimedia Commons.
Author: Cburnett.
Source: Wikimedia Commons.
License selected: BSD license.

Turbo Chess selects the BSD license option offered on the Wikimedia Commons file pages. Turbo Chess does not imply endorsement by the author or contributors.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the BSD license conditions and disclaimer are retained.

Neither the name of The author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

This software is provided by The author and contributors "as is" and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed. In no event shall The author and contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages arising in any way out of the use of this software, even if advised of the possibility of such damage.

Chess sounds: OpenGameArt "Click sounds(6)" by pauliuw.
Source: https://opengameart.org/content/click-sounds6
License selected: CC0 1.0 Universal.

Turbo Chess uses renamed copies of selected click MP3 files for move, capture, check, and checkmate sounds. CC0 permits copying, modifying, distributing, and commercial use without attribution. Turbo Chess documents the source in assets/sounds/chess/.
''';

  static const String _fontAwesomeLegalNotice = '''
Font Awesome Free / font_awesome_flutter

Turbo Chess uses Font Awesome Free icons through the font_awesome_flutter Flutter package.

Font Awesome Free icons/fonts are by Fonticons, Inc. Font Awesome Free is distributed under its published free license terms, including CC BY 4.0 for SVG/JS icons, SIL OFL 1.1 for fonts, and MIT for code as applicable.

The font_awesome_flutter package is distributed under the MIT license by its contributors.

Only Font Awesome Free icons are used. No Font Awesome Pro icons are bundled.
''';

  static const String _brandingNotice = '''
Turbo Chess branding assets

Turbo Chess launcher icon is included as part of the Turbo Chess project assets.
''';

  static const String _legalNotice = '''
$_stockfishLegalNotice

Source code and licenses

Turbo Chess source code is intended to be released under the GNU General Public License version 3. See LICENSE, THIRD_PARTY_NOTICES.md, and docs/OPEN_SOURCE_RELEASE.md in the source package.

$_cburnettLegalNotice

$_fontAwesomeLegalNotice

$_brandingNotice
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
          'Offline chess training with playable drills and engine replies.',
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

class _MorePremiumSection extends StatefulWidget {
  const _MorePremiumSection();

  @override
  State<_MorePremiumSection> createState() => _MorePremiumSectionState();
}

class _MorePremiumSectionState extends State<_MorePremiumSection> {
  bool _rewardedAdLoading = false;
  bool _restoringPremium = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = AdFreeService.instance;
      if (service.isInitialized) {
        unawaited(service.refreshSubscriptionEntitlement());
      }
    });
  }

  Future<void> _watchRewardedAd() async {
    final service = AdFreeService.instance;
    if (_rewardedAdLoading || service.status.isAdFree) {
      return;
    }

    setState(() => _rewardedAdLoading = true);
    final result = await AdRuntime.instance.showRewardedAd();
    if (!mounted) {
      return;
    }

    if (result.isRewardEarned) {
      await service.grantRewardedAdFreePass(
        lastPassSource: 'more_screen_rewarded_ad',
      );
      if (!mounted) {
        return;
      }
      setState(() => _rewardedAdLoading = false);
      _showSnackBar(
        rewardedPremiumPassActivatedMessage,
        success: true,
      );
      return;
    }

    setState(() => _rewardedAdLoading = false);
    _showSnackBar(result.message, success: false);
  }

  Future<void> _subscribe() async {
    final service = AdFreeService.instance;
    await service.subscribeAdFree();
    if (!mounted) {
      return;
    }
    final status = service.status;
    _showSnackBar(
      status.subscriptionError ??
          status.subscriptionMessage ??
          'Complete the purchase in Google Play.',
      success: status.subscriptionError == null,
    );
  }

  Future<void> _restorePremium() async {
    if (_restoringPremium) {
      return;
    }
    setState(() => _restoringPremium = true);
    final result = await AdFreeService.instance.restorePremium();
    if (!mounted) {
      return;
    }
    setState(() => _restoringPremium = false);
    if (result.status == PremiumRestoreStatus.notFound) {
      _showRestoreHelpDialog(result.message);
      return;
    }
    _showSnackBar(
      result.message,
      success: result.status == PremiumRestoreStatus.restored,
    );
  }

  Future<void> _manageSubscription() async {
    final opened = await AdFreeService.instance.openManageSubscription();
    if (!mounted) {
      return;
    }
    if (!opened) {
      _showSnackBar(
        'Manage this subscription in Google Play > Payments & subscriptions.',
        success: false,
      );
    }
  }

  void _showSnackBar(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? DesignSystem.backgroundElevated
            : DesignSystem.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRestoreHelpDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('Restore Premium'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHowRestoreWorks() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignSystem.backgroundRaised,
        title: const Text('How restore works'),
        content: const Text(PremiumSubscriptionCopy.accountNoticeLong),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdFreeService.instance,
      builder: (context, _) {
        final status = AdFreeService.instance.status;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PremiumStatusCard(status: status),
            const SizedBox(height: 10),
            _SubscriptionSection(
              status: status,
              onSubscribe: _subscribe,
              onRestore: _restorePremium,
              onExplainRestore: _showHowRestoreWorks,
              onManage: _manageSubscription,
              isRestoring: _restoringPremium,
            ),
            const SizedBox(height: 10),
            _RewardedPassSection(
              status: status,
              isLoading: _rewardedAdLoading,
              onWatchAd: _watchRewardedAd,
            ),
          ],
        );
      },
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  final AdFreeStatus status;

  const _PremiumStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isWarning = status.shouldShowVerificationMessage;
    final isActive = status.isAdFree;
    final statusTitle = isActive ? 'Ad-free access' : 'Free access';
    final statusSubtitle = status.hasActiveSubscription
        ? 'Premium active'
        : status.hasRewardedPass
            ? AdFreeStatusCopy.remainingCompact(status.remainingDuration)
            : isWarning
                ? 'Verification required'
                : 'Ads active';
    final iconColor = isWarning
        ? DesignSystem.warningLight
        : isActive
            ? DesignSystem.tertiaryLight
            : DesignSystem.primaryLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withAlpha(isActive ? 70 : 44)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(34),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TurboChessIconSymbol(
              glyph: TurboChessIconGlyph.adFreeAccess,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Premium Status',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DesignSystem.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: DesignSystem.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isWarning
                        ? DesignSystem.warningLight
                        : isActive
                            ? DesignSystem.tertiaryLight
                            : DesignSystem.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  final AdFreeStatus status;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback onExplainRestore;
  final VoidCallback onManage;
  final bool isRestoring;

  const _SubscriptionSection({
    required this.status,
    required this.onSubscribe,
    required this.onRestore,
    required this.onExplainRestore,
    required this.onManage,
    required this.isRestoring,
  });

  @override
  Widget build(BuildContext context) {
    final product = status.subscriptionProductDetails;
    final isBusy = status.isSubscriptionVerifying ||
        status.isSubscriptionPurchasePending ||
        isRestoring;
    final canSubscribe =
        product != null && !status.hasActiveSubscription && !isBusy;
    final detail = status.hasActiveSubscription
        ? 'Premium active via Google Play.'
        : product != null
            ? 'Ad-free subscription - ${product.price} / 4 weeks'
            : status.subscriptionMessage ??
                (status.isSubscriptionStoreAvailable
                    ? PremiumSubscriptionCopy.productUnavailableMessage
                    : PremiumSubscriptionCopy.billingUnavailableMessage);

    return _MonetizationPanel(
      icon: Icons.workspace_premium_rounded,
      label: 'Subscription',
      iconWidget: const TurboChessIconSymbol(
        glyph: TurboChessIconGlyph.subscribeAdFree,
        color: DesignSystem.primaryLight,
        size: 21,
      ),
      iconColor: DesignSystem.primaryLight,
      title: 'Subscribe ad-free',
      subtitle: detail,
      footer: status.subscriptionError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SubscriptionInfoBox(),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Subscribe to ad-free Turbo Chess',
            child: PremiumButton(
              text: status.hasActiveSubscription
                  ? 'Subscription active'
                  : isBusy
                      ? 'Checking'
                      : 'Subscribe',
              icon: status.hasActiveSubscription
                  ? Icons.check_circle_rounded
                  : Icons.workspace_premium_rounded,
              onPressed: canSubscribe ? onSubscribe : null,
              isLoading: isBusy,
              fullWidth: true,
              height: 50,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 10),
          _SecondaryActionButton(
            onPressed: isBusy ? null : onRestore,
            icon: Icons.restore_rounded,
            text: 'Restore Premium',
            isLoading: isRestoring,
          ),
          const SizedBox(height: 8),
          _SecondaryActionButton(
            onPressed: onExplainRestore,
            icon: Icons.help_outline_rounded,
            text: 'How restore works',
            quiet: true,
          ),
          if (status.hasActiveSubscription) ...[
            const SizedBox(height: 8),
            _SecondaryActionButton(
              onPressed: onManage,
              icon: Icons.open_in_new_rounded,
              text: 'Manage subscription',
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionInfoBox extends StatelessWidget {
  const _SubscriptionInfoBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundBase.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignSystem.border),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubscriptionInfoLine(
              icon: Icons.account_circle_outlined,
              text: PremiumSubscriptionCopy.accountNoticeLine1,
            ),
            SizedBox(height: 7),
            _SubscriptionInfoLine(
              icon: Icons.restore_rounded,
              text: PremiumSubscriptionCopy.accountNoticeLine2,
            ),
            SizedBox(height: 7),
            _SubscriptionInfoLine(
              icon: Icons.verified_user_outlined,
              text: PremiumSubscriptionCopy.accountNoticeLine3,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SubscriptionInfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: DesignSystem.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DesignSystem.textSecondary,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool quiet;

  const _SecondaryActionButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        quiet ? DesignSystem.textSecondary : DesignSystem.textPrimary;
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: foreground,
          side: BorderSide(
            color: quiet
                ? DesignSystem.border.withAlpha(150)
                : DesignSystem.primary.withAlpha(82),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(text),
      ),
    );
  }
}

class _RewardedPassSection extends StatelessWidget {
  final AdFreeStatus status;
  final bool isLoading;
  final VoidCallback onWatchAd;

  const _RewardedPassSection({
    required this.status,
    required this.isLoading,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyAdFree = status.isAdFree;
    final detail = status.hasActiveSubscription
        ? 'Your subscription already hides banner ads.'
        : status.hasRewardedPass
            ? AdFreeStatusCopy.activeUntilLine(status)
            : status.shouldShowVerificationMessage
                ? 'Ad-free status could not be verified. Please reconnect to the internet.'
                : rewardedPremiumPassDescription;

    return _MonetizationPanel(
      icon: Icons.confirmation_number_rounded,
      label: 'Premium Pass',
      iconWidget: const TurboChessIconSymbol(
        glyph: TurboChessIconGlyph.premiumPass,
        color: DesignSystem.tertiaryLight,
        size: 21,
      ),
      iconColor: DesignSystem.tertiaryLight,
      title: rewardedPremiumPassTitle,
      subtitle: detail,
      child: Semantics(
        button: true,
        label: 'Watch ad to activate $rewardedPremiumPassTitle',
        child: PremiumButton(
          text: alreadyAdFree ? 'Ad-free active' : 'Watch ad',
          icon: alreadyAdFree
              ? Icons.check_circle_rounded
              : Icons.play_circle_fill_rounded,
          onPressed: alreadyAdFree || isLoading ? null : onWatchAd,
          isLoading: isLoading,
          fullWidth: true,
          height: 50,
          borderRadius: 16,
          backgroundColor:
              alreadyAdFree ? DesignSystem.tertiary : DesignSystem.primary,
          glowColor:
              alreadyAdFree ? DesignSystem.tertiary : DesignSystem.primary,
        ),
      ),
    );
  }
}

class _MonetizationPanel extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final Color iconColor;
  final String? label;
  final String title;
  final String subtitle;
  final String? footer;
  final Widget child;

  const _MonetizationPanel({
    required this.icon,
    this.iconWidget,
    required this.iconColor,
    this.label,
    required this.title,
    required this.subtitle,
    this.footer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: iconWidget ?? Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: DesignSystem.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DesignSystem.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          if (footer != null && footer!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              footer!,
              style: const TextStyle(
                color: DesignSystem.errorLight,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
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
