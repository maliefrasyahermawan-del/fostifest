import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _line(
  String id,
  String name,
  String unit,
  num qty,
  int price,
) =>
    {
      'materialId': id,
      'name': name,
      'unit': unit,
      'qty': qty,
      'unitPrice': price,
    };

/// Seed data lokal tanpa POS, piutang, QRIS, atau pembayaran digital.
Future<bool> seedBatikDemoData() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('laras_transactions_v1') != null ||
      prefs.getString('laras_products_v1') != null) {
    await _upgradeDemoData(prefs);
    return false;
  }
  final now = DateTime.now();
  final base = now.microsecondsSinceEpoch;
  Future<void> put(String key, Object value) async {
    if (!await prefs.setString(key, jsonEncode(value))) {
      throw StateError('Data contoh gagal disimpan.');
    }
  }

  await put('laras_products_v1', [
    {
      'name': 'Batik Tulis Parang Rusak 2m',
      'sku': 'BTL-001',
      'category': 'Kain batik',
      'price': 850000,
      'cost': 520000,
      'stock': 6,
      'min': 3,
    },
    {
      'name': 'Batik Cap Kawung 2m',
      'sku': 'BCP-001',
      'category': 'Kain batik',
      'price': 275000,
      'cost': 150000,
      'costMode': 'resep',
      'labor': 45000,
      'overhead': 10300,
      'recipe': [
        _line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.3, 28000),
        _line('mat-malam', 'Malam batik (lilin)', 'kg', 0.12, 65000),
        _line('mat-naptol', 'Pewarna naptol', 'botol', 0.5, 45000),
      ],
      'stock': 24,
      'min': 8,
    },
    {
      'name': 'Kemeja Batik Pria',
      'sku': 'KMJ-001',
      'category': 'Busana',
      'price': 245000,
      'cost': 130000,
      'costMode': 'resep',
      'labor': 40000,
      'overhead': 8900,
      'recipe': [
        _line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.2, 28000),
        _line('mat-benang', 'Benang & kancing', 'set', 1, 6000),
        _line('mat-naptol', 'Pewarna naptol', 'botol', 0.3, 45000),
      ],
      'stock': 22,
      'min': 8,
    },
    {
      'name': 'Dress Batik Wanita',
      'sku': 'DRS-001',
      'category': 'Busana',
      'price': 335000,
      'cost': 185000,
      'costMode': 'resep',
      'labor': 55000,
      'overhead': 11600,
      'recipe': [
        _line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.8, 28000),
        _line('mat-indigosol', 'Pewarna indigosol', 'botol', 0.4, 85000),
        _line('mat-benang', 'Benang & kancing', 'set', 1, 6000),
      ],
      'stock': 4,
      'min': 5,
    },
    {
      'name': 'Tas Tote Batik',
      'sku': 'AKS-002',
      'category': 'Aksesori',
      'price': 95000,
      'cost': 48000,
      'stock': 20,
      'min': 8,
    },
  ]);
  await put('laras_customers_v1', [
    {
      'id': '${base + 1}',
      'name': 'Ibu Retno Wulandari',
      'detail': '0812-2345-1101 · Pelanggan tetap',
      'createdAt': now.subtract(const Duration(days: 80)).toIso8601String(),
    },
    {
      'id': '${base + 2}',
      'name': 'CV Sinar Seragam',
      'detail': '0271-555-001 · Pelanggan instansi',
      'createdAt': now.subtract(const Duration(days: 55)).toIso8601String(),
    },
    {
      'id': '${base + 3}',
      'name': 'Dinda Maharani',
      'detail': '0857-7788-9903 · Pelanggan online',
      'createdAt': now.subtract(const Duration(days: 24)).toIso8601String(),
    },
  ]);
  await put('laras_transactions_v1', [
    {
      'id': '${base + 10}',
      'name': 'Penjualan katalog bulan ini',
      'amount': 4850000,
      'category': 'Penjualan',
      'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      'source': 'Input manual',
    },
    {
      'id': '${base + 11}',
      'name': 'Pesanan seragam batik',
      'amount': 6200000,
      'category': 'Pesanan usaha',
      'date': now.subtract(const Duration(days: 12)).toIso8601String(),
      'source': 'Input manual',
    },
    {
      'id': '${base + 12}',
      'name': 'Penjualan marketplace',
      'amount': 2100000,
      'category': 'Penjualan online',
      'date': now.subtract(const Duration(days: 19)).toIso8601String(),
      'source': 'Input manual',
    },
  ]);
  await put('laras_expenses_v1', [
    {
      'id': '${base + 20}',
      'name': 'Kain mori dan bahan baku',
      'detail': 'Belanja bahan produksi',
      'amount': 3400000,
      'category': 'Bahan baku',
      'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': '${base + 21}',
      'name': 'Upah pengrajin',
      'detail': 'Produksi mingguan',
      'amount': 2800000,
      'category': 'Tenaga kerja',
      'createdAt': now.subtract(const Duration(days: 9)).toIso8601String(),
    },
    {
      'id': '${base + 22}',
      'name': 'Kemasan dan label',
      'detail': 'Kebutuhan pengiriman',
      'amount': 650000,
      'category': 'Operasional',
      'createdAt': now.subtract(const Duration(days: 16)).toIso8601String(),
    },
  ]);
  await put('laras_cash_categories_v1', [
    {'id': 'income', 'name': 'Penjualan'},
    {'id': 'expense', 'name': 'Operasional'},
  ]);
  await put('laras_product_categories_v1', [
    {'id': 'fabric', 'name': 'Kain batik'},
    {'id': 'fashion', 'name': 'Busana'},
    {'id': 'accessory', 'name': 'Aksesori'},
  ]);
  await prefs.setString('business_name', 'Batik Sekar');
  await prefs.setString(
    'business_description',
    'Batik tulis, batik cap & busana khas Surakarta',
  );
  await prefs.setString('business_location', 'Laweyan, Surakarta, Jawa Tengah');
  await prefs.setString('business_category', 'Fashion & kerajinan');
  await _upgradeDemoData(prefs);
  return true;
}

