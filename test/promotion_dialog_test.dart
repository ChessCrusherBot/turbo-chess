import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_chess/core/chess/chess_board.dart';
import 'package:turbo_chess/core/ui/promotion_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('white promotion dialog shows all premium SVG choices', (
    tester,
  ) async {
    await _setSurface(tester, const Size(360, 640));
    await _pumpPromotionButton(tester, PieceColor.white);

    await tester.tap(find.text('Open promotion'));
    await tester.pumpAndSettle();

    expect(find.text('Promote pawn'), findsOneWidget);
    expect(find.text('Choose a piece'), findsOneWidget);
    expect(find.text('Queen'), findsOneWidget);
    expect(find.text('Rook'), findsOneWidget);
    expect(find.text('Bishop'), findsOneWidget);
    expect(find.text('Knight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('black promotion dialog uses high-contrast choices', (
    tester,
  ) async {
    await _setSurface(tester, const Size(360, 640));
    await _pumpPromotionButton(tester, PieceColor.black);

    await tester.tap(find.text('Open promotion'));
    await tester.pumpAndSettle();

    expect(find.text('Promote pawn'), findsOneWidget);
    expect(find.text('Choose a piece'), findsOneWidget);
    expect(find.byKey(const ValueKey('promotion_black_q')), findsOneWidget);
    expect(find.byKey(const ValueKey('promotion_black_r')), findsOneWidget);
    expect(find.byKey(const ValueKey('promotion_black_b')), findsOneWidget);
    expect(find.byKey(const ValueKey('promotion_black_n')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('promotion dialog stays compact on a small phone', (
    tester,
  ) async {
    await _setSurface(tester, const Size(320, 480));
    await _pumpPromotionButton(tester, PieceColor.white);

    await tester.tap(find.text('Open promotion'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(
      find.byKey(const ValueKey('promotion_dialog_card')),
    );
    expect(dialogRect.width, lessThanOrEqualTo(330));
    expect(dialogRect.height, lessThan(300));
    expect(find.text('Queen'), findsOneWidget);
    expect(find.text('Rook'), findsOneWidget);
    expect(find.text('Bishop'), findsOneWidget);
    expect(find.text('Knight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting each promotion option returns the right code', (
    tester,
  ) async {
    for (final entry in const {
      'q': 'Queen',
      'r': 'Rook',
      'b': 'Bishop',
      'n': 'Knight'
    }.entries) {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await PromotionDialog.show(
                  context,
                  PieceColor.black,
                );
              },
              child: const Text('Open promotion'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open promotion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value));
      await tester.pumpAndSettle();

      expect(selected, entry.key);
    }
  });

  testWidgets('promotion dialog cancel returns null', (tester) async {
    String? selected = 'pending';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selected = await PromotionDialog.show(
                context,
                PieceColor.white,
              );
            },
            child: const Text('Open promotion'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open promotion'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('promotion_cancel')));
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });
}

Future<void> _pumpPromotionButton(
  WidgetTester tester,
  PieceColor color,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => PromotionDialog.show(context, color),
          child: const Text('Open promotion'),
        ),
      ),
    ),
  );
}

Future<void> _setSurface(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
