import 'package:fostifest_companion/break_even_page.dart';
import 'package:fostifest_companion/cashflow_page.dart';
import 'package:fostifest_companion/debt_page.dart';
import 'package:fostifest_companion/guide_page.dart';
import 'package:fostifest_companion/inventory_page.dart';
import 'package:fostifest_companion/legal_page.dart';
import 'package:fostifest_companion/report_pdf.dart';
import 'package:fostifest_companion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const FostifestApp());
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Masuk ke akun demo LARAS UMKM'));
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
    expect(card.top - search.bottom, 16);
    expect(card.left, greaterThanOrEqualTo(16));
    expect(card.right, lessThanOrEqualTo(374));
  });

  testWidgets('pencarian fitur membuka layar pengeluaran', (tester) async {
    await enterDemo(tester);
    await tester.enterText(
        find.byKey(const Key('feature_search')), 'pengeluaran');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feature_search_results')), findsOneWidget);
    await tester.tap(find.text('Pengeluaran').first);
    await tester.pumpAndSettle();
    expect(find.text('Keuangan'), findsWidgets);
    expect(find.text('Catat pemasukan'), findsOneWidget);
  });

  testWidgets('pencarian tidak dikenal menunjukkan keadaan kosong',
      (tester) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'xyzfitur');
    await tester.pumpAndSettle();
    expect(find.text('Fitur tidak ditemukan. Coba kata lain.'), findsOneWidget);
  });

  testWidgets('pencarian KUR tidak menawarkan fitur yang dihapus',
      (tester) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'KUR');
    await tester.pumpAndSettle();
    expect(find.text('Fitur tidak ditemukan. Coba kata lain.'), findsOneWidget);
  });

  testWidgets('tombol hijau memiliki teks putih', (tester) async {
    await enterDemo(tester);
    await tester.scrollUntilVisible(find.text('Catat transaksi sekarang'), 100,
        scrollable: find.byType(Scrollable).first);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Catat transaksi sekarang'));
    expect(button.style!.foregroundColor!.resolve({}), Colors.white);
  });

  testWidgets('pencarian laporan membuka tab laporan', (tester) async {
    await enterDemo(tester);
    await tester.enterText(find.byKey(const Key('feature_search')), 'laporan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laporan keuangan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance_report_page')), findsOneWidget);
  });

  testWidgets('tab tengah bernama Manage Cerdas dan menampilkan ikon fitur',
      (tester) async {
    await enterDemo(tester);
    expect(find.text('Catat Cerdas'), findsNothing);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('manage_cerdas_page')), findsOneWidget);
    for (final key in ['keuangan', 'pelanggan', 'produk', 'margin']) {
      await tester.scrollUntilVisible(find.byKey(Key('manage_$key')), 200,
          scrollable: find.byType(Scrollable).first);
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
    await tester.scrollUntilVisible(find.byKey(const Key('manage_margin')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_margin')));
    await tester.pumpAndSettle();
    expect(find.text('Harga & margin produk'), findsOneWidget);
  });

  testWidgets('legalitas: status tersimpan dan progres bertambah',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('manage_legalitas')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_legalitas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legalitas_page')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    await tester.tap(find.text('NIB (Nomor Induk Berusaha)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('legal_nib_sudah')));
    await tester.pumpAndSettle();
    final raw =
        (await SharedPreferences.getInstance()).getString('laras_legal_v1');
    expect(raw, contains('"nib":{"s":"sudah"'));
    expect(find.text('0%'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('manage_legalitas')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_legalitas')));
    await tester.pumpAndSettle();
    expect(
        find.text('0%'), findsNothing); // status bertahan setelah dibuka lagi
  });

  test('legalitas: progres, pengingat masa berlaku, dan data lengkap', () {
    final now = DateTime(2026, 11, 14);
    final total = allLegalDocs.length;
    expect(total, greaterThanOrEqualTo(15));
    expect(legalProgress({}).done, 0);
    expect(legalProgress({}).total, total);
    final st = {
      'nib': LegalEntry(status: LegalStatus.sudah),
      'halal': LegalEntry(status: LegalStatus.tidakPerlu),
      'pirt': LegalEntry(status: LegalStatus.tidakPerlu),
    };
    final p = legalProgress(st);
    expect(p.done, 1);
    expect(p.total, total - 2); // "tidak perlu" tidak dihitung
    final e =
        LegalEntry(status: LegalStatus.sudah, expiry: DateTime(2026, 12, 4));
    expect(legalDaysLeft(e, now), 20);
    expect(legalDaysLeft(LegalEntry(), now), isNull);
    expect(
        legalDaysLeft(
            LegalEntry(
                status: LegalStatus.sudah, expiry: DateTime(2026, 11, 1)),
            now),
        lessThan(0));
    for (final d in allLegalDocs) {
      expect(d.steps, isNotEmpty);
      expect(d.what, isNotEmpty);
      expect(d.where, isNotEmpty);
    }
    expect(allLegalDocs.map((d) => d.id).toSet().length, total);
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
    expect(find.text('Daftar akun LARAS UMKM'), findsOneWidget);

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

    expect(find.byKey(const Key('feature_search')), findsOneWidget);
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
    expect(find.byKey(const Key('feature_search')), findsOneWidget);
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

  testWidgets('tombol LARAS membuka halaman chat', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Asisten usaha LARAS UMKM'), findsOneWidget);
    expect(find.text('Tanya Laras...'), findsOneWidget);
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
    expect(find.text('LARAS'), findsWidgets);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('business_name'), 'Batik Melati');
  });

  testWidgets('panduan dan privasi usaha dapat dibuka dari profil',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Produk dan stok'), findsNothing);

    await tester.scrollUntilVisible(find.text('Panduan LARAS UMKM'), 180);
    await tester.tap(find.text('Panduan LARAS UMKM'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai mengelola usaha'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Privasi dan data usaha'), 180);
    await tester.tap(find.text('Privasi dan data usaha'));
    await tester.pumpAndSettle();
    expect(find.text('Data usaha tetap milikmu'), findsOneWidget);
  });

  test('AI insight: rekomendasi sesuai data', () {
    final now = DateTime(2026, 11, 13);
    TransactionItem t(String n, int a, int daysAgo) => TransactionItem(
        name: n,
        amount: a,
        date: now.subtract(Duration(days: daysAgo)),
        source: 'Input manual');
    final empty = buildAiInsights(
        items: [], monthlyRevenue: 0, monthlyProfit: 0, now: now);
    expect(empty.first.$2, 'Mulai catat penjualan');
    final drop = buildAiInsights(
        items: [t('A', 1000000, 20), t('B', 200000, 3)],
        monthlyRevenue: 1200000,
        monthlyProfit: 100000,
        now: now);
    expect(drop.map((e) => e.$2), contains('Omzet 2 minggu terakhir turun'));
    expect(drop.map((e) => e.$2), contains('Margin laba masih tipis'));
    expect(drop.length, lessThanOrEqualTo(5));
  });

  test('Cashflow: analisis masuk, keluar, tipe, dan dampak harga bahan', () {
    final now = DateTime(2026, 11, 13);
    String ago(int d) => now.subtract(Duration(days: d)).toIso8601String();
    final a = analyzeCashflow(
      income: [
        {'amount': 1000000, 'category': 'Penjualan', 'date': ago(2)},
        {'amount': 500000, 'category': 'Modal pemilik', 'date': ago(5)},
        {'amount': 800000, 'category': 'Penjualan', 'date': ago(40)},
      ],
      expenses: [
        {
          'name': 'Beli Kain mori (X)',
          'amount': 540000,
          'category': 'Bahan baku',
          'createdAt': ago(3)
        },
        {
          'name': 'Mesin jahit',
          'amount': 300000,
          'category': 'Peralatan',
          'createdAt': ago(4)
        },
      ],
      materials: [
        {
          'name': 'Kain mori',
          'priceHistory': [
            {'price': 100, 'at': ago(60)},
            {'price': 108, 'at': ago(10)}
          ]
        },
      ],
      range: DateTimeRange(
          start: now.subtract(const Duration(days: 29)), end: now),
    );
    expect(a.inflow, 1500000);
    expect(a.outflow, 840000);
    expect(a.net, 660000);
    expect(a.byType['Pendanaan'], 500000);
    expect(a.byType['Investasi'], -300000);
    expect(a.impacts.single.extra, 40000); // 540000 * .08 / 1.08
    expect(a.bahanBaku, 540000);
  });

  testWidgets('kotak Manajemen Cashflow membuka halaman cashflow',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('manage_cashflow')), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_cashflow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashflow_page')), findsOneWidget);
    expect(find.text('Ringkasan arus kas'), findsOneWidget);
  });

  test('Utang & Piutang: sisa, status, dan ringkasan', () {
    final now = DateTime(2026, 11, 14);
    Map<String, dynamic> d(String kind, int amt, int paid, int dueIn) => {
          'kind': kind,
          'amount': amt,
          'paid': paid,
          'due': now.add(Duration(days: dueIn)).toIso8601String()
        };
    expect(debtRemaining(d('piutang', 1000, 400, 5)), 600);
    expect(debtStatus(d('piutang', 1000, 1000, 5), now), DebtStatus.lunas);
    expect(debtStatus(d('piutang', 1000, 0, -1), now), DebtStatus.terlambat);
    expect(debtStatus(d('utang', 1000, 0, 2), now), DebtStatus.segera);
    expect(debtStatus(d('utang', 1000, 0, 9), now), DebtStatus.berjalan);
    final s = DebtSummary([
      d('piutang', 1000, 400, -2),
      d('piutang', 500, 500, 3),
      d('utang', 700, 0, 9),
    ], now);
    expect(s.piutang, 600);
    expect(s.piutangLate, 600);
    expect(s.utang, 700);
    expect(s.net, -100);
  });

  testWidgets('Utang & Piutang: terima pembayaran tercatat sebagai uang masuk',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_utang')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debt_page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('debt_pay_debt-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debt_pay_confirm')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect('${prefs.getString('laras_transactions_v1')}',
        contains('Pelunasan piutang Dinda Maharani'));
    expect('${prefs.getString('laras_debts_v1')}', contains('"paid":850000'));
  });

  test('Titik impas dan dana cadangan dihitung dari biaya tetap & variabel',
      () {
    final now = DateTime(2026, 11, 14);
    String ago(int d) => now.subtract(Duration(days: d)).toIso8601String();
    final a = analyzeCashflow(
      income: [
        {'amount': 1000000, 'category': 'Penjualan', 'date': ago(2)}
      ],
      expenses: [
        {
          'name': 'Beli bahan',
          'amount': 400000,
          'category': 'Bahan baku',
          'createdAt': ago(3)
        },
        {
          'name': 'Upah pengrajin',
          'amount': 200000,
          'category': 'Tenaga kerja',
          'createdAt': ago(4)
        },
      ],
      materials: const [],
      range: DateTimeRange(
          start: now.subtract(const Duration(days: 29)), end: now),
    );
    final b = computeBep(a, targetProfit: 100000);
    expect(b.fixedMonthly.round(), 200000);
    expect(b.contribution, closeTo(0.6, 1e-9));
    expect(b.bep.round(), 333333);
    expect(b.targetRevenue.round(), 500000);
    expect(b.safetyMargin, closeTo(0.6667, 1e-3));
    final r = ReserveResult(
        cash: 600000, months: 3, fixedMonthly: 200000, outflowMonthly: 600000);
    expect(r.target, 600000);
    expect(r.gap, 0);
    expect(r.runwayMinimalDays!.round(), 90);
    expect(r.runwayNormalDays!.round(), 30);
    // Biaya variabel >= omzet: tidak mungkin impas.
    expect(
        BepResult(
                fixedMonthly: 1,
                revenueMonthly: 10,
                variableRatio: 1.2,
                targetProfit: 0)
            .feasible,
        isFalse);
  });

  testWidgets('Titik Impas & Dana Cadangan dapat dibuka dan saldo tersimpan',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_impas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bep_page')), findsOneWidget);
    expect(find.byKey(const Key('bep_value')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('reserve_edit')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('reserve_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('reserve_cash_field')), '5000000');
    await tester.tap(find.byKey(const Key('reserve_cash_save')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 5.000.000'), findsWidgets);
    expect(
        '${(await SharedPreferences.getInstance()).getString('laras_reserve_v1')}',
        contains('5000000'));
  });

  test('Panduan: semua fitur Manage Cerdas dan istilah kunci terdaftar', () {
    final names = [
      for (final s in guideSections) ...s.features.map((f) => f.name)
    ];
    for (final n in [
      'Manajemen Cashflow',
      'Utang & Piutang',
      'Titik Impas & Dana Cadangan',
      'Harga & Margin',
      'AI Insight'
    ]) {
      expect(names, contains(n));
    }
    final terms = guideTerms.map((t) => t.term).join('|');
    for (final t in [
      'Piutang',
      'Utang',
      'Arus kas',
      'Titik impas',
      'Dana cadangan'
    ]) {
      expect(terms, contains(t));
    }
    for (final f in [for (final s in guideSections) ...s.features]) {
      expect(f.what, isNotEmpty);
      expect(f.why, isNotEmpty);
    }
  });

  testWidgets('Panduan: tab Istilah bisa dicari', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LarasGuidePage()));
    expect(find.text('Mulai mengelola usaha'), findsOneWidget);
    await tester.tap(find.text('Istilah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('guide_search')), 'piutang');
    await tester.pumpAndSettle();
    expect(find.text('Piutang'), findsOneWidget);
    expect(find.text('Rugi'), findsNothing);
  });

  test('Produk & Stok: level stok dan margin', () {
    expect(stockLevel({'stock': 0, 'min': 3}), StockLevel.habis);
    expect(stockLevel({'stock': 3, 'min': 3}), StockLevel.menipis);
    expect(stockLevel({'stock': 4, 'min': 3}), StockLevel.aman);
    expect(productMargin({'price': 200, 'cost': 150}), 25);
    expect(productMargin({'price': 0, 'cost': 10}), 0);
  });

  testWidgets('Produk & Stok: cari, filter menipis, ubah stok cepat',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({
      'laras_products_v1':
          '[{"name":"Kain Parang","sku":"A1","category":"Kain","price":100000,"cost":60000,"stock":2,"min":3,"recipe":[{"x":1}]},'
              '{"name":"Kemeja","sku":"B1","category":"Busana","price":200000,"cost":100000,"stock":10,"min":3}]'
    });
    await tester.pumpWidget(const MaterialApp(home: InventoryPage()));
    await tester.pumpAndSettle();
    expect(find.text('Kain Parang'), findsOneWidget);
    expect(find.text('Kemeja'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('inv_search')), 'kemeja');
    await tester.pumpAndSettle();
    expect(find.text('Kain Parang'), findsNothing);
    await tester.enterText(find.byKey(const Key('inv_search')), '');
    await tester.tap(find.text('Menipis'));
    await tester.pumpAndSettle();
    expect(find.text('Kemeja'), findsNothing);
    expect(find.text('Kain Parang'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inv_plus_0')));
    await tester.pumpAndSettle();
    final saved =
        (await SharedPreferences.getInstance()).getString('laras_products_v1')!;
    expect(saved, contains('"stock":3'));

    // Edit lewat formulir tidak boleh menghapus data resep.
    await tester.tap(find.byKey(const Key('inv_item_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inv_save')));
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance()).getString('laras_products_v1'),
        contains('"recipe"'));
  });

  testWidgets('Tempel Chat: baca, verifikasi, lalu simpan DP + piutang',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Catat transaksi sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_paste_step')), findsOneWidget);
    // tombol proses nonaktif sampai ada teks
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('chat_process')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const Key('chat_sample')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_process')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_verify_step')), findsOneWidget);
    expect(find.text('Rp 795.000'), findsWidgets); // 2 x 275rb + 245rb
    expect(find.byKey(const Key('chat_save')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat_save')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
        '${prefs.getString('laras_debts_v1')}', contains('"party":"Bu Ani"'));
    expect('${prefs.getString('laras_debts_v1')}', contains('"amount":795000'));
    expect(
        '${prefs.getString('laras_transactions_v1')}', contains('DP Bu Ani'));
    expect('${prefs.getString('laras_customers_v1')}', contains('Bu Ani'));
  });

  testWidgets('Tempel Chat: simpan ditahan bila harga belum terbaca',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await enterDemo(tester);
    await tester.tap(find.text('Catat transaksi sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('chat_input')), 'mau pesan 3 pashmina polos ya');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_process')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('chat_save')))
            .onPressed,
        isNull);
    expect(find.textContaining('Harga'), findsWidgets);
    await tester.enterText(find.byKey(const Key('chat_item_price_0')), '90000');
    await tester.pumpAndSettle();
    expect(find.text('Rp 270.000'), findsWidgets);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('chat_save')))
            .onPressed,
        isNotNull);
  });

  testWidgets('Utang & Piutang: tombol Isi data contoh mengisi daftar kosong',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: DebtPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debt_seed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('debt_seed')));
    await tester.pumpAndSettle();
    expect(find.text('Koperasi Seragam Sekolah'), findsOneWidget);
    final raw =
        (await SharedPreferences.getInstance()).getString('laras_debts_v1')!;
    expect(raw, contains('Toko Sutra Kotagede'));
    final all = sampleDebts(DateTime(2026, 11, 14));
    expect(all.where((d) => d['kind'] == 'piutang').length, 6);
    expect(all.where((d) => d['kind'] == 'utang').length, 5);
    final s = DebtSummary(all, DateTime(2026, 11, 14));
    expect(s.piutangLate, 850000 + 1800000);
    expect(s.utangLate, 650000);
  });

  test('Laporan PDF: angka, perbandingan, insight, dan dokumen terbentuk',
      () async {
    final now = DateTime(2026, 11, 14);
    String ago(int d) => now.subtract(Duration(days: d)).toIso8601String();
    final r = buildReportData(
      business: 'Batik Sekar',
      range: DateTimeRange(
          start: DateTime(2026, 1, 1), end: DateTime(2026, 12, 31)),
      income: [
        {
          'name': 'Penjualan katalog',
          'amount': 4850000,
          'category': 'Penjualan',
          'date': ago(2),
          'source': 'Input manual'
        },
        {
          'name': 'Pesanan seragam',
          'amount': 6200000,
          'category': 'Pesanan usaha',
          'date': ago(12),
          'source': 'Input manual'
        },
        {
          'name': 'Marketplace',
          'amount': 2100000,
          'category': 'Penjualan online',
          'date': ago(40),
          'source': 'Input manual'
        },
      ],
      expenses: [
        {
          'name': 'Beli kain',
          'amount': 3400000,
          'category': 'Bahan baku',
          'createdAt': ago(3)
        },
        {
          'name': 'Upah pengrajin',
          'amount': 2800000,
          'category': 'Tenaga kerja',
          'createdAt': ago(9)
        },
      ],
      cogs: 500000,
      debts: [
        {'kind': 'piutang', 'amount': 1000000, 'paid': 0, 'due': ago(5)},
        {
          'kind': 'utang',
          'amount': 500000,
          'paid': 0,
          'due': now.add(const Duration(days: 9)).toIso8601String()
        },
      ],
      now: now,
    );
    expect(r.revenue, 13150000);
    expect(r.operatingExpense, 6200000);
    expect(r.totalExpense, 6700000);
    expect(r.profit, 6450000);
    expect(r.tax, 65750);
    expect(r.months.length, 12); // Januari sampai Desember
    expect(r.incomeLines.length, 3);
    final titles = r.insights.map((i) => i.title).toList();
    for (final t in [
      'Kinerja usaha',
      'Sumber pendapatan',
      'Struktur biaya',
      'Arus kas',
      'Utang dan piutang',
      'Rekomendasi tindakan'
    ]) {
      expect(titles, contains(t));
    }
    expect(r.insights.length, greaterThanOrEqualTo(6));
    final bytes = await buildFinanceReportPdf(r).save();
    expect(bytes.length, greaterThan(5000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // Periode tanpa data tidak boleh error.
    final empty = buildReportData(
        business: 'X',
        range: DateTimeRange(
            start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        income: const [],
        expenses: const [],
        cogs: 0,
        debts: const [],
        now: now);
    expect(empty.insights.single.title, 'Belum ada data');
    expect((await buildFinanceReportPdf(empty).save()).isNotEmpty, isTrue);
  });
}
