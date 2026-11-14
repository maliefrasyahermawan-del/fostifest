import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'laras_operations_page.dart' show larasRupiah;

const _yellow = Color(0xFF14935A);
const _ink = Color(0xFF123126);
const _gold = Color(0xFF0B5D3B);
const _red = Color(0xFF8A5A00);
const _amber = Color(0xFF8A5A00);
const _muted = Color(0xFF5F766C);

enum StockLevel { habis, menipis, aman }

StockLevel stockLevel(Map<String, dynamic> p) {
  final s = (p['stock'] as num?)?.toInt() ?? 0;
  final m = (p['min'] as num?)?.toInt() ?? 0;
  if (s <= 0) return StockLevel.habis;
  return s <= m ? StockLevel.menipis : StockLevel.aman;
}

/// Margin keuntungan dalam persen dari harga jual (0 bila harga jual 0).
double productMargin(Map<String, dynamic> p) {
  final price = (p['price'] as num?)?.toDouble() ?? 0;
  final cost = (p['cost'] as num?)?.toDouble() ?? 0;
  return price <= 0 ? 0 : (price - cost) * 100 / price;
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Map<String, dynamic>> products = [];
  bool _loaded = false;
  String _query = '';
  String _filter = 'Semua'; // Semua | Menipis | Habis | <kategori>
  String _sort = 'Nama';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(p.getString('laras_products_v1') ?? '[]') as List;
      if (mounted) {
        setState(() {
          products =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loaded = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data produk tidak dapat dibaca.')));
      }
    }
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (!await p.setString('laras_products_v1', jsonEncode(products))) {
      throw StateError('Gagal menyimpan produk');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _safePersist(String failMessage) async {
    try {
      await persist();
    } catch (_) {
      await load();
      if (mounted) _toast(failMessage);
    }
  }

  /// Ubah stok satu produk langsung dari kartu (tanpa membuka formulir).
  Future<void> _adjustStock(Map<String, dynamic> p, int delta) async {
    final next = ((p['stock'] as num?)?.toInt() ?? 0) + delta;
    if (next < 0) return;
    setState(() => p['stock'] = next);
    await _safePersist('Stok gagal disimpan.');
  }

  Future<void> edit([Map<String, dynamic>? item]) async {
    final isNew = item == null;
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final sku = TextEditingController(text: item?['sku'] as String? ?? '');
    final category =
        TextEditingController(text: item?['category'] as String? ?? '');
    final price = TextEditingController(text: isNew ? '' : '${item['price']}');
    final cost = TextEditingController(text: isNew ? '' : '${item['cost']}');
    final stock = TextEditingController(text: isNew ? '' : '${item['stock']}');
    final min = TextEditingController(text: isNew ? '0' : '${item['min']}');
    final form = GlobalKey<FormState>();
    final categories = {
      for (final p in products)
        if ('${p['category'] ?? ''}'.isNotEmpty) '${p['category']}'
    }.toList();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final pr = int.tryParse(price.text) ?? 0;
        final co = int.tryParse(cost.text) ?? 0;
        final margin = pr <= 0 ? null : (pr - co) * 100 / pr;
        Widget numberField(TextEditingController c, String label,
                {String? prefix, String? helper}) =>
            TextFormField(
                controller: c,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setSheet(() {}),
                decoration: InputDecoration(
                    labelText: label,
                    prefixText: prefix,
                    helperText: helper,
                    border: const OutlineInputBorder()),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Isi angka nol atau lebih'
                    : null);
        Widget heading(String t) => Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Text(t,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13, color: _gold)));
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(isNew ? 'Tambah produk' : 'Edit produk',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900))),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close)),
                    ]),
                    heading('INFO PRODUK'),
                    TextFormField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Nama produk',
                            border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Isi nama produk'
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: sku,
                        decoration: const InputDecoration(
                            labelText: 'SKU (opsional)',
                            border: OutlineInputBorder()),
                        validator: (v) {
                          final code = v?.trim() ?? '';
                          if (code.isEmpty) return null;
                          for (final p in products) {
                            if (!identical(p, item) &&
                                (p['sku'] as String? ?? '') == code) {
                              return 'Kode sudah digunakan';
                            }
                          }
                          return null;
                        }),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: category,
                        onChanged: (_) => setSheet(() {}),
                        decoration: const InputDecoration(
                            labelText: 'Kategori (opsional)',
                            border: OutlineInputBorder())),
                    if (categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(spacing: 8, runSpacing: 0, children: [
                          for (final c in categories)
                            ActionChip(
                                label: Text(c),
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setSheet(() => category.text = c)),
                        ]),
                      ),
                    heading('HARGA'),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: numberField(price, 'Harga jual',
                                  prefix: 'Rp ')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: numberField(cost, 'Harga modal',
                                  prefix: 'Rp ')),
                        ]),
                    if (margin != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'Untung ${larasRupiah(pr - co)} per produk · margin ${margin.toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: margin < 20 ? _red : _gold)),
                      ),
                    heading('STOK'),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: numberField(stock, 'Stok')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: numberField(min, 'Batas stok menipis',
                                  helper: 'Diingatkan di bawah ini')),
                        ]),
                    const SizedBox(height: 20),
                    FilledButton(
                        key: const Key('inv_save'),
                        onPressed: () {
                          if (!form.currentState!.validate()) return;
                          Navigator.pop(ctx, {
                            'name': name.text.trim(),
                            'sku': sku.text.trim(),
                            'category': category.text.trim(),
                            'price': int.parse(price.text),
                            'cost': int.parse(cost.text),
                            'stock': int.parse(stock.text),
                            'min': int.parse(min.text)
                          });
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: _yellow,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52)),
                        child: const Text('Simpan')),
                    if (!isNew)
                      TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await remove(item);
                          },
                          icon: const Icon(Icons.delete_outline, color: _red),
                          label: const Text('Hapus produk',
                              style: TextStyle(color: _red))),
                  ]),
            ),
          ),
        );
      }),
    );
    if (result != null && mounted) {
      setState(() {
        if (isNew) {
          products.add(result);
        } else {
          // Pertahankan data lain (resep, tenaga kerja, dll) yang tidak ada di formulir.
          item.addAll(result);
        }
      });
      await _safePersist('Produk gagal disimpan.');
    }
    // Controller sengaja tidak di-dispose: sheet masih beranimasi tutup saat
    // fungsi ini lanjut, dan dispose lebih awal membuat widget error.
  }

  Future<bool> remove(Map<String, dynamic> p) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Hapus produk?'),
                content: Text(p['name'] as String),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'))
                ]));
    if (confirmed != true || !mounted) return false;
    setState(() => products.remove(p));
    await _safePersist('Produk gagal dihapus.');
    return true;
  }

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    final list = products.where((p) {
      final lvl = stockLevel(p);
      final okFilter = switch (_filter) {
        'Semua' => true,
        'Menipis' => lvl == StockLevel.menipis || lvl == StockLevel.habis,
        'Habis' => lvl == StockLevel.habis,
        final c => '${p['category'] ?? ''}' == c,
      };
      final okQuery = q.isEmpty ||
          '${p['name']}'.toLowerCase().contains(q) ||
          '${p['sku'] ?? ''}'.toLowerCase().contains(q) ||
          '${p['category'] ?? ''}'.toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();
    switch (_sort) {
      case 'Stok terendah':
        list.sort((a, b) => (a['stock'] as num).compareTo(b['stock'] as num));
      case 'Margin tertinggi':
        list.sort((a, b) => productMargin(b).compareTo(productMargin(a)));
      default:
        list.sort((a, b) => '${a['name']}'
            .toLowerCase()
            .compareTo('${b['name']}'.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final low =
        products.where((p) => stockLevel(p) == StockLevel.menipis).length;
    final out = products.where((p) => stockLevel(p) == StockLevel.habis).length;
    final value = products.fold<int>(
        0,
        (s, p) =>
            s +
            ((p['stock'] as num?)?.toInt() ?? 0) *
                ((p['cost'] as num?)?.toInt() ?? 0));
    final categories = {
      for (final p in products)
        if ('${p['category'] ?? ''}'.isNotEmpty) '${p['category']}'
    }.toList()
      ..sort();
    final shown = _visible;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Produk dan stok',
              style: TextStyle(fontWeight: FontWeight.w900))),
      floatingActionButton: FloatingActionButton.extended(
          key: const Key('inv_add'),
          onPressed: () => edit(),
          backgroundColor: _yellow,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Tambah produk')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? _emptyAll()
              : ListView(
                  key: const Key('inv_list'),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  children: [
                    Row(children: [
                      _stat('PRODUK', '${products.length}', _yellow),
                      const SizedBox(width: 8),
                      _stat('MENIPIS / HABIS', '${low + out}',
                          low + out > 0 ? _amber : _gold),
                      const SizedBox(width: 8),
                      _stat('NILAI STOK', _compact(value), _gold),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          key: const Key('inv_search'),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Cari nama, SKU, atau kategori',
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Urutkan',
                        icon: const Icon(Icons.sort_rounded),
                        initialValue: _sort,
                        onSelected: (v) => setState(() => _sort = v),
                        itemBuilder: (_) => [
                          for (final s in const [
                            'Nama',
                            'Stok terendah',
                            'Margin tertinggi'
                          ])
                            PopupMenuItem(value: s, child: Text('Urut: $s')),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final f in [
                          'Semua',
                          'Menipis',
                          'Habis',
                          ...categories
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    if (shown.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            const Icon(Icons.search_off_rounded,
                                size: 40, color: _muted),
                            const SizedBox(height: 8),
                            Text(
                                _filter == 'Menipis' && _query.isEmpty
                                    ? 'Tidak ada produk yang menipis. Stokmu aman.'
                                    : 'Tidak ada produk yang cocok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _muted)),
                          ]))
                    else
                      for (final p in shown) _card(p),
                  ],
                ),
    );
  }

  String _compact(int v) => v >= 1000000
      ? 'Rp${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)} jt'
      : v >= 1000
          ? 'Rp${(v / 1000).round()} rb'
          : 'Rp$v';

  Widget _emptyAll() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: .25),
                    shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 40, color: _ink)),
            const SizedBox(height: 16),
            const Text('Belum ada produk',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
                'Tambahkan produk pertamamu untuk memantau stok dan margin keuntungan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.4)),
          ]),
        ),
      );

  Widget _stat(String label, String value, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: c.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
        ),
      );

  Widget _card(Map<String, dynamic> p) {
    final i = products.indexOf(p);
    final lvl = stockLevel(p);
    final (label, color) = switch (lvl) {
      StockLevel.habis => ('Habis', _red),
      StockLevel.menipis => ('Menipis', _amber),
      StockLevel.aman => ('Aman', _gold),
    };
    final margin = productMargin(p);
    final category = '${p['category'] ?? ''}';
    final sku = '${p['sku'] ?? ''}';
    final name = '${p['name']}';
    final stock = (p['stock'] as num).toInt();
    return Dismissible(
      key: ObjectKey(p),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => remove(p).then((_) => false),
      background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
              color: _red.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline, color: _red)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('inv_item_$i'),
          onTap: () => edit(p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: lvl == StockLevel.aman
                            ? _yellow.withValues(alpha: .28)
                            : color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(13)),
                    child: Text(
                        name.isEmpty
                            ? '?'
                            : name.characters.first.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _ink))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                      if (category.isNotEmpty || sku.isNotEmpty)
                        Text(
                            [category, sku]
                                .where((e) => e.isNotEmpty)
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 12, color: _muted)),
                    ])),
                const SizedBox(width: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(larasRupiah((p['price'] as num).toInt()),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                          'Modal ${larasRupiah((p['cost'] as num).toInt())} · margin ${margin.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: margin < 20 ? _red : _muted)),
                    ])),
                _stepper(p, i, stock, color),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stepper(Map<String, dynamic> p, int i, int stock, Color color) =>
      Container(
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              key: Key('inv_minus_$i'),
              tooltip: 'Kurangi stok',
              visualDensity: VisualDensity.compact,
              onPressed: stock > 0 ? () => _adjustStock(p, -1) : null,
              icon: const Icon(Icons.remove_rounded)),
          ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 28),
              child: Text('$stock',
                  key: Key('inv_stock_$i'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16))),
          IconButton(
              key: Key('inv_plus_$i'),
              tooltip: 'Tambah stok',
              visualDensity: VisualDensity.compact,
              onPressed: () => _adjustStock(p, 1),
              icon: const Icon(Icons.add_rounded)),
        ]),
      );
}
