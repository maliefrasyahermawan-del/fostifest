import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fostifest_companion/price_simulation_page.dart';

void main() {
  test('menghitung laba, rugi, margin, omzet, dan impas', () {
    const profit = PriceSimulationResult(
      price: 50000,
      quantity: 10,
      materialCost: 15000,
      productionCost: 5000,
    );
    expect(profit.revenue, 500000);
    expect(profit.totalCost, 200000);
    expect(profit.profit, 300000);
    expect(profit.margin, 60);
    expect(profit.breakEvenPrice, 20000);
    const loss = PriceSimulationResult(
      price: 10000,
      quantity: 2,
      materialCost: 12000,
      productionCost: 3000,
    );
    expect(loss.profit, -10000);
    expect(loss.loss, 10000);
  });

  test('maksimal sepuluh, bisa diperbarui dan dihapus', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PriceSimulationStore();
    for (var i = 0; i < 10; i++) {
      await store.save({'id': '$i', 'name': 'Produk $i'});
    }
    expect((await store.read()).length, 10);
    await expectLater(store.save({'id': '11'}), throwsStateError);
    await store.save({'id': '0', 'name': 'Diperbarui'});
    expect(
      (await store.read()).singleWhere((e) => e['id'] == '0')['name'],
      'Diperbarui',
    );
    await store.delete('0');
    expect((await store.read()).length, 9);
  });
}
