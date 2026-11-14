import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'laras_operations_page.dart';
import 'supplier_page.dart';

const priceSimulationKey = 'laras_price_simulations_v1';

class PriceSimulationResult {
  const PriceSimulationResult({
    required this.price,
    required this.quantity,
    required this.materialCost,
    required this.productionCost,
  });
  final int price, quantity, materialCost, productionCost;
  int get unitCost => materialCost + productionCost;
  int get revenue => price * quantity;
  int get totalCost => unitCost * quantity;
  int get profit => revenue - totalCost;
  int get loss => profit < 0 ? -profit : 0;
  double get margin => revenue == 0 ? 0 : profit * 100 / revenue;
  int get breakEvenPrice => unitCost;
}

class PriceSimulationStore {
  static const maxItems = 10;
  Future<List<Map<String, dynamic>>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString(priceSimulationKey) ?? '[]') as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> save(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await read();
    final index = all.indexWhere((e) => e['id'] == item['id']);
    if (index >= 0) {
      all[index] = item;
    } else {
      if (all.length >= maxItems)
        throw StateError('Maksimal 10 simulasi tersimpan.');
      all.insert(0, item);
    }
    if (!await prefs.setString(priceSimulationKey, jsonEncode(all)))
      throw StateError('Simulasi belum tersimpan.');
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await read()
      ..removeWhere((e) => e['id'] == id);
    if (!await prefs.setString(priceSimulationKey, jsonEncode(all)))
      throw StateError('Simulasi belum terhapus.');
  }
}

class PriceSimulationPage extends StatefulWidget {
  const PriceSimulationPage({super.key});
  @override
  State<PriceSimulationPage> createState() => _PriceSimulationPageState();
}

class _PriceSimulationPageState extends State<PriceSimulationPage> {
  final _repo = LarasLocalRepository();
  final _store = PriceSimulationStore();
  final _price = TextEditingController(text: '0');
  final _qty = TextEditingController(text: '1');
  final _materialQty = TextEditingController(text: '1');
  final _production = TextEditingController(text: '0');
  List<Map<String, dynamic>> _products = [],
      _materials = [],
      _suppliers = [],
      _saved = [];
  String? _productId, _materialId, _editingId;
  bool _loading = true;

  int _number(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, String? id) {
    for (final e in list) {
      if ('${e['id'] ?? e['sku']}' == id) return e;
    }
    return null;
  }

  int get _materialCost {
    final m = _find(_materials, _materialId);
    return (((m?['pricePerUnit'] as num?) ?? 0) * _number(_materialQty))
        .round();
  }

