import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'laras_operations_page.dart';
import 'laras_design.dart';
import 'laras_components.dart';
import 'laras_forms.dart';

const kSuppliersKey = 'laras_suppliers_v1';
const kMaterialsKey = 'laras_materials_v1';

const _deep = Color(0xFF0C6B40);

/// Modal produk dari resep: bahan (harga terbaru) + upah + overhead.
int recipeCost(
  Map<String, dynamic> product,
  Map<String, Map<String, dynamic>> materials,
) {
  var sum = 0.0;
  for (final line in (product['recipe'] as List?) ?? const []) {
    final m = materials['${line['materialId']}'];
    final unit = ((m?['pricePerUnit'] ?? line['unitPrice']) as num?) ?? 0;
    sum += unit.toDouble() * ((line['qty'] as num?)?.toDouble() ?? 0);
  }
  sum +=
      ((product['labor'] as num?) ?? 0) + ((product['overhead'] as num?) ?? 0);
  return sum.round();
}

class CostImpact {
  CostImpact(this.name, this.oldCost, this.newCost, this.price);
  final String name;
  final int oldCost, newCost, price;
  double get oldMargin => price <= 0 ? 0 : (price - oldCost) * 100 / price;
  double get newMargin => price <= 0 ? 0 : (price - newCost) * 100 / price;
}

/// Hitung ulang modal semua produk bermode resep setelah harga bahan berubah.
Future<List<CostImpact>> recomputeRecipeCosts(LarasLocalRepository repo) async {
  final products = await repo.read(LarasLocalRepository.products);
  final materials = {
    for (final m in await repo.read(kMaterialsKey)) '${m['id']}': m,
  };
  final impacts = <CostImpact>[];
  var changed = false;
  for (var i = 0; i < products.length; i++) {
    final p = products[i];
    final recipe = (p['recipe'] as List?) ?? const [];
    if (p['costMode'] != 'resep' || recipe.isEmpty) continue;
    final lines = [
      for (final line in recipe)
        {
          ...Map<String, dynamic>.from(line as Map),
          if (materials['${line['materialId']}'] != null)
            'unitPrice': materials['${line['materialId']}']!['pricePerUnit'],
        },
    ];
    final next = {...p, 'recipe': lines};
    final cost = recipeCost(next, materials);
    final old = (p['cost'] as num? ?? 0).round();
    next['cost'] = cost;
    products[i] = next;
    changed = true;
    if (cost != old) {
      impacts.add(
        CostImpact(
          '${p['name']}',
          old,
          cost,
          (p['price'] as num? ?? 0).round(),
        ),
      );
    }
  }
  if (changed) await repo.write(LarasLocalRepository.products, products);
  return impacts;
}

String _pct(double v) => '${v.toStringAsFixed(0)}%';

InputDecoration _field(String label, {String? hint, String? prefix}) =>
    InputDecoration(labelText: label, hintText: hint, prefixText: prefix);

Widget _gradientHeader({required Widget child}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LarasDesign.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );

/// Tab Supplier: daftar pemasok bahan baku.
class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _suppliers = [], _materials = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _repo.read(kSuppliersKey);
      final m = await _repo.read(kMaterialsKey);
      if (mounted) {
        setState(() {
          _suppliers = s;
          _materials = m;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Data supplier belum dapat dibaca.';
        });
      }
    }
  }

  Future<void> _add() async {
    final r = await showSupplierForm(context);
    if (r == null) return;
    try {
      await _repo.write(kSuppliersKey, [r, ..._suppliers]);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier belum tersimpan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('supplier_page'),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          const LarasEntrance(
            child: LarasPageIntro(
              eyebrow: 'Jaringan usahamu',
              title: 'Supplier',
              icon: Icons.local_shipping_outlined,
              description:
                  'Temukan kontak, pantau harga bahan, dan jaga pasokan usahamu.',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('add_supplier'),
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Tambah supplier'),
          ),
          const SizedBox(height: 14),
          if (_suppliers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Belum ada supplier. Tambahkan pemasok pertama.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LarasDesign.secondary(context)),
              ),
            ),
          for (final s in _suppliers) _tile(s),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> s) {
    final mine = _materials.where((m) => m['supplierId'] == s['id']).toList();
    return LarasRecordCard(
      key: Key('supplier_${s['id']}'),
      title: '${s['name']}',
      subtitle:
          '${(s['phone'] ?? '').toString().isEmpty ? 'Tanpa nomor' : s['phone']}\n${mine.length} bahan baku',
      icon: Icons.local_shipping_outlined,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierDetailPage(supplierId: '${s['id']}'),
          ),
        );
        await _load();
      },
    );
  }
}

