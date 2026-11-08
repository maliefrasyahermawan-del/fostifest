import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fostifest_companion/laras_design.dart';
import 'package:fostifest_companion/laras_operations_page.dart';
import 'package:fostifest_companion/price_simulation.dart';
import 'package:fostifest_companion/price_simulation_page.dart';
import 'package:fostifest_companion/simulation_cost_page.dart';

import 'app_test.dart' show enterDemo;

final suppliers = <Map<String, dynamic>>[
  {'id': 's1', 'name': 'Supplier Mori'},
  {'id': 's2', 'name': 'Supplier Alternatif'},
];
final materials = <Map<String, dynamic>>[
  {
    'id': 'm1',
    'supplierId': 's1',
    'name': 'Kain mori',
    'unit': 'meter',
    'pricePerUnit': 28000,
  },
  {
    'id': 'm2',
    'supplierId': 's2',
    'name': 'Kain alternatif',
    'unit': 'meter',
    'pricePerUnit': 26500,
  },
];
final product = <String, dynamic>{
  'name': 'Batik Kawung',
  'sku': 'BK',
  'price': 275000,
  'cost': 150000,
  'costMode': 'resep',
  'labor': 45000,
  'overhead': 10300,
  'recipe': [
    {
      'materialId': 'm1',
      'name': 'Kain mori',
      'unit': 'meter',
      'qty': 2.3,
      'unitPrice': 28000,
    },
    {'name': 'Malam', 'unit': 'kg', 'qty': 0.12, 'unitPrice': 65000},
    {'name': 'Naptol', 'unit': 'botol', 'qty': 0.5, 'unitPrice': 45000},
  ],
};
SimulationCost cost() =>
    SimulationCost.fromProduct(product, materials, suppliers);
PriceSimulation scenario({
  String id = 'one',
  int price = 275000,
  int quantity = 10,
}) =>
    PriceSimulation(
      id: id,
      name: 'Batik Kawung',
      price: price,
      quantity: quantity,
      cost: cost(),
      savedAt: DateTime(2026, 11, 8),
    );

Future<void> seed() async {
  SharedPreferences.setMockInitialValues({
    LarasLocalRepository.products: jsonEncode([product]),
    'laras_materials_v1': jsonEncode(materials),
    'laras_suppliers_v1': jsonEncode(suppliers),
    LarasLocalRepository.income: '[{"id":"sale","amount":275000}]',
    LarasLocalRepository.stockMoves: '[{"id":"stock","qty":10}]',
  });
}

Future<void> mount(
  WidgetTester tester, {
  Widget? page,
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: LarasDesign.theme(dark: dark),
      home: page ?? PriceSimulationPage(initialProduct: product),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String value) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
  await tester.pumpAndSettle();
}

