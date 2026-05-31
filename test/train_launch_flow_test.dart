import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_chess/core/positions/position_category.dart';
import 'package:turbo_chess/core/positions/position_fen_repository.dart';
import 'package:turbo_chess/features/train/presentation/position_grid_screen.dart';
import 'package:turbo_chess/features/train/presentation/train_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Train screen shows the three launch drill modules', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: TrainScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Opening Drills'), findsOneWidget);
    expect(find.text('Middlegame Drills'), findsOneWidget);
    expect(find.text('Endgame Drills'), findsOneWidget);
    expect(find.text('0 / 10,000 completed'), findsNWidgets(3));
    expect(find.textContaining('Game Review'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Streak'), findsNothing);
    expect(find.textContaining('Coins'), findsNothing);
  });

  testWidgets('Position grid shows current and locked free states', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = PositionFenRepository(
      bundle: _FakePositionAssetBundle({
        PositionCategory.opening.assetPath: [
          '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
          '8/8/4k3/8/3K4/4P3/8/8 w - - 0 1',
          '8/8/8/3k4/8/3K4/3P4/8 w - - 0 1',
        ].join('\n'),
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PositionGridScreen(
          category: PositionCategory.opening,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opening Drills'), findsWidgets);
    expect(find.text('Position'), findsNWidgets(3));
    expect(find.text('Current'), findsWidgets);
    expect(find.text('Locked'), findsNWidgets(2));
    expect(find.text('Fast navigation'), findsOneWidget);
    expect(find.textContaining('Beginner to Master'), findsNothing);
  });
}

class _FakePositionAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _FakePositionAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    final asset = assets[key];
    if (asset == null) {
      throw StateError('Missing fake asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(asset)));
  }
}