Future<Map<String, dynamic>?> showSupplierForm(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final repo = LarasLocalRepository();
  final name = TextEditingController(text: '${initial?['name'] ?? ''}');
  final phone = TextEditingController(text: '${initial?['phone'] ?? ''}');
  final address = TextEditingController(text: '${initial?['address'] ?? ''}');
  final note = TextEditingController(text: '${initial?['note'] ?? ''}');
  final form = GlobalKey<FormState>();
  final r = await showLarasFormDialog<Map<String, dynamic>>(
    context: context,
    builder: (c) => LarasFormDialog(
      title: initial == null ? 'Tambah supplier' : 'Ubah supplier',
      description: 'Simpan kontak dan informasi pemasok usahamu.',
      icon: Icons.local_shipping_outlined,
      body: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LarasLabeledField(
              label: 'Nama supplier',
              child: TextFormField(
                key: const Key('supplier_name'),
                controller: name,
                decoration: larasEntryDecoration(
                  hint: 'Contoh: Toko Mori Sejahtera',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 20),
            LarasLabeledField(
              label: 'Nomor telepon / WhatsApp',
              child: TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: larasEntryDecoration(
                  hint: 'Contoh: 0812 3456 7890',
                ),
              ),
            ),
            const SizedBox(height: 20),
            LarasLabeledField(
              label: 'Alamat',
              child: TextFormField(
                controller: address,
                minLines: 2,
                maxLines: 3,
                decoration: larasEntryDecoration(
                  hint: 'Alamat toko atau lokasi pemasok',
                ),
              ),
            ),
            const SizedBox(height: 20),
            LarasLabeledField(
              label: 'Catatan',
              child: TextFormField(
                controller: note,
                minLines: 2,
                maxLines: 3,
                decoration: larasEntryDecoration(
                  hint: 'Contoh: pemasok kain mori dan malam',
                ),
              ),
            ),
          ],
        ),
      ),
      onCancel: () => Navigator.pop(c),
      onSave: () {
        if (form.currentState!.validate()) {
          Navigator.pop(c, {
            'id': initial?['id'] ?? repo.id(),
            'name': name.text.trim(),
            'phone': phone.text.trim(),
            'address': address.text.trim(),
            'note': note.text.trim(),
            'createdAt':
                initial?['createdAt'] ?? DateTime.now().toIso8601String(),
          });
        }
      },
    ),
  );
  name.dispose();
  phone.dispose();
  address.dispose();
  note.dispose();
  return r;
}

class SupplierDetailPage extends StatefulWidget {
  const SupplierDetailPage({super.key, required this.supplierId});
  final String supplierId;
  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _suppliers = [], _materials = [];
  bool _loading = true;

  Map<String, dynamic>? get _supplier => _suppliers
      .where((s) => s['id'] == widget.supplierId)
      .cast<Map<String, dynamic>?>()
      .firstOrNull;
  List<Map<String, dynamic>> get _mine =>
      _materials.where((m) => m['supplierId'] == widget.supplierId).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.read(kSuppliersKey);
    final m = await _repo.read(kMaterialsKey);
    if (mounted) {
      setState(() {
        _suppliers = s;
        _materials = m;
        _loading = false;
      });
    }
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editSupplier() async {
    final s = _supplier;
    if (s == null) return;
    final r = await showSupplierForm(context, initial: s);
    if (r == null) return;
    await _repo.write(kSuppliersKey, [
      for (final e in _suppliers) e['id'] == r['id'] ? r : e,
    ]);
    await _load();
  }

