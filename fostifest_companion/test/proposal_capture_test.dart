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
    const RepaintBoundary(key: boundaryKey, child: FostifestApp()),
  );
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

Future<void> enterDemo(WidgetTester tester) async {
  await openDemo(tester);
  await tester.ensureVisible(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
}

Future<void> saveGolden(WidgetTester tester, String path) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/images/hero-store.jpg'), context),
      precacheImage(
        const AssetImage('assets/images/batik-store-avatar.jpg'),
        context,
      ),
    ]);
  });
  await tester.pumpAndSettle();
  await expectLater(find.byKey(boundaryKey), matchesGoldenFile(path));
}

void main() {
  testWidgets('login proposal', (tester) async {
    await openDemo(tester);
    await saveGolden(tester, 'proposal/01-login.png');
  });

  testWidgets('supplier proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/06-supplier.png');
  });

  testWidgets('inventory proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Produk & Stok'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/08-produk.png');
  });

  testWidgets('dark dashboard and chat proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mode gelap'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode gelap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/09-beranda-gelap.png');
    await tester.tap(find.byTooltip('Laras'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/10-laras-gelap.png');
  });

  testWidgets('transaction form proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catat transaksi sekarang'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/11-form-transaksi.png');
  });

  testWidgets('chat transaction form proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catat transaksi sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/14-form-chat.png');
  });

  testWidgets('product dialog proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Produk & Stok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah produk'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/15-form-produk.png');
  });

  testWidgets('supplier dialog proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_supplier')));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/16-form-supplier.png');
  });

  testWidgets('legalitas proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('manage_legalitas')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_legalitas')));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/12-legalitas.png');
  });

  testWidgets('margin proposal', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_margin')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Batik Tulis Parang Rusak 2m'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batik Tulis Parang Rusak 2m'));
    await tester.pumpAndSettle();
    await saveGolden(tester, 'proposal/13-margin.png');
  });

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
