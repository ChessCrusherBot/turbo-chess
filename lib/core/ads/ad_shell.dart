import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../design_system.dart';
import 'ad_free_service.dart';
import 'ad_runtime.dart';

enum AdBannerPlacement { top, bottom }

class AdBannerPolicy {
  const AdBannerPolicy._();

  static bool shouldShowBanners({
    required bool screenVisible,
    required bool adsRuntimeEnabled,
    required bool isAdFree,
  }) {
    return screenVisible && adsRuntimeEnabled && !isAdFree;
  }
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBanner)
          AdBannerSlot(
            placement: AdBannerPlacement.top,
            isVisible: isVisible,
            usesTopSafeArea: topBannerUsesSafeArea,
          ),
        Expanded(child: child),
        if (showBottomBanner)
          AdBannerSlot(
            placement: AdBannerPlacement.bottom,
            isVisible: isVisible,
            usesBottomSafeArea: bottomBannerUsesSafeArea,
          ),
      ],
    );
  }
}

class AdBannerSlot extends StatefulWidget {
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
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get _canShowAds {
    return AdBannerPolicy.shouldShowBanners(
      screenVisible: widget.isVisible,
      adsRuntimeEnabled: AdRuntime.instance.canUseAds,
      isAdFree: AdFreeService.instance.isAdFree,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdFreeService.instance.addListener(_handleAdPolicyChange);
    _syncAdState();
  }

  @override
  void didUpdateWidget(covariant AdBannerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible ||
        oldWidget.usesTopSafeArea != widget.usesTopSafeArea ||
        oldWidget.usesBottomSafeArea != widget.usesBottomSafeArea ||
        oldWidget.placement != widget.placement) {
      _syncAdState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAdState();
    }
  }

  void _handleAdPolicyChange() {
    _syncAdState();
  }

  Future<void> _syncAdState() async {
    if (!_canShowAds) {
      _disposeBanner(notify: true);
      return;
    }

    if (_bannerAd == null && !_isLoading) {
      await _loadBannerAd();
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBannerAd() async {
    if (!_canShowAds || _isLoading) {
      return;
    }

    _isLoading = true;
    try {
      await AdRuntime.instance.initialize();
    } catch (_) {
      developer.log(
        'BannerAd request skipped: MobileAds initialization threw',
        name: 'TurboChessAds',
      );
      _isLoading = false;
      _isLoaded = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (!_canShowAds || !mounted) {
      _isLoading = false;
      return;
    }

    developer.log('BannerAd request started', name: 'TurboChessAds');
    final ad = AdRuntime.instance.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted || _bannerAd != loadedAd) {
            loadedAd.dispose();
            return;
          }
          developer.log('BannerAd loaded', name: 'TurboChessAds');
          _isLoading = false;
          _isLoaded = true;
          setState(() {});
        },
        onAdFailedToLoad: (failedAd, error) {
          developer.log(
            'BannerAd failed to load: code=${error.code}, '
            'domain=${error.domain}, message=${error.message}',
            name: 'TurboChessAds',
          );
          if (_bannerAd == failedAd) {
            _bannerAd = null;
          }
          _isLoading = false;
          _isLoaded = false;
          failedAd.dispose();
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );

    _bannerAd = ad;
    _isLoaded = false;
    try {
      await ad.load();
    } catch (_) {
      developer.log('BannerAd load threw before callback',
          name: 'TurboChessAds');
      if (_bannerAd == ad) {
        _bannerAd = null;
      }
      _isLoading = false;
      _isLoaded = false;
      ad.dispose();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _disposeBanner({bool notify = false}) {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    AdFreeService.instance.removeListener(_handleAdPolicyChange);
    WidgetsBinding.instance.removeObserver(this);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox.shrink();

    if (_canShowAds && _isLoaded && _bannerAd != null) {
      child = Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          widget.placement == AdBannerPlacement.top ? 8 : 4,
          8,
          widget.placement == AdBannerPlacement.bottom ? 8 : 4,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignSystem.backgroundSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DesignSystem.border),
            boxShadow: DesignSystem.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
        ),
      );

      if (widget.placement == AdBannerPlacement.bottom &&
          widget.usesBottomSafeArea) {
        child = SafeArea(top: false, child: child);
      }
      if (widget.placement == AdBannerPlacement.top && widget.usesTopSafeArea) {
        child = SafeArea(bottom: false, child: child);
      }
    }

    return AnimatedSize(
      duration: DesignSystem.durationNormal,
      curve: Curves.easeOutCubic,
      alignment: widget.placement == AdBannerPlacement.top
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      child: child,
    );
  }
}
