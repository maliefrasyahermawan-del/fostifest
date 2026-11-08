import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fostifest_companion/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> enterDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const FostifestApp());
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Masuk ke akun demo LARAS UMKM'));
  await tester.pumpAndSettle();
}

Future<void> openSupplierTab(WidgetTester tester) async {
  await enterDemo(tester);
  await tester.tap(find.text('Supplier'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tab Supplier menggantikan Legalitas di navigasi bawah',
      (tester) async {
    await enterDemo(tester);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Legalitas'), findsNothing);
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supplier_page')), findsOneWidget);
    expect(find.text('Pedagang Mori Pasar Klewer'), findsOneWidget);
    expect(find.text('Toko Warna Batik Solo'), findsOneWidget);
  });

  testWidgets('detail supplier menampilkan bahan dan penanda termurah',
      (tester) async {
    await openSupplierTab(tester);
    await tester.tap(find.byKey(const Key('supplier_sup-cv')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supplier_detail')), findsOneWidget);
    expect(find.text('Termurah'), findsOneWidget);
  });

  testWidgets('supplier baru dapat ditambahkan', (tester) async {
    await openSupplierTab(tester);
    await tester.tap(find.byKey(const Key('add_supplier')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('supplier_name')), 'Toko Benang Sari');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Toko Benang Sari'), findsOneWidget);
  });

  testWidgets(
      'harga bahan naik memperbarui modal produk dan menampilkan dampak',
      (tester) async {
    await openSupplierTab(tester);
    await tester.tap(find.byKey(const Key('supplier_sup-klewer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('material_mat-mori-klewer')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('material_price')), '30000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('impact_dialog')), findsOneWidget);
    expect(find.textContaining('naik 7%'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final products = jsonDecode(prefs.getString('laras_products_v1')!) as List;
    final kawung = products.firstWhere((p) => p['sku'] == 'BCP-001') as Map;
    // 150.000 + 2,3 m x Rp2.000 kenaikan harga mori
    expect(kawung['cost'], 154600);
    final tulis = products.firstWhere((p) => p['sku'] == 'BTL-001') as Map;
    // resep batik tulis memakai 2,3 m mori yang sama
    expect(tulis['cost'], 524600);
    final sutra = products.firstWhere((p) => p['sku'] == 'SLD-001') as Map;
    expect(sutra['cost'], 95000); // tidak memakai mori
  });

  testWidgets('beli bahan mencatat pengeluaran', (tester) async {
    await openSupplierTab(tester);
    await tester.tap(find.byKey(const Key('supplier_sup-warna')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy_material')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('buy_qty')), '2');
    await tester.tap(find.text('Catat pengeluaran'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final expenses = jsonDecode(prefs.getString('laras_expenses_v1')!) as List;
    expect(expenses.first['category'], 'Bahan baku');
    expect(expenses.first['amount'], 90000);
  });

  testWidgets('resep produk menghitung modal otomatis dari bahan supplier',
      (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Manage Cerdas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_margin')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Batik Cap Kawung 2m'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Batik Cap Kawung 2m'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('open_recipe')), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('open_recipe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_page')), findsOneWidget);
    expect(find.text('Rp150.000'), findsWidgets);
    expect(tester.widget<Text>(find.byKey(const Key('recipe_total'))).data,
        'Rp150.000');
  });
}
