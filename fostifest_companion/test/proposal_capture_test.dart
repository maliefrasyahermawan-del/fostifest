import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fostifest_companion/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const boundaryKey = Key('proposal_capture_boundary');

Future<void> openDemo(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    const RepaintBoundary(
      key: boundaryKey,
      child: FostifestApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

Future<void> enterDemo(WidgetTester tester) async {
  await openDemo(tester);
  await tester.ensureVisible(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.tap(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
}

Future<void> saveGolden(WidgetTester tester, String path) async {
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(path),
  );
}

void main() {
  testWidgets('dashboard proposal', (tester) async {
    await enterDemo(tester);
    await saveGolden(tester, 'proposal/02-dashboard.png');
  });

  testWidgets('smart record proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/03-catat-transaksi.png');
  });

  testWidgets('ledger proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/04-catatan-keuangan.png');
  });

  testWidgets('report proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/05-laporan.png');
  });

  testWidgets('profile proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/07-profil.png');
  });
}
