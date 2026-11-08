import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fostifest_companion/laras_forms.dart';

import 'app_test.dart' show enterDemo;

void phone(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> fill(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> openProduct(WidgetTester tester) async {
  await enterDemo(tester);
  await tester.tap(find.text('Produk & Stok'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tambah produk'));
  await tester.pumpAndSettle();
}

Future<void> openSupplier(WidgetTester tester) async {
  await enterDemo(tester);
  await tester.tap(find.text('Supplier'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add_supplier')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('product form keeps validation and saves every existing field', (
    tester,
  ) async {
    phone(tester);
    await openProduct(tester);
    expect(
      tester.getSize(find.byKey(const Key('product_name'))).width,
      greaterThan(280),
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Isi nama produk'), findsOneWidget);
    for (final entry in {
      'product_name': 'Batik Melati Baru',
      'product_sku': 'NEW-001',
      'product_category': 'Kain batik',
      'product_price': '120000',
      'product_cost': '70000',
      'product_stock': '15',
      'product_min': '2',
    }.entries) {
      await fill(tester, entry.key, entry.value);
    }
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final products = jsonDecode(prefs.getString('laras_products_v1')!) as List;
    expect(products.last, {
      'name': 'Batik Melati Baru',
      'sku': 'NEW-001',
      'category': 'Kain batik',
      'price': 120000,
      'cost': 70000,
      'stock': 15,
      'min': 2,
    });
    expect(find.byType(LarasFormDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supplier fields keep complete labels and save contacts', (
    tester,
  ) async {
    phone(tester);
    await openSupplier(tester);
    expect(find.text('Nomor telepon / WhatsApp'), findsOneWidget);
    await fill(tester, 'supplier_name', 'Pemasok Melati');
    final fields = find.descendant(
      of: find.byType(LarasFormDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(1), '081234567890');
    await tester.ensureVisible(fields.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), 'Jalan Melati 10, Solo');
    await tester.ensureVisible(fields.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(3), 'Kain mori dan malam');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final suppliers =
        jsonDecode(prefs.getString('laras_suppliers_v1')!) as List;
    final saved = suppliers.first as Map;
    expect(saved['name'], 'Pemasok Melati');
    expect(saved['phone'], '081234567890');
    expect(saved['address'], 'Jalan Melati 10, Solo');
    expect(saved['note'], 'Kain mori dan malam');
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat form retains the transaction save behavior', (
    tester,
  ) async {
    phone(tester);
    await enterDemo(tester);
    await tester.tap(find.text('Catat transaksi sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Catat transaksi'), findsOneWidget);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await fill(tester, 'transaction_name', 'Penjualan Batik Melati');
    await fill(tester, 'transaction_amount', '480000');
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final transactions =
        jsonDecode(prefs.getString('laras_transactions_v1')!) as List;
    expect(transactions.first['name'], 'Penjualan Batik Melati');
    expect(transactions.first['amount'], 480000);
    expect(transactions.first['source'], 'Tempel chat');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'transaction form keeps save visible at scale $scale with keyboard',
      (tester) async {
        phone(tester, scale: scale);
        await enterDemo(tester);
        await tester.scrollUntilVisible(
          find.text('Catat transaksi sekarang'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Catat transaksi sekarang'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chat'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final save = find.widgetWithText(FilledButton, 'Simpan transaksi');
        final rect = tester.getRect(save);
        expect(rect.bottom, lessThanOrEqualTo(544));
        await tester.scrollUntilVisible(
          find.byKey(const Key('transaction_customer')),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(save), rect);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    (const Size(390, 844), 2.0, 0.0),
    (const Size(844, 390), 1.0, 0.0),
    (const Size(390, 844), 1.0, 300.0),
  ]) {
    for (final supplier in [false, true]) {
      testWidgets(
        '${supplier ? 'supplier' : 'product'} dialog adapts to ${scenario.$1} scale ${scenario.$2} keyboard ${scenario.$3}',
        (tester) async {
          phone(tester, size: scenario.$1, scale: scenario.$2);
          if (supplier) {
            await openSupplier(tester);
          } else {
            // At large text, the shortcut may start below the viewport.
            await enterDemo(tester);
            await tester.scrollUntilVisible(
              find.text('Produk & Stok'),
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Produk & Stok'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Tambah produk'));
            await tester.pumpAndSettle();
          }
          tester.view.viewInsets = FakeViewPadding(bottom: scenario.$3);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final save = find.widgetWithText(FilledButton, 'Simpan');
          final rect = tester.getRect(save);
          expect(
            rect.bottom,
            lessThanOrEqualTo(scenario.$1.height - scenario.$3),
          );
          await tester.drag(
            find.byKey(const Key('laras_form_scroll')),
            const Offset(0, -280),
          );
          await tester.pumpAndSettle();
          expect(tester.getRect(save), rect);
          await tester.tap(find.text('Batal'));
          await tester.pumpAndSettle();
          expect(find.byType(LarasFormDialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
