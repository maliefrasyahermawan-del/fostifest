import 'package:fostifest_companion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const FostifestApp());
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Masuk ke akun demo FOSTIFEST'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Masuk ke akun demo FOSTIFEST'));
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
    final greeting = tester.getRect(find.byKey(const Key('home_greeting')));
    final subtitle = tester.getRect(find.byKey(const Key('home_subtitle')));
    final card = tester.getRect(find.byKey(const Key('home_summary_card')));

    expect(brand.top, greaterThan(avatar.top - 6));
    expect(brand.bottom, lessThan(avatar.bottom));
    expect(greeting.top, greaterThan(avatar.bottom + 15));
    expect(subtitle.top, greaterThan(greeting.bottom));
    expect(card.top, greaterThanOrEqualTo(subtitle.bottom + 18));
    expect(card.top, lessThanOrEqualTo(subtitle.bottom + 34));
    expect(card.left, greaterThanOrEqualTo(16));
    expect(card.right, lessThanOrEqualTo(374));
  });

  testWidgets('ikon Catat Cerdas memiliki lencana uang berlatar hijau',
      (tester) async {
    await enterDemo(tester);
    final icon = find.byKey(const Key('smart_record_icon'));
    expect(icon, findsOneWidget);
    expect(
        find.descendant(of: icon, matching: find.text('\$')), findsOneWidget);

    final coin = tester.widget<Container>(
      find.descendant(of: icon, matching: find.byType(Container)).last,
    );
    final decoration = coin.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF0B5D3B));
  });

  testWidgets('Catat Cerdas membuka form transaksi manual yang lengkap',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catat Cerdas'));
    await tester.pumpAndSettle();

    expect(find.text('Catat transaksi'), findsOneWidget);
    expect(find.text('Tanggal'), findsOneWidget);
    expect(find.text('Nama produk atau keterangan'), findsOneWidget);
    expect(find.text('Total transaksi'), findsOneWidget);
  });

  testWidgets('Kelayakan menampilkan skor usaha dan simulasi KUR',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Kelayakan'));
    await tester.pumpAndSettle();

    expect(find.text('Kelayakan usaha'), findsOneWidget);
    expect(find.text('DARI 100'), findsOneWidget);

    await tester.tap(find.text('KUR'));
    await tester.pumpAndSettle();
    expect(find.text('SIMULASI PLAFON'), findsOneWidget);
  });

  testWidgets('Catatan keuangan membuka laporan bulanan dan PDF',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan keuangan'), findsOneWidget);
    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian pendapatan (penjualan)'), findsOneWidget);
    expect(find.text('Laba Rugi'), findsOneWidget);
  });

  testWidgets('akun baru tersimpan dan dapat digunakan untuk masuk',
      (tester) async {
    await tester.pumpWidget(const FostifestApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar akun FOSTIFEST'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('register_name')), 'Alif Pemilik Usaha');
    await tester.enterText(
        find.byKey(const Key('register_identifier')), 'alif@fostifest.id');
    await tester.enterText(
        find.byKey(const Key('register_password')), 'rahasia123');
    await tester.enterText(
        find.byKey(const Key('register_confirmation')), 'rahasia123');
    await tester.drag(find.byType(ListView).last, const Offset(0, -620));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Batik Sekar 👋'), findsOneWidget);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('account_identifier'), 'alif@fostifest.id');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const FostifestApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'contoh@usaha.id'), 'alif@fostifest.id');
    await tester.enterText(
        find.widgetWithText(TextField, 'Minimal 6 karakter'), 'rahasia123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Batik Sekar 👋'), findsOneWidget);
  });

  testWidgets('kalender catatan menampilkan transaksi per tanggal',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finance_calendar_page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_day_1')));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const Key('finance_calendar_page')), const Offset(0, -620));
    await tester.pumpAndSettle();
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    final now = DateTime.now();
    expect(
        find.text(
            'Catatan 01/${now.month.toString().padLeft(2, '0')}/${now.year}'),
        findsOneWidget);
  });

  testWidgets('tombol Fosti membuka halaman chat', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Fosti'));
    await tester.pumpAndSettle();

    expect(find.text('Asisten usaha FOSTIFEST'), findsOneWidget);
    expect(find.text('Tanya Fosti…'), findsOneWidget);
  });

  testWidgets('profil usaha dapat diedit dan muncul di beranda',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Edit profil usaha'), 200);
    await tester.tap(find.text('Edit profil usaha'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama usaha'), 'Batik Melati');
    await tester.ensureVisible(find.text('Simpan profil'));
    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();

    expect(find.text('Batik Melati'), findsWidgets);
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Batik Melati 👋'), findsOneWidget);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('business_name'), 'Batik Melati');
  });
}