  PriceSimulationResult get _result => PriceSimulationResult(
        price: _number(_price).clamp(0, 10000000),
        quantity: _number(_qty).clamp(1, 999999),
        materialCost: _materialCost,
        productionCost: _number(_production),
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_price, _qty, _materialQty, _production]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Future.wait([
      _repo.read(LarasLocalRepository.products),
      _repo.read(kMaterialsKey),
      _repo.read(kSuppliersKey),
      _store.read(),
    ]);
    if (mounted)
      setState(() {
        _products = data[0];
        _materials = data[1];
        _suppliers = data[2];
        _saved = data[3];
        _loading = false;
      });
  }

  void _selectProduct(String? id) {
    final p = _find(_products, id);
    if (p == null) return;
    setState(() {
      _productId = id;
      _price.text = '${(p['price'] as num? ?? 0).round()}';
      _production.text = '${(p['cost'] as num? ?? 0).round()}';
    });
  }

  String _supplierName(Object? id) =>
      _suppliers
          .where((e) => e['id'] == id)
          .map((e) => '${e['name']}')
          .firstOrNull ??
      'Supplier tidak ditemukan';
  void _clear() => setState(() {
        _editingId = null;
        _productId = null;
        _materialId = null;
        _price.text = '0';
        _qty.text = '1';
        _materialQty.text = '1';
        _production.text = '0';
      });
  void _open(Map<String, dynamic> e) => setState(() {
        _editingId = '${e['id']}';
        _productId = e['productId'] as String?;
        _materialId = e['materialId'] as String?;
        _price.text = '${e['price'] ?? 0}';
        _qty.text = '${e['quantity'] ?? 1}';
        _materialQty.text = '${e['materialQuantity'] ?? 1}';
        _production.text = '${e['productionCost'] ?? 0}';
      });
  Future<void> _save() async {
    final p = _find(_products, _productId),
        m = _find(_materials, _materialId),
        r = _result;
    if (p == null) {
      _toast('Pilih produk yang disimulasikan.');
      return;
    }
    try {
      final now = DateTime.now().toIso8601String();
      await _store.save({
        'id': _editingId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        'name': '${p['name']}',
        'productId': '${p['id'] ?? p['sku']}',
        'materialId': _materialId,
        'materialName': m?['name'],
        'materialQuantity': _number(_materialQty),
        'price': r.price,
        'quantity': r.quantity,
        'productionCost': r.productionCost,
        'updatedAt': now,
      });
      await _load();
      if (mounted) _toast('Simulasi tersimpan. Data produk tidak diubah.');
    } catch (e) {
      _toast(e is StateError ? e.message : 'Simulasi belum tersimpan.');
    }
  }

  Future<void> _delete(Map<String, dynamic> e) async {
    await _store.delete('${e['id']}');
    if (_editingId == e['id']) _clear();
    await _load();
  }

  void _toast(String s) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  InputDecoration _dec(String label, {String? helper}) => InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      );
  Widget _metric(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final r = _result,
        positive = r.profit >= 0,
        material = _find(_materials, _materialId);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6F5),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Simulasi Harga Produk',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _clear,
            tooltip: 'Simulasi baru',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ListView(
        key: const Key('price_simulation_page'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF087A55),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coba harga tanpa mengubah inventaris',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  positive
                      ? 'Potensi untung ${larasRupiah(r.profit)}'
                      : 'Potensi rugi ${larasRupiah(r.loss)}',
                  key: const Key('simulation_profit'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Omzet ${larasRupiah(r.revenue)} · ${r.margin.toStringAsFixed(1)}% margin',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _productId,
            decoration: _dec(
              'Produk inventaris',
              helper: 'Hanya dibaca sebagai titik awal',
            ),
            items: [
              for (final p in _products)
                DropdownMenuItem(
                  value: '${p['id'] ?? p['sku']}',
                  child: Text('${p['name']}'),
                ),
            ],
            onChanged: _selectProduct,
          ),
          const SizedBox(height: 12),
          Text(
            'Harga jual ${larasRupiah(r.price)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Slider(
            key: const Key('price_slider'),
            value: r.price.toDouble(),
            min: 0,
            max: 10000000,
            divisions: 1000,
            label: larasRupiah(r.price),
            onChanged: (v) => setState(() => _price.text = '${v.round()}'),
          ),
          TextField(
            key: const Key('price_input'),
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dec(
              'Harga jual manual',
              helper: 'Rp0 sampai Rp10.000.000',
            ),
            onChanged: (v) {
              final n = _number(_price);
              if (n > 10000000) {
                _price.text = '10000000';
                _price.selection = TextSelection.collapsed(
                  offset: _price.text.length,
                );
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dec('Jumlah produk'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bahan baku & biaya',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _materialId,
            decoration: _dec('Bahan dari supplier'),
            items: [
              for (final m in _materials)
                DropdownMenuItem(
                  value: '${m['id']}',
                  child: Text(
                    '${m['name']} · ${_supplierName(m['supplierId'])}',
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _materialId = v),
          ),
          if (material != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${larasRupiah(material['pricePerUnit'] as num? ?? 0)}/${material['unit']}',
                style: const TextStyle(color: Color(0xFF5F766C)),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _materialQty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Jumlah bahan'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _production,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Biaya produksi/unit'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Omzet', larasRupiah(r.revenue), const Color(0xFF176B45)),
              const SizedBox(width: 8),
              _metric(
                'Total biaya',
                larasRupiah(r.totalCost),
                const Color(0xFF735C0F),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric(
                positive ? 'Laba' : 'Rugi',
                larasRupiah(positive ? r.profit : r.loss),
                positive ? const Color(0xFF087A45) : const Color(0xFFC0342B),
              ),
              const SizedBox(width: 8),
              _metric(
                'Harga impas',
                larasRupiah(r.breakEvenPrice),
                const Color(0xFF315B8A),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('save_simulation'),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              _editingId == null
                  ? 'Simpan simulasi (${_saved.length}/10)'
                  : 'Perbarui simulasi',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tersimpan (${_saved.length}/10)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_saved.isEmpty) const Text('Belum ada simulasi tersimpan.'),
          for (final e in _saved)
            Card(
              child: ListTile(
                onTap: () => _open(e),
                title: Text(
                  '${e['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${larasRupiah(e['price'] as num? ?? 0)} × ${e['quantity']} produk',
                ),
                trailing: IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => _delete(e),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
