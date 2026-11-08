import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_margin_page.dart';

class LarasLocalRepository {
  static const income = 'laras_transactions_v1';
  static const expenses = 'laras_expenses_v1';
  static const customers = 'laras_customers_v1';
  static const products = 'laras_products_v1';
  static const categories = 'laras_cash_categories_v1';
  static const productCategories = 'laras_product_categories_v1';
  static const stockMoves = 'laras_stock_movements_v1';
  static const notifications = 'laras_notifications_v1';

  Future<List<Map<String, dynamic>>> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString(key) ?? '[]') as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> write(String key, List<Map<String, dynamic>> values) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(values))) {
      throw StateError('Data belum tersimpan di perangkat.');
    }
    await prefs.setString(
        'laras_last_updated_at', DateTime.now().toIso8601String());
  }

  String id() => DateTime.now().microsecondsSinceEpoch.toString();
}

String larasRupiah(num value) {
  final raw = value.round().toString();
  final groups = <String>[];
  for (var i = raw.length; i > 0; i -= 3) {
    groups.insert(0, raw.substring(i >= 3 ? i - 3 : 0, i));
  }
  return 'Rp${groups.join('.')}';
}

class LarasOperationsPage extends StatefulWidget {
  const LarasOperationsPage({super.key, this.section = 'keuangan'});

  /// 'keuangan' | 'pelanggan' | 'margin'
  final String section;
  @override
  State<LarasOperationsPage> createState() => _LarasOperationsPageState();
}

class _LarasOperationsPageState extends State<LarasOperationsPage> {
  final _repo = LarasLocalRepository();
  bool _loading = true;
  String? _error;
  late List<List<Map<String, dynamic>>> _data;
  List<Map<String, dynamic>> _sales = [];
  static const _keys = [
    LarasLocalRepository.income,
    LarasLocalRepository.expenses,
    LarasLocalRepository.customers,
    LarasLocalRepository.products,
    LarasLocalRepository.categories,
    LarasLocalRepository.productCategories,
    LarasLocalRepository.stockMoves,
    LarasLocalRepository.notifications,
  ];

