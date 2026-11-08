import 'package:flutter_test/flutter_test.dart';
import 'package:fostifest_companion/legalitas_page.dart';

void main() {
  test('klasifikasi batas modal dan omzet', () {
    expect(scaleFromCapital(1000000000), BusinessScale.micro);
    expect(scaleFromCapital(1000000001), BusinessScale.small);
    expect(scaleFromCapital(5000000001), BusinessScale.medium);
    expect(scaleFromRevenue(2000000000), BusinessScale.micro);
    expect(scaleFromRevenue(2000000001), BusinessScale.small);
    expect(scaleFromRevenue(15000000001), BusinessScale.medium);
    expect(scaleFromRevenue(50000000001), BusinessScale.outside);
  });

  test('tidak menebak izin saat informasi kurang', () {
    final rules = LegalRuleEngine.evaluate(
      sector: 'kuliner',
      product: '',
      kbli: '',
      scope: '',
      risk: LegalRisk.unknown,
      scale: BusinessScale.micro,
    );
    expect(rules.any((e) => e.id == 'risk_check'), isTrue);
    expect(rules.any((e) => e.id == 'standard' || e.id == 'permit'), isFalse);
  });

  test('rekomendasi mengikuti risiko dan sektor', () {
    final rules = LegalRuleEngine.evaluate(
      sector: 'kuliner',
      product: 'Sambal kemasan',
      kbli: '10772',
      scope: 'Produksi dan penjualan sambal kemasan',
      risk: LegalRisk.mediumHigh,
      scale: BusinessScale.micro,
    );
    expect(rules.any((e) => e.id == 'standard_verified'), isTrue);
    expect(rules.any((e) => e.id == 'halal'), isTrue);
    expect(rules.any((e) => e.id == 'food_permit'), isTrue);
  });

  test('usaha di luar batas UMKM tidak diarahkan ke skema UMK', () {
    final rules = LegalRuleEngine.evaluate(
      sector: 'kuliner',
      product: 'Makanan kemasan',
      kbli: '10799',
      scope: 'Produksi dan distribusi nasional',
      risk: LegalRisk.mediumHigh,
      scale: BusinessScale.outside,
    );
    final halal = rules.singleWhere((e) => e.id == 'halal');
    expect(halal.status, contains('di luar batas UMKM'));
    expect(halal.status, isNot(contains('self-declare')));
  });

  test('profil rusak diabaikan', () {
    expect(decodeLegalProfile('{json-rusak'), isNull);
    expect(decodeLegalProfile('[]'), isNull);
  });

  test('sektor lama dinormalisasi sebelum dipakai dropdown', () {
    final profile = decodeLegalProfile(
      '{"sector":"batik","product":"Kain","risk":"unknown"}',
    );
    expect(profile?['sector'], '');
    expect(profile?['product'], 'Kain');
  });
}
