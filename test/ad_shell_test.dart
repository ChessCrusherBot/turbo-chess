import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/ads/ad_shell.dart';

void main() {
  testWidgets('screen frame returns child without ad UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdScreenFrame(
            isVisible: true,
            child: Text('Training board'),
          ),
        ),
      ),
    );

    expect(find.text('Training board'), findsOneWidget);
    expect(find.byType(AdBannerSlot), findsNothing);
  });

  testWidgets('legacy banner slot renders no visible content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdBannerSlot(placement: AdBannerPlacement.bottom),
        ),
      ),
    );

    expect(find.byType(AdBannerSlot), findsOneWidget);
    expect(find.byType(SizedBox), findsOneWidget);
    expect(tester.getSize(find.byType(SizedBox)), Size.zero);
  });

  test('banner policy never enables banners in version 1', () {
    expect(AdBannerPolicy.shouldShowBanners(screenVisible: true), isFalse);
    expect(AdBannerPolicy.shouldShowBanners(screenVisible: false), isFalse);
  });
}
