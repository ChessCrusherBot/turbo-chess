import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/ads/ad_shell.dart';

void main() {
  test('no entitlement means banners can show when ads are enabled', () {
    expect(
      AdBannerPolicy.shouldShowBanners(
        screenVisible: true,
        adsRuntimeEnabled: true,
        isAdFree: false,
      ),
      isTrue,
    );
  });

  test('ad-free entitlement hides top and bottom banner slots', () {
    final topBannerVisible = AdBannerPolicy.shouldShowBanners(
      screenVisible: true,
      adsRuntimeEnabled: true,
      isAdFree: true,
    );
    final bottomBannerVisible = AdBannerPolicy.shouldShowBanners(
      screenVisible: true,
      adsRuntimeEnabled: true,
      isAdFree: true,
    );

    expect(topBannerVisible, isFalse);
    expect(bottomBannerVisible, isFalse);
  });
}
