import 'package:flutter/material.dart';

enum AdBannerPlacement { top, bottom }

class AdBannerPolicy {
  const AdBannerPolicy._();

  static bool shouldShowBanners({required bool screenVisible}) => false;
}

class AdScreenFrame extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final bool showTopBanner;
  final bool showBottomBanner;
  final bool topBannerUsesSafeArea;
  final bool bottomBannerUsesSafeArea;

  const AdScreenFrame({
    super.key,
    required this.child,
    this.isVisible = true,
    this.showTopBanner = true,
    this.showBottomBanner = false,
    this.topBannerUsesSafeArea = false,
    this.bottomBannerUsesSafeArea = true,
  });

  @override
  Widget build(BuildContext context) => child;
}

class AdBannerSlot extends StatelessWidget {
  final AdBannerPlacement placement;
  final bool isVisible;
  final bool usesTopSafeArea;
  final bool usesBottomSafeArea;

  const AdBannerSlot({
    super.key,
    required this.placement,
    this.isVisible = true,
    this.usesTopSafeArea = false,
    this.usesBottomSafeArea = true,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