  List<Map<String, dynamic>> get _income => _data[0];
  List<Map<String, dynamic>> get _expenses => _data[1];
  List<Map<String, dynamic>> get _customers => _data[2];
  List<Map<String, dynamic>> get _products => _data[3];
  List<Map<String, dynamic>> get _categories => _data[4];
  List<Map<String, dynamic>> get _productCategories => _data[5];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final next = <List<Map<String, dynamic>>>[];
      for (final key in _keys) {
        next.add(await _repo.read(key));
      }
      var sales = <Map<String, dynamic>>[];
      try {
        sales = await _repo.read('laras_sales_v1');
      } catch (_) {}
      if (mounted)
        setState(() {
          _data = next;
          _sales = sales;
          _loading = false;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Data lokal belum dapat dibaca.';
        });
    }
  }

  Future<void> _save(int index, List<Map<String, dynamic>> value) async {
    try {
      await _repo.write(_keys[index], value);
      if (mounted) setState(() => _data[index] = value);
    } catch (_) {
      if (mounted) _toast('Perubahan belum tersimpan. Coba lagi.');
    }
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  int _sum(List<Map<String, dynamic>> list) =>
      list.fold(0, (a, b) => a + ((b['amount'] as num?)?.round() ?? 0));
  String _date(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null
        ? '-'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
              switch (widget.section) {
                'pelanggan' => 'Pelanggan',
                'margin' => 'Harga & Margin',
                _ => 'Keuangan',
              },
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _Retry(message: _error!, onRetry: _load)
                : switch (widget.section) {
                    'pelanggan' => _customersPage(),
                    'margin' => _margins(),
                    _ => _finance(),
                  },
      );

  Widget _finance() => _Page(
          title: 'Keuangan',
          subtitle:
              'Catat arus kas usaha secara manual. Metode pembayaran hanya menjadi catatan, bukan layanan pembayaran.',
          action: 'Catat pemasukan',
          onAction: () => _cashForm(true),
          children: [
            _metrics([
              [
                'Pemasukan',
                larasRupiah(_sum(_income)),
                Icons.south_west_rounded
              ],
              [
                'Pengeluaran',
                larasRupiah(_sum(_expenses)),
                Icons.north_east_rounded
              ]
            ]),
            _title('Riwayat transaksi'),
            ..._transactions(),
            _title('Kategori kas'),
            _chips(_categories, 4, 'Tambah kategori'),
          ]);
  List<Widget> _transactions() {
    final rows = [
      ..._income.map((e) => {...e, 'type': 'Pemasukan', 'when': e['date']}),
      ..._expenses
          .map((e) => {...e, 'type': 'Pengeluaran', 'when': e['createdAt']})
    ]..sort((a, b) => '${b['when']}'.compareTo('${a['when']}'));
    if (rows.isEmpty)
      return [
        const _Empty(
            'Belum ada transaksi. Mulai dari pemasukan atau pengeluaran pertama.')
      ];
    return rows
        .take(30)
        .map((e) => Card(
            child: ListTile(
                leading: Icon(
                    e['type'] == 'Pemasukan'
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: const Color(0xFF14935A)),
                title: Text('${e['name'] ?? 'Transaksi'}'),
                subtitle: Text(
                    '${e['type']} · ${_date('${e['when']}')} · ${e['category'] ?? 'Tanpa kategori'}'),
                trailing: Text(larasRupiah((e['amount'] as num?) ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w800)))))
        .toList();
  }

  Widget _customersPage() => _Page(
        title: 'Pelanggan',
        subtitle:
            'Simpan kontak dan catatan pelanggan tanpa fitur tagihan otomatis.',
        action: 'Tambah pelanggan',
        onAction: _customerForm,
        children: [
          if (_customers.isEmpty)
            const _Empty(
                'Belum ada pelanggan. Tambahkan kontak pelanggan pertama.'),
          ..._customers.map((e) => Card(
                  child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${e['name']}'),
                subtitle: Text('${e['detail'] ?? 'Tanpa kontak'}'),
                onTap: () => _customerForm(initial: e),
                trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Hapus pelanggan',
                    onPressed: () => _deleteCustomer(e)),
              ))),
        ],
      );

  List<ProductMargin> get _productMargins {
    final sold = <String, int>{};
    for (final sale in _sales) {
      for (final item in (sale['items'] as List?) ?? const []) {
        final name = '${item['name']}';
        sold[name] =
            (sold[name] ?? 0) + ((item['quantity'] as num?)?.round() ?? 0);
      }
    }
    return _products
        .map((p) => ProductMargin(p, sold['${p['name']}'] ?? 0))
        .toList()
      ..sort((a, b) => a.marginPercent.compareTo(b.marginPercent));
  }

  Widget _margins() {
    final list = _productMargins;
    if (list.isEmpty) {
      return const _Empty(
          'Belum ada produk. Tambahkan produk dan harga modalnya agar margin dapat dianalisis.');
    }
    final average =
        list.fold<double>(0, (s, e) => s + e.marginPercent) / list.length;
    final weak = list.where((e) => e.marginPercent < 30).length;
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const Text('Harga & margin produk',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                  'Margin = harga jual dikurangi harga modal. Pilih produk untuk melihat penyebab margin dan mengatur harga.',
                  style: TextStyle(color: Color(0xFF5F766C), height: 1.4)),
              const SizedBox(height: 14),
              _metrics([
                [
                  'Rata-rata margin',
                  '${average.toStringAsFixed(1)}%',
                  Icons.percent_rounded
                ],
                ['Produk dipantau', '${list.length}', Icons.category_outlined],
                [
                  'Margin tertinggi',
                  '${list.last.marginPercent.toStringAsFixed(0)}%',
                  Icons.trending_up_rounded
                ],
                ['Margin < 30%', '$weak produk', Icons.warning_amber_rounded],
              ]),
              _title('Margin per produk'),
              ...list.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductMarginPage(
                                  product: e.product,
                                  unitsSold: e.unitsSold,
                                  averageMargin: average)));
                      await _load();
                    },
                    title: Text(e.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        'Jual ${larasRupiah(e.price)} · Modal ${larasRupiah(e.cost)} · Margin ${larasRupiah(e.margin)}'),
                    trailing: MarginBadge(percent: e.marginPercent),
                  ))),
            ]));
  }

  Widget _title(String label) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)));
  Widget _action(String label, IconData icon, VoidCallback onTap) => SizedBox(
      width: 150,
      child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8))));
  Widget _metrics(List<List<Object>> entries) => GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.65,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: entries
          .map((e) => DecoratedBox(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1FB36F),
                        Color(0xFF45C98E),
                        Color(0xFFBFF0D6)
                      ],
                      stops: [
                        0,
                        .65,
                        1
                      ]),
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(e[2] as IconData,
                            color: const Color(0xFF123126), size: 20),
                        const SizedBox(height: 5),
                        Text(e[0] as String,
                            style: const TextStyle(
                                color: Color(0xFF123126), fontSize: 11)),
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(e[1] as String,
                                style: const TextStyle(
                                    color: Color(0xFF123126),
                                    fontWeight: FontWeight.w900)))
                      ]))))
          .toList());
  Widget _chips(List<Map<String, dynamic>> list, int index, String label) =>
      Wrap(spacing: 8, runSpacing: 6, children: [
        ...list.map((e) => InputChip(
            label: Text('${e['name']}'),
            onDeleted: () async {
              final next = [...list]..remove(e);
              await _save(index, next);
            })),
        ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: Text(label),
            onPressed: () => _categoryForm(index, label))
      ]);

  Future<void> _cashForm(bool income) async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final category =
        TextEditingController(text: income ? 'Penjualan' : 'Operasional');
    final form = GlobalKey<FormState>();
    final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(income ? 'Catat pemasukan' : 'Catat pengeluaran'),
                content: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                              labelText: 'Nama transaksi'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama transaksi wajib diisi'
                              : null),
                      TextFormField(
                          controller: amount,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Nominal (Rp)'),
                          validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                              ? 'Nominal harus lebih dari nol'
                              : null),
                      TextFormField(
                          controller: category,
                          decoration:
                              const InputDecoration(labelText: 'Kategori')),
                      const SizedBox(height: 8),
                      const Text(
                          'Metode pembayaran dicatat manual: tunai, transfer bank, atau e-wallet.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF5F766C)))
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate())
                          Navigator.pop(c, {
                            'id': _repo.id(),
                            'name': name.text.trim(),
                            'amount': int.parse(amount.text),
                            'category': category.text.trim(),
                            'method': 'Tunai',
                            'date': DateTime.now().toIso8601String(),
                            'createdAt': DateTime.now().toIso8601String(),
                            'source': 'Input manual'
                          });
                      },
                      child: const Text('Simpan'))
                ]));
    name.dispose();
    amount.dispose();
    category.dispose();
    if (r == null) return;
    await _save(income ? 0 : 1, [r, ..._data[income ? 0 : 1]]);
    if (mounted) _toast('Transaksi tersimpan.');
  }

  Future<void> _customerForm({Map<String, dynamic>? initial}) async {
    final name = TextEditingController(text: '${initial?['name'] ?? ''}');
    final detail = TextEditingController(text: '${initial?['detail'] ?? ''}');
    final form = GlobalKey<FormState>();
    final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(
                    initial == null ? 'Tambah pelanggan' : 'Ubah pelanggan'),
                content: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                              labelText: 'Nama pelanggan'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama wajib diisi'
                              : null),
                      TextFormField(
                          controller: detail,
                          decoration: const InputDecoration(
                              labelText: 'Telepon, alamat, atau catatan'))
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate())
                          Navigator.pop(c, {
                            'id': initial?['id'] ?? _repo.id(),
                            'name': name.text.trim(),
                            'detail': detail.text.trim(),
                            'createdAt': initial?['createdAt'] ??
                                DateTime.now().toIso8601String()
                          });
                      },
                      child: const Text('Simpan'))
                ]));
    name.dispose();
    detail.dispose();
    if (r == null) return;
    final next = [..._customers];
    final i = next.indexWhere((e) => e['id'] == r['id']);
    if (i < 0) {
      next.insert(0, r);
    } else {
      next[i] = r;
    }
    await _save(2, next);
  }

  Future<void> _deleteCustomer(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('Hapus ${item['name']}?'),
                content: const Text('Kontak ini akan dihapus dari perangkat.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Hapus'))
                ]));
    if (yes == true) {
      final next = [..._customers]..remove(item);
      await _save(2, next);
    }
  }

  Future<void> _categoryForm(int index, String label) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (x) => AlertDialog(
                title: Text(label),
                content: TextField(
                    controller: c,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nama kategori')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(x, c.text.trim()),
                      child: const Text('Tambah'))
                ]));
    c.dispose();
    if (name == null || name.isEmpty) return;
    await _save(index, [
      ..._data[index],
      {'id': _repo.id(), 'name': name}
    ]);
  }
}

class _Page extends StatelessWidget {
  const _Page(
      {required this.title,
      required this.subtitle,
      required this.action,
      required this.onAction,
      required this.children});
  final String title, subtitle, action;
  final VoidCallback onAction;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
        Text(subtitle, style: const TextStyle(color: Color(0xFF5F766C))),
        const SizedBox(height: 14),
        FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(action)),
        ...children
      ]);
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(22),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5F766C))));
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 42),
        const SizedBox(height: 10),
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi'))
      ]));
}