/// Melengkapi data demo yang sudah ada: supplier, bahan baku, resep produk,
/// produk tambahan, dan pembelian bahan. Aman dijalankan berulang kali.
Future<void> _upgradeDemoData(SharedPreferences prefs) async {
  final now = DateTime.now();
  String ago(int days) => now.subtract(Duration(days: days)).toIso8601String();
  List<Map<String, dynamic>> read(String key) {
    try {
      return (jsonDecode(prefs.getString(key) ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> write(String key, Object value) async {
    if (!await prefs.setString(key, jsonEncode(value))) {
      throw StateError('Data contoh gagal disimpan.');
    }
  }

  final newSuppliers = prefs.getString('laras_suppliers_v1') == null;
  if (newSuppliers) {
    Map<String, dynamic> supplier(
      String id,
      String name,
      String phone,
      String address,
      String note,
      int days,
    ) =>
        {
          'id': id,
          'name': name,
          'phone': phone,
          'address': address,
          'note': note,
          'createdAt': ago(days),
        };
    await write('laras_suppliers_v1', [
      supplier(
        'sup-klewer',
        'Pedagang Mori Pasar Klewer',
        '0812-2000-1101',
        'Pasar Klewer, Surakarta',
        'Kain mori primissima dan katun',
        200,
      ),
      supplier(
        'sup-cv',
        'CV Tekstil Nusantara',
        '0271-555-0404',
        'Jl. Slamet Riyadi, Surakarta',
        'Kain mori, benang, dan kancing (grosir)',
        160,
      ),
      supplier(
        'sup-malam',
        'Toko Malam & Canting Laweyan',
        '0813-3000-2202',
        'Laweyan, Surakarta',
        'Malam batik, canting, dan soda abu',
        190,
      ),
      supplier(
        'sup-warna',
        'Toko Warna Batik Solo',
        '0857-4000-3303',
        'Kauman, Surakarta',
        'Pewarna naptol dan indigosol',
        180,
      ),
      supplier(
        'sup-sutra',
        'Toko Sutra Kotagede',
        '0813-5000-4404',
        'Kotagede, Yogyakarta',
        'Kain sutra untuk selendang',
        120,
      ),
      supplier(
        'sup-kemasan',
        'Toko Kemasan Pasar Gede',
        '0821-6000-5505',
        'Pasar Gede, Surakarta',
        'Box, plastik, dan label merek',
        100,
      ),
    ]);
    Map<String, dynamic> material(
      String id,
      String supplier,
      String name,
      String unit,
      int price, [
      int? before,
    ]) =>
        {
          'id': id,
          'supplierId': supplier,
          'name': name,
          'unit': unit,
          'pricePerUnit': price,
          'updatedAt': ago(12),
          'priceHistory': [
            if (before != null) {'price': before, 'at': ago(70)},
            {'price': price, 'at': ago(12)},
          ],
        };
    await write('laras_materials_v1', [
      material(
        'mat-mori-klewer',
        'sup-klewer',
        'Kain mori primissima',
        'meter',
        28000,
        26000,
      ),
      material(
        'mat-katun-klewer',
        'sup-klewer',
        'Kain katun halus',
        'meter',
        22000,
      ),
      material('mat-mori-cv', 'sup-cv', 'Kain mori primissima', 'meter', 26500),
      material('mat-benang', 'sup-cv', 'Benang & kancing', 'set', 6000),
      material(
        'mat-malam',
        'sup-malam',
        'Malam batik (lilin)',
        'kg',
        65000,
        62000,
      ),
      material(
        'mat-canting',
        'sup-malam',
        'Canting tulis tembaga',
        'pcs',
        18000,
      ),
      material('mat-soda', 'sup-malam', 'Soda abu (fiksasi)', 'kg', 14000),
      material('mat-naptol', 'sup-warna', 'Pewarna naptol', 'botol', 45000),
      material(
        'mat-indigosol',
        'sup-warna',
        'Pewarna indigosol',
        'botol',
        85000,
        80000,
      ),
      material('mat-sutra', 'sup-sutra', 'Kain sutra', 'meter', 60000, 58000),
      material(
        'mat-kemasan',
        'sup-kemasan',
        'Kemasan box & label',
        'pcs',
        3500,
      ),
      material(
        'mat-plastik',
        'sup-kemasan',
        'Plastik pembungkus',
        'pak',
        12000,
      ),
    ]);
    // Riwayat pembelian bahan di Keuangan.
    Map<String, dynamic> buy(int n, String name, int amount, int days) => {
          'id': 'buy-$n',
          'name': name,
          'amount': amount,
          'category': 'Bahan baku',
          'method': 'Tunai',
          'createdAt': ago(days),
          'source': 'Supplier',
        };
    await write('laras_expenses_v1', [
      buy(
        1,
        'Beli Kain mori primissima (Pedagang Mori Pasar Klewer)',
        1120000,
        11,
      ),
      buy(2, 'Beli Pewarna naptol (Toko Warna Batik Solo)', 540000, 13),
      buy(3, 'Beli Malam batik (Toko Malam & Canting Laweyan)', 650000, 16),
      buy(4, 'Beli Kain sutra (Toko Sutra Kotagede)', 900000, 22),
      buy(5, 'Beli Kemasan box & label (Toko Kemasan Pasar Gede)', 350000, 28),
      ...read('laras_expenses_v1'),
    ]);
  }

  Map<String, dynamic> line(
    String id,
    String name,
    String unit,
    num qty,
    int price,
  ) =>
      {
        'materialId': id,
        'name': name,
        'unit': unit,
        'qty': qty,
        'unitPrice': price,
      };
  Map<String, dynamic> recipe(
    int labor,
    int overhead,
    List<Map<String, dynamic>> lines,
  ) =>
      {
        'costMode': 'resep',
        'labor': labor,
        'overhead': overhead,
        'recipe': lines,
      };

  final recipes = <String, Map<String, dynamic>>{
    'BTL-001': recipe(195000, 41850, [
      line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.3, 28000),
      line('mat-malam', 'Malam batik (lilin)', 'kg', 0.55, 65000),
      line('mat-naptol', 'Pewarna naptol', 'botol', 1.8, 45000),
      line('mat-indigosol', 'Pewarna indigosol', 'botol', 1.2, 85000),
    ]),
    'AKS-002': recipe(11000, 3950, [
      line('mat-mori-klewer', 'Kain mori primissima', 'meter', 0.6, 28000),
      line('mat-naptol', 'Pewarna naptol', 'botol', 0.15, 45000),
      line('mat-benang', 'Benang & kancing', 'set', 1, 6000),
      line('mat-kemasan', 'Kemasan box & label', 'pcs', 1, 3500),
    ]),
    'BTL-002': recipe(210000, 39100, [
      line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.3, 28000),
      line('mat-malam', 'Malam batik (lilin)', 'kg', 0.6, 65000),
      line('mat-naptol', 'Pewarna naptol', 'botol', 2, 45000),
      line('mat-indigosol', 'Pewarna indigosol', 'botol', 1.5, 85000),
    ]),
    'BCP-002': recipe(42000, 10550, [
      line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.3, 28000),
      line('mat-malam', 'Malam batik (lilin)', 'kg', 0.12, 65000),
      line('mat-naptol', 'Pewarna naptol', 'botol', 0.45, 45000),
    ]),
    'OTR-001': recipe(50000, 12750, [
      line('mat-mori-klewer', 'Kain mori primissima', 'meter', 2.5, 28000),
      line('mat-indigosol', 'Pewarna indigosol', 'botol', 0.25, 85000),
      line('mat-benang', 'Benang & kancing', 'set', 1, 6000),
    ]),
    'SLD-001': recipe(22000, 6500, [
      line('mat-sutra', 'Kain sutra', 'meter', 0.9, 60000),
      line('mat-naptol', 'Pewarna naptol', 'botol', 0.2, 45000),
      line('mat-kemasan', 'Kemasan box & label', 'pcs', 1, 3500),
    ]),
  };
  Map<String, dynamic> product(
    String name,
    String sku,
    String category,
    int price,
    int cost,
    int stock,
    int min,
  ) =>
      {
        'name': name,
        'sku': sku,
        'category': category,
        'price': price,
        'cost': cost,
        'stock': stock,
        'min': min,
      };
  final extra = [
    product(
      'Batik Tulis Sidomukti 2m',
      'BTL-002',
      'Kain batik',
      925000,
      570000,
      5,
      3,
    ),
    product(
      'Batik Cap Truntum 2m',
      'BCP-002',
      'Kain batik',
      265000,
      145000,
      18,
      8,
    ),
    product('Outer Batik Kimono', 'OTR-001', 'Busana', 295000, 160000, 9, 5),
    product(
      'Selendang Batik Sutra',
      'SLD-001',
      'Aksesori',
      185000,
      95000,
      14,
      5,
    ),
  ];
  final products = read('laras_products_v1');
  var changed = false;
  for (final e in extra) {
    if (!products.any((p) => p['sku'] == e['sku'])) {
      products.add(e);
      changed = true;
    }
  }
  for (var i = 0; i < products.length; i++) {
    final r = recipes[products[i]['sku']];
    if (r != null && (products[i]['recipe'] as List?)?.isNotEmpty != true) {
      products[i] = {...products[i], ...r};
      changed = true;
    }
  }
  if (changed) await write('laras_products_v1', products);
}
