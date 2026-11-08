import 'package:fostifest_companion/main.dart';
import 'package:fostifest_companion/price_simulation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const FostifestApp());
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Masuk ke akun demo LARAS UMKM'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('header beranda rapi pada layar ponsel', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);

    final avatar = tester.getRect(find.byKey(const Key('home_avatar')));
    final brand = tester.getRect(find.byKey(const Key('home_brand')));
    final search = tester.getRect(find.byKey(const Key('feature_search')));
    final card = tester.getRect(find.byKey(const Key('home_summary_card')));

    expect(brand.top, greaterThan(avatar.top - 6));
    expect(brand.bottom, lessThan(avatar.bottom));
    expect(find.byKey(const Key('home_greeting')), findsNothing);
    expect(find.byKey(const Key('home_subtitle')), findsNothing);
    expect(search.top, greaterThanOrEqualTo(avatar.bottom));
    expect(card.top, greaterThan(search.bottom));
    final action = tester.getRect(find.text('Catat transaksi sekarang'));
    expect(card.bottom, lessThan(action.top));
    expect(card.left, greaterThanOrEqualTo(16));
    expect(card.right, lessThanOrEqualTo(374));
  });

  testWidgets('pencarian fitur membuka layar pengeluaran', (tester) async {
    await enterDemo(tester);
    await tester.enterText(
      find.byKey(const Key('feature_search')),
      'pengeluaran',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feature_search_results')), findsOneWidget);
    await tester.tap(find.text('Pengeluaran').first);
    await tester.pumpAndSettle();
    expect(find.text('Keuangan'), findsWidgets);
    expect(find.text('Catat pemasukan'), findsOneWidget);
  });

  testWidgets('pencarian tidak dikenal menunjukkan keadaan kosong', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'xyzfitur');
    await tester.pumpAndSettle();
    expect(find.text('Fitur tidak ditemukan. Coba kata lain.'), findsOneWidget);
  });

  testWidgets('pencarian KUR tidak menawarkan fitur yang dihapus', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'KUR');
    await tester.pumpAndSettle();
    expect(find.text('Fitur tidak ditemukan. Coba kata lain.'), findsOneWidget);
  });

  testWidgets('tombol hijau memiliki teks putih', (tester) async {
    await enterDemo(tester);
    await tester.scrollUntilVisible(
      find.text('Catat transaksi sekarang'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Catat transaksi sekarang'),
    );
    expect(button.style!.foregroundColor!.resolve({}), Colors.white);
    final buttonContext = tester.element(
      find.widgetWithText(FilledButton, 'Catat transaksi sekarang'),
    );
    final background = button.style!.backgroundColor?.resolve({}) ??
        FilledButtonTheme.of(buttonContext)
            .style!
            .backgroundColor!
            .resolve({})!;
    final contrast = (Colors.white.computeLuminance() + .05) /
        (background.computeLuminance() + .05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });

  for (final width in [360.0, 414.0]) {
    testWidgets('ringkasan usaha terbaca pada lebar $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await enterDemo(tester);
      final omzet = tester.getRect(find.text('OMZET BULAN INI'));
      final laba = tester.getRect(find.text('ESTIMASI LABA'));
      expect(omzet.left, greaterThanOrEqualTo(20));
      expect(laba.right, lessThanOrEqualTo(width - 20));
      final overview = tester.getRect(
        find.byKey(const Key('home_summary_card')),
      );
      expect(overview.contains(omzet.center), isTrue);
      expect(overview.contains(laba.center), isTrue);
      expect(laba.top, greaterThan(omzet.bottom));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Manage Cerdas'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('manage_keuangan')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nama supplier tetap terbaca dalam mode gelap', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode gelap'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.text('Supplier').last);
    await tester.pumpAndSettle();
    final name = find.text('Pedagang Mori Pasar Klewer');
    final foreground = tester.widget<Text>(name).style!.color!;
    final surface = Theme.of(tester.element(name)).colorScheme.surface;
    expect(Theme.of(tester.element(name)).brightness, Brightness.dark);
    final a = foreground.computeLuminance();
    final b = surface.computeLuminance();
    final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });

  testWidgets('pencarian laporan membuka tab laporan', (tester) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'laporan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laporan keuangan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance_report_page')), findsOneWidget);
  });

  testWidgets('tab tengah bernama Manage Cerdas dan menampilkan ikon fitur', (
    tester,
  ) async {
    await enterDemo(tester);
    expect(find.text('Catat Cerdas'), findsNothing);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('manage_cerdas_page')), findsOneWidget);
    for (final key in ['keuangan', 'pelanggan', 'produk', 'margin']) {
      expect(find.byKey(Key('manage_$key')), findsOneWidget);
    }
    expect(find.text('Pusat Operasi Usaha'), findsNothing);
    expect(find.text('Pembayaran'), findsNothing);
    expect(find.text('Kasir'), findsNothing);
  });

  testWidgets('Harga & Margin dapat dibuka dari Manage Cerdas', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage_margin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_margin')));
    await tester.pumpAndSettle();
    expect(find.text('Harga & margin produk'), findsOneWidget);
  });

  testWidgets('Simulasi Harga dapat dibuka dari Manage Cerdas', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('manage_simulasi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_simulasi')));
    await tester.pumpAndSettle();
    expect(find.byType(PriceSimulationPage), findsOneWidget);
  });

  testWidgets('legalitas tetap tersedia dari Manage Cerdas dan tersimpan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('manage_legalitas')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_legalitas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legalitas_page')), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool('legal_nib'),
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_legalitas')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
          .value,
      isTrue,
    );
  });

  testWidgets('Catatan keuangan membuka laporan bulanan dan PDF', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan keuangan'), findsOneWidget);
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian pendapatan (penjualan)'), findsOneWidget);
    expect(find.text('Laba Rugi'), findsOneWidget);
  });

  testWidgets('akun baru tersimpan dan dapat digunakan untuk masuk', (
    tester,
  ) async {
    await tester.pumpWidget(const FostifestApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar akun LARAS UMKM'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register_name')),
      'Alif Pemilik Usaha',
    );
    await tester.enterText(
      find.byKey(const Key('register_identifier')),
      'alif@fostifest.id',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'rahasia123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirmation')),
      'rahasia123',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -620));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feature_search')), findsOneWidget);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('account_identifier'), 'alif@fostifest.id');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const FostifestApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'contoh@usaha.id'),
      'alif@fostifest.id',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Minimal 6 karakter'),
      'rahasia123',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feature_search')), findsOneWidget);
  });

  testWidgets('kalender catatan menampilkan transaksi per tanggal', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finance_calendar_page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_day_1')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('finance_calendar_page')),
      const Offset(0, -620),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    final now = DateTime.now();
    expect(
      find.text(
        'Catatan 01/${now.month.toString().padLeft(2, '0')}/${now.year}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tombol Laras membuka halaman chat', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.byTooltip('Laras'));
    await tester.pumpAndSettle();

    expect(find.text('Asisten usaha LARAS UMKM'), findsOneWidget);
    expect(find.text('Tanya Laras...'), findsOneWidget);
  });

  testWidgets('profil usaha dapat diedit dan muncul di beranda', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Edit profil usaha'), 200);
    await tester.tap(find.text('Edit profil usaha'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama usaha'),
      'Batik Melati',
    );
    await tester.ensureVisible(find.text('Simpan profil'));
    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();

    expect(find.text('Batik Melati'), findsWidgets);
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('LARAS UMKM'), findsWidgets);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('business_name'), 'Batik Melati');
  });

  testWidgets('panduan dan privasi usaha dapat dibuka dari profil', (
    tester,
  ) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Produk dan stok'), findsNothing);

    await tester.scrollUntilVisible(find.text('Panduan LARAS UMKM'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panduan LARAS UMKM'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai mengelola usaha'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Privasi dan data usaha'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privasi dan data usaha'));
    await tester.pumpAndSettle();
    expect(find.text('Data usaha tetap milikmu'), findsOneWidget);
  });
}