void main() {
  setUp(seed);
  test('decimal recipe, profit, loss, break-even and zero price', () {
    expect(cost().total, 150000);
    final s = scenario();
    expect(s.profitPerUnit, 125000);
    expect(s.totalProfit, 1250000);
    expect(s.margin, closeTo(45.4545, .001));
    expect(scenario(price: 100000).totalProfit, -500000);
    expect(scenario(price: 150000).margin, 0);
    expect(scenario(price: 0).margin, isNull);
    expect(scenario(price: 0).totalProfit, -1500000);
    expect(scenario(price: 10000000).price, 10000000);
    expect(() => scenario(price: 10000001), throwsArgumentError);
    expect(() => scenario(quantity: 0), throwsArgumentError);
    expect(
      () => SimulationMaterial(
        name: 'x',
        unit: 'kg',
        quantity: double.nan,
        unitPrice: 1,
      ),
      throwsArgumentError,
    );
  });
  test('manual product retains its full cost without recipe', () {
    final manual = SimulationCost.fromProduct({'cost': 89000}, [], []);
    expect(manual.total, 89000);
    expect(manual.materials.single.supplierId, isNull);
  });
  test(
    'saved cost is immutable and remains historical after supplier changes',
    () async {
      final repo = PriceSimulationRepository();
      final original = scenario();
      await repo.save(original);
      final changed =
          materials.map((m) => {...m, 'pricePerUnit': 25000}).toList();
      expect(
        SimulationCost.fromProduct(product, changed, suppliers).total,
        143100,
      );
      final restored = (await PriceSimulationRepository().read()).single;
      expect(restored.cost.total, 150000);
      expect(restored.cost.materials.first.supplierName, 'Supplier Mori');
      expect(() => restored.cost.materials.clear(), throwsUnsupportedError);
      expect(restored.toJson(), original.toJson());
    },
  );
  test(
      'concurrent saves respect ten-slot capacity across instances and deletion frees one',
      () async {
    final repo = PriceSimulationRepository();
    final attempts = await Future.wait(
      List.generate(12, (i) async {
        try {
          await PriceSimulationRepository().save(scenario(id: '$i'));
          return true;
        } on SimulationLimitException {
          return false;
        }
      }),
    );
    expect(attempts.where((v) => v).length, 10);
    expect((await repo.read()).length, 10);
    await repo.delete('0');
    await repo.save(scenario(id: 'new'));
    final values = await repo.read();
    expect(values.length, 10);
    expect(values.any((s) => s.id == '0'), isFalse);
    expect(values.first.id, 'new');
  });
  test('corrupt storage fails without replacing the original data', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PriceSimulationRepository.storageKey, '{broken');
    final repo = PriceSimulationRepository();
    await expectLater(repo.read(), throwsA(isA<SimulationReadException>()));
    await expectLater(
      repo.save(scenario()),
      throwsA(isA<SimulationReadException>()),
    );
    await expectLater(
      repo.delete('one'),
      throwsA(isA<SimulationReadException>()),
    );
    expect(prefs.getString(PriceSimulationRepository.storageKey), '{broken');
  });
  testWidgets(
    'exact input, draggable price and live profit/loss including validation',
    (tester) async {
      await mount(tester);
      expect(find.text('Rp125.000'), findsNWidgets(2));
      await fill(tester, 'simulation_quantity', '10');
      expect(find.text('Rp1.250.000'), findsOneWidget);
      await fill(tester, 'simulation_price', '100000');
      expect(find.text('Perkiraan Rugi per produk'), findsOneWidget);
      expect(find.text('Margin -50.0%'), findsOneWidget);
      await fill(tester, 'simulation_price', '150000');
      expect(find.text('Perkiraan Impas per produk'), findsOneWidget);
      await fill(tester, 'simulation_price', '0');
      expect(find.text('Margin —'), findsOneWidget);
      await fill(tester, 'simulation_price', '10000001');
      expect(find.text('Isi Rp0 sampai Rp10.000.000.'), findsOneWidget);
      expect(find.text('Perkiraan Rugi per produk'), findsNothing);
      final slider = find.byKey(const Key('simulation_slider'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.drag(slider, const Offset(150, 0));
      await tester.pumpAndSettle();
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('simulation_price')),
      );
      final price = int.parse(field.controller!.text);
      expect(price, inInclusiveRange(1, 10000000));
      expect(tester.widget<Slider>(slider).value.round(), price);
      await fill(tester, 'simulation_price', '275123');
      expect(tester.widget<Slider>(slider).value, 275123);
      await fill(tester, 'simulation_quantity', '0');
      await tapKey(tester, 'simulation_save');
      expect(await PriceSimulationRepository().read(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'supplier selection, decimal quantities and manual cost apply as a draft',
    (tester) async {
      await mount(tester);
      await tapKey(tester, 'simulation_edit_cost');
      await tapKey(tester, 'simulation_add_material');
      await tapKey(tester, 'simulation_source_supplier');
      await tapKey(tester, 'simulation_supplier');
      await tester.tap(find.text('Supplier Alternatif').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bahan supplier'));
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kain alternatif').last);
      await tester.pumpAndSettle();
      await fill(tester, 'simulation_material_quantity', '2,3');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('simulation_material_price')),
            )
            .controller!
            .text,
        '26500',
      );
      await tapKey(tester, 'simulation_apply_material');
      // Back discards the entire cost draft, including the newly added line.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Rp150.000 / produk'), findsOneWidget);
      await tapKey(tester, 'simulation_edit_cost');
      await tapKey(tester, 'simulation_add_material');
      await fill(tester, 'simulation_material_name', 'Kemasan percobaan');
      await fill(tester, 'simulation_material_quantity', '0,5');
      await fill(tester, 'simulation_material_price', '10000');
      await tapKey(tester, 'simulation_apply_material');
      await tapKey(tester, 'simulation_apply_cost');
      expect(find.text('Rp155.000 / produk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'save, reopen historical snapshot and delete leave all business data intact',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      await mount(tester);
      await fill(tester, 'simulation_quantity', '10');
      await tapKey(tester, 'simulation_save');
      expect((await PriceSimulationRepository().read()).length, 1);
      await fill(tester, 'simulation_price', '1');
      await tapKey(tester, 'simulation_saved');
      await tester.tap(find.text('Buka simulasi'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('simulation_price')))
            .controller!
            .text,
        '275000',
      );
      expect(find.text('Rp1.250.000'), findsOneWidget);
      await tapKey(tester, 'simulation_saved');
      await tester.tap(find.byTooltip('Hapus simulasi Batik Kawung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect((await PriceSimulationRepository().read()).length, 1);
      await tester.tap(find.byTooltip('Hapus simulasi Batik Kawung'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada simulasi tersimpan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Lihat simpanan · 0/10'), findsOneWidget);
      for (final key in before.keys) {
        expect(prefs.get(key), before[key], reason: 'Unchanged $key');
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'full storage disables saving until a saved simulation is deleted',
    (tester) async {
      for (var i = 0; i < 10; i++) {
        await PriceSimulationRepository().save(scenario(id: '$i'));
      }
      await mount(tester);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('simulation_save')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'simulation_saved');
      await tester.tap(find.byTooltip('Hapus simulasi Batik Kawung').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('simulation_save')))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets(
    'manual simulation available without inventory and discoverable in app search',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await mount(tester, page: const PriceSimulationPage());
      expect(find.text('Tentukan modalmu'), findsOneWidget);
      await tapKey(tester, 'simulation_saved');
      expect(find.text('Belum ada simulasi tersimpan'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await enterDemo(tester);
      await tester.enterText(
        find.byKey(const Key('feature_search')),
        'simulasi',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulasi harga produk'));
      await tester.pumpAndSettle();
      expect(find.byType(PriceSimulationPage), findsOneWidget);
    },
  );
  for (final config in [
    (const Size(360, 800), 1.0, false),
    (const Size(844, 390), 1.0, false),
    (const Size(414, 896), 2.0, false),
    (const Size(414, 896), 3.2, true),
  ]) {
    testWidgets(
      'simulation screens fit ${config.$1} text ${config.$2} dark ${config.$3}',
      (tester) async {
        await mount(tester, size: config.$1, scale: config.$2, dark: config.$3);
        expect(tester.takeException(), isNull);
        await tapKey(tester, 'simulation_edit_cost');
        expect(find.byType(SimulationCostPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapKey(tester, 'simulation_add_material');
        await fill(tester, 'simulation_material_name', 'Modal');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tapKey(tester, 'simulation_apply_material');
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tapKey(tester, 'simulation_saved');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