  Future<void> _deleteSupplier() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Hapus ${_supplier?['name']}?'),
        content: const Text(
          'Supplier dan daftar bahannya dihapus. Modal produk yang memakai resep tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _repo.write(
      kSuppliersKey,
      _suppliers.where((e) => e['id'] != widget.supplierId).toList(),
    );
    await _repo.write(
      kMaterialsKey,
      _materials.where((e) => e['supplierId'] != widget.supplierId).toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _editMaterial([Map<String, dynamic>? initial]) async {
    final name = TextEditingController(text: '${initial?['name'] ?? ''}');
    final unit = TextEditingController(text: '${initial?['unit'] ?? 'meter'}');
    final price = TextEditingController(
      text: initial == null ? '' : '${initial['pricePerUnit']}',
    );
    final form = GlobalKey<FormState>();
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(initial == null ? 'Tambah bahan' : 'Ubah bahan'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('material_name'),
                controller: name,
                decoration: _field('Nama bahan'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: unit,
                decoration: _field('Satuan', hint: 'meter, kg, roll, pcs'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Satuan wajib diisi' : null,
              ),
              TextFormField(
                key: const Key('material_price'),
                controller: price,
                keyboardType: TextInputType.number,
                decoration: _field('Harga per satuan (Rp)'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Harga harus lebih dari nol'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, {
                  'name': name.text.trim(),
                  'unit': unit.text.trim(),
                  'price': int.parse(price.text),
                });
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (r == null) return;
    final now = DateTime.now().toIso8601String();
    final oldPrice = (initial?['pricePerUnit'] as num?)?.round();
    final history = [
      ...((initial?['priceHistory'] as List?) ?? const []),
      if (oldPrice != r['price']) {'price': r['price'], 'at': now},
    ];
    final material = {
      'id': initial?['id'] ?? _repo.id(),
      'supplierId': widget.supplierId,
      'name': r['name'],
      'unit': r['unit'],
      'pricePerUnit': r['price'],
      'updatedAt': now,
      'priceHistory': history,
    };
    try {
      final next = initial == null
          ? [material, ..._materials]
          : [
              for (final e in _materials)
                e['id'] == material['id'] ? material : e,
            ];
      await _repo.write(kMaterialsKey, next);
      List<CostImpact> impacts = [];
      if (initial != null && oldPrice != r['price']) {
        impacts = await recomputeRecipeCosts(_repo);
      }
      await _load();
      if (impacts.isNotEmpty && mounted) {
        await _showImpact(material, oldPrice, impacts);
      }
    } catch (_) {
      if (mounted) _toast('Bahan belum tersimpan. Coba lagi.');
    }
  }

  Future<void> _showImpact(
    Map<String, dynamic> material,
    int? oldPrice,
    List<CostImpact> impacts,
  ) async {
    final newPrice = (material['pricePerUnit'] as num).round();
    final change = oldPrice == null || oldPrice == 0
        ? 0.0
        : (newPrice - oldPrice) * 100 / oldPrice;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const Key('impact_dialog'),
        title: Text(
          'Harga ${material['name']} ${change >= 0 ? 'naik' : 'turun'} ${change.abs().toStringAsFixed(0)}%',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${impacts.length} produk terdampak:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final i in impacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${i.name}\nModal ${larasRupiah(i.oldCost)} → ${larasRupiah(i.newCost)} · margin ${_pct(i.oldMargin)} → ${_pct(i.newMargin)}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Lihat Harga & Margin'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LarasOperationsPage(section: 'margin'),
        ),
      );
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Hapus ${m['name']}?'),
        content: const Text('Bahan dihapus dari supplier ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _repo.write(
      kMaterialsKey,
      _materials.where((e) => e['id'] != m['id']).toList(),
    );
    await _load();
  }

  Future<void> _buy() async {
    final mine = _mine;
    if (mine.isEmpty) {
      _toast('Tambahkan bahan terlebih dahulu.');
      return;
    }
    var selected = mine.first;
    final qty = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: const Text('Catat pembelian bahan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: '${selected['id']}',
                isExpanded: true,
                items: [
                  for (final m in mine)
                    DropdownMenuItem(
                      value: '${m['id']}',
                      child: Text(
                        '${m['name']} · ${larasRupiah(m['pricePerUnit'] as num)}/${m['unit']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setLocal(
                  () => selected = mine.firstWhere((m) => '${m['id']}' == v),
                ),
              ),
              TextField(
                key: const Key('buy_qty'),
                controller: qty,
                keyboardType: TextInputType.number,
                onChanged: (_) => setLocal(() {}),
                decoration: _field('Jumlah (${selected['unit']})'),
              ),
              const SizedBox(height: 10),
              Text(
                'Total ${larasRupiah((double.tryParse(qty.text) ?? 0) * (selected['pricePerUnit'] as num))}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Catat pengeluaran'),
            ),
          ],
        ),
      ),
    );
    final q = double.tryParse(qty.text) ?? 0;
    if (ok != true || q <= 0) return;
    final amount = (q * (selected['pricePerUnit'] as num)).round();
    try {
      final expenses = await _repo.read(LarasLocalRepository.expenses);
      await _repo.write(LarasLocalRepository.expenses, [
        {
          'id': _repo.id(),
          'name': 'Beli ${selected['name']} (${_supplier?['name']})',
          'amount': amount,
          'category': 'Bahan baku',
          'method': 'Tunai',
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'Supplier',
        },
        ...expenses,
      ]);
      if (mounted) {
        _toast('Pengeluaran ${larasRupiah(amount)} tercatat di Keuangan.');
      }
    } catch (_) {
      if (mounted) _toast('Pembelian belum tersimpan. Coba lagi.');
    }
  }

  /// Bahan sama (nama sama) dari supplier lain yang lebih murah?
  bool _cheapest(Map<String, dynamic> m) {
    final same = _materials.where(
      (o) => '${o['name']}'.toLowerCase() == '${m['name']}'.toLowerCase(),
    );
    if (same.length < 2) return false;
    return same.every(
      (o) => (o['pricePerUnit'] as num) >= (m['pricePerUnit'] as num),
    );
  }

  String? _trend(Map<String, dynamic> m) {
    final h = (m['priceHistory'] as List?) ?? const [];
    if (h.length < 2) return null;
    final prev = (h[h.length - 2]['price'] as num).toDouble();
    final now = (h.last['price'] as num).toDouble();
    if (prev <= 0 || prev == now) return null;
    final c = (now - prev) * 100 / prev;
    return '${c > 0 ? 'Naik' : 'Turun'} ${c.abs().toStringAsFixed(0)}% dari ${larasRupiah(prev)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = _supplier;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s == null ? 'Supplier' : '${s['name']}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (s != null) ...[
            IconButton(
              tooltip: 'Ubah supplier',
              onPressed: _editSupplier,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus supplier',
              onPressed: _deleteSupplier,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: _loading || s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('supplier_detail'),
              padding: const EdgeInsets.all(16),
              children: [
                _gradientHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${s['phone']}'.isEmpty
                                  ? 'Tanpa nomor'
                                  : '${s['phone']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if ('${s['phone']}'.isNotEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: '${s['phone']}'),
                                );
                                if (mounted) _toast('Nomor disalin.');
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Salin'),
                            ),
                        ],
                      ),
                      if ('${s['address']}'.isNotEmpty)
                        Text(
                          '${s['address']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      if ('${s['note']}'.isNotEmpty)
                        Text(
                          '${s['note']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('add_material'),
                        onPressed: () => _editMaterial(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah bahan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('buy_material'),
                        onPressed: _buy,
                        icon: const Icon(Icons.shopping_basket_outlined),
                        label: const Text('Beli bahan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bahan baku & harga',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Belum ada bahan dari supplier ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: LarasDesign.secondary(context)),
                    ),
                  ),
                for (final m in _mine)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      key: Key('material_${m['id']}'),
                      onTap: () => _editMaterial(m),
                      title: Text(
                        '${m['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${larasRupiah(m['pricePerUnit'] as num)} / ${m['unit']}'
                        '${_trend(m) == null ? '' : '\n${_trend(m)}'}',
                      ),
                      isThreeLine: _trend(m) != null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_cheapest(m))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6F5E4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Termurah',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _deep,
                                ),
                              ),
                            ),
                          IconButton(
                            tooltip: 'Hapus bahan',
                            onPressed: () => _deleteMaterial(m),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Resep produk: modal dihitung dari harga bahan supplier + upah + overhead.
class ProductRecipePage extends StatefulWidget {
  const ProductRecipePage({super.key, required this.product});
  final Map<String, dynamic> product;
  @override
  State<ProductRecipePage> createState() => _ProductRecipePageState();
}

class _ProductRecipePageState extends State<ProductRecipePage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _materials = [], _suppliers = [];
  late List<Map<String, dynamic>> _lines;
  late final TextEditingController _labor, _overhead;
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _lines = [
      for (final l in (widget.product['recipe'] as List?) ?? const [])
        Map<String, dynamic>.from(l as Map),
    ];
    _labor = TextEditingController(text: '${widget.product['labor'] ?? 0}');
    _overhead = TextEditingController(
      text: '${widget.product['overhead'] ?? 0}',
    );
    _load();
  }

  @override
  void dispose() {
    _labor.dispose();
    _overhead.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final m = await _repo.read(kMaterialsKey);
    final s = await _repo.read(kSuppliersKey);
    if (mounted) {
      setState(() {
        _materials = m;
        _suppliers = s;
        _loading = false;
      });
    }
  }

  String _supplierName(Object? id) =>
      '${_suppliers.where((s) => s['id'] == id).map((s) => s['name']).firstOrNull ?? '-'}';
  Map<String, Map<String, dynamic>> get _byId => {
        for (final m in _materials) '${m['id']}': m,
      };
  int get _laborValue => int.tryParse(_labor.text.trim()) ?? 0;
  int get _overheadValue => int.tryParse(_overhead.text.trim()) ?? 0;

  num _unitPrice(Map<String, dynamic> line) =>
      (_byId['${line['materialId']}']?['pricePerUnit'] ??
          line['unitPrice'] ??
          0) as num;

  int get _materialTotal => _lines.fold<int>(
        0,
        (s, l) => s + (_unitPrice(l) * ((l['qty'] as num?) ?? 0)).round(),
      );
  int get _total => _materialTotal + _laborValue + _overheadValue;

  Future<void> _addLine() async {
    if (_materials.isEmpty) return;
    var selected = _materials.first;
    final qty = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: const Text('Tambah bahan ke resep'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('recipe_material'),
                initialValue: '${selected['id']}',
                isExpanded: true,
                items: [
                  for (final m in _materials)
                    DropdownMenuItem(
                      value: '${m['id']}',
                      child: Text(
                        '${m['name']} · ${_supplierName(m['supplierId'])} · ${larasRupiah(m['pricePerUnit'] as num)}/${m['unit']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setLocal(
                  () => selected = _materials.firstWhere(
                    (m) => '${m['id']}' == v,
                  ),
                ),
              ),
              TextField(
                key: const Key('recipe_qty'),
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _field(
                  'Pemakaian per 1 produk (${selected['unit']})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
    final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
    if (ok != true || q <= 0) return;
    setState(
      () => _lines.add({
        'materialId': selected['id'],
        'name': selected['name'],
        'unit': selected['unit'],
        'qty': q,
        'unitPrice': selected['pricePerUnit'],
      }),
    );
  }

  Future<void> _save({required bool useRecipe}) async {
    setState(() => _saving = true);
    try {
      final all = await _repo.read(LarasLocalRepository.products);
      final i = all.indexWhere(
        (e) =>
            e['name'] == widget.product['name'] &&
            e['sku'] == widget.product['sku'],
      );
      if (i < 0) throw StateError('Produk tidak ditemukan.');
      final lines = [
        for (final l in _lines) {...l, 'unitPrice': _unitPrice(l)},
      ];
      all[i] = {
        ...all[i],
        'recipe': lines,
        'labor': _laborValue,
        'overhead': _overheadValue,
        'costMode': useRecipe ? 'resep' : 'manual',
        if (useRecipe) 'cost': _total,
      };
      await _repo.write(LarasLocalRepository.products, all);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            useRecipe
                ? 'Modal produk diperbarui menjadi ${larasRupiah(_total)}.'
                : 'Kembali memakai modal manual.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep belum tersimpan. Coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.product['price'] as num? ?? 0).round();
    final margin = price <= 0 ? 0.0 : (price - _total) * 100 / price;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resep & modal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('recipe_page'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${widget.product['name']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modal dihitung otomatis dari harga bahan supplier, upah, dan overhead per 1 produk.',
                  style: TextStyle(
                    color: LarasDesign.secondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                if (_materials.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada bahan baku. Tambahkan bahan di tab Supplier lebih dulu.',
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    key: const Key('add_recipe_line'),
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah bahan'),
                  ),
                const SizedBox(height: 12),
                for (var i = 0; i < _lines.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        '${_lines[i]['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_lines[i]['qty']} ${_lines[i]['unit']} × ${larasRupiah(_unitPrice(_lines[i]))}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            larasRupiah(
                              _unitPrice(_lines[i]) *
                                  ((_lines[i]['qty'] as num?) ?? 0),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            tooltip: 'Hapus bahan',
                            onPressed: () => setState(() => _lines.removeAt(i)),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('labor_field'),
                  controller: _labor,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _field('Upah pengrajin per produk (Rp)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('overhead_field'),
                  controller: _overhead,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _field(
                    'Overhead per produk (listrik, gas, kemasan)',
                  ),
                ),
                const SizedBox(height: 16),
                _gradientHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modal otomatis',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        larasRupiah(_total),
                        key: const Key('recipe_total'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Bahan ${larasRupiah(_materialTotal)} + upah ${larasRupiah(_laborValue)} + overhead ${larasRupiah(_overheadValue)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Harga jual ${larasRupiah(price)} → margin ${margin.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('use_recipe_cost'),
                  onPressed: _saving || _lines.isEmpty
                      ? null
                      : () => _save(useRecipe: true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Pakai modal ini'),
                ),
                if (widget.product['costMode'] == 'resep')
                  TextButton(
                    onPressed: _saving ? null : () => _save(useRecipe: false),
                    child: const Text('Kembali ke modal manual'),
                  ),
              ],
            ),
    );
  }
}
