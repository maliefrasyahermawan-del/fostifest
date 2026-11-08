import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fostifest_companion/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show enterDemo;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const scenarios = [
    (Size(360, 800), 1.0, false),
    (Size(375, 844), 1.0, false),
    (Size(844, 390), 1.0, false),
    (Size(768, 1024), 1.0, false),
    (Size(414, 896), 2.0, false),
    (Size(414, 896), 3.2, false),
    (Size(375, 844), 1.0, true),
  ];
  for (final scenario in scenarios) {
    testWidgets(
      'core screens adapt to ${scenario.$1}, text ${scenario.$2}, reduced motion ${scenario.$3}',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: scenario.$3);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });
        await enterDemo(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Manage Cerdas'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(const Key('manage_produk')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('manage_produk')));
        await tester.pumpAndSettle();
        expect(find.text('Produk dan stok'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(FostifestBottomBar),
            matching: find.text('Supplier'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('supplier_page')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
