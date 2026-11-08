import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'laras_api.dart';
import 'laras_design.dart';
import 'laras_forms.dart';
import 'laras_operations_page.dart';
import 'price_simulation.dart';
import 'simulation_cost_page.dart';
import 'supplier_page.dart' show kMaterialsKey, kSuppliersKey;

class PriceSimulationPage extends StatefulWidget {
  const PriceSimulationPage({super.key, this.initialProduct});
  final Map<String, dynamic>? initialProduct;
  @override
  State<PriceSimulationPage> createState() => _PriceSimulationPageState();
}

class _PriceSimulationPageState extends State<PriceSimulationPage> {
  final _repo = PriceSimulationRepository();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _quantity = TextEditingController(text: '1');
  List<Map<String, dynamic>> _products = [], _materials = [], _suppliers = [];
  SimulationCost _cost = SimulationCost();
  int _count = 0, _selectedProduct = -1;
  bool _loading = true, _error = false, _saving = false;
  String _errorMessage =
      'Data simulasi belum bisa dibaca. Data yang ada tetap tersimpan.';
  PriceSimulation? _pendingSave;
  String? _pendingFingerprint;
  int? get _validPrice {
    final p = int.tryParse(_price.text);
    return p != null && p >= 0 && p <= PriceSimulation.maxPrice ? p : null;
  }

  int? get _validQuantity {
    final q = int.tryParse(_quantity.text);
    return q != null && q > 0 && q <= PriceSimulation.maxQuantity ? q : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final local = LarasLocalRepository();
      final data = await Future.wait([
        local.read(LarasLocalRepository.products),
        local.read(kMaterialsKey),
        local.read(kSuppliersKey),
      ]);
      final saved = await _repo.read();
      if (!mounted) return;
      setState(() {
        _products = data[0];
        _materials = data[1];
        _suppliers = data[2];
        _count = saved.length;
        if (widget.initialProduct != null) {
          _selectProduct(widget.initialProduct!);
          _selectedProduct = _products.indexWhere(
            (p) =>
                p['name'] == widget.initialProduct!['name'] &&
                p['sku'] == widget.initialProduct!['sku'],
          );
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage = e is LarasApiException
              ? e.message
              : 'Data simulasi belum bisa dibaca. Data yang ada tetap tersimpan.';
        });
      }
    }
  }

  void _selectProduct(Map<String, dynamic> p) {
    _name.text = '${p['name']}';
    _price.text =
        '${(p['price'] as num? ?? 0).round().clamp(0, PriceSimulation.maxPrice)}';
    _cost = SimulationCost.fromProduct(p, _materials, _suppliers);
  }

  Future<void> _editCost() async {
    final cost = await Navigator.push<SimulationCost>(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationCostPage(
          cost: _cost,
          materials: _materials,
          suppliers: _suppliers,
        ),
      ),
    );
    if (cost != null && mounted) setState(() => _cost = cost);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _saved() async {
    final result = await Navigator.push<PriceSimulation>(
      context,
      MaterialPageRoute(builder: (_) => const SavedPriceSimulationsPage()),
    );
    if (!mounted) return;
    try {
      final values = await _repo.read();
      if (!mounted) return;
      setState(() {
        _count = values.length;
        if (result != null) {
          _selectedProduct = -1;
          _name.text = result.name;
          _price.text = '${result.price}';
          _quantity.text = '${result.quantity}';
          _cost = result.cost;
        }
      });
      if (result != null) {
        _message('Simulasi dibuka dengan biaya saat disimpan.');
      }
    } catch (e) {
      if (mounted) {
        _message(
          e is LarasApiException
              ? e.message
              : 'Simpanan belum bisa dibaca. Coba buka kembali.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      _message('Periksa kembali nama simulasi, harga jual, dan jumlah produk.');
      return;
    }
    if (!_cost.isDefined) {
      _message('Atur biaya produksi terlebih dahulu.');
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final fingerprint = jsonEncode([
        _name.text.trim(),
        _validPrice,
        _validQuantity,
        _cost.toJson(),
      ]);
      if (_pendingSave == null || fingerprint != _pendingFingerprint) {
        _pendingFingerprint = fingerprint;
        _pendingSave = PriceSimulation(
          id: '${now.microsecondsSinceEpoch}',
          name: _name.text.trim(),
          price: _validPrice!,
          quantity: _validQuantity!,
          cost: _cost,
          savedAt: now,
        );
      }
      await _repo.save(_pendingSave!);
      _pendingSave = null;
      if (!mounted) return;
      setState(() => _count = (_count + 1).clamp(0, 10));
      _message('Simulasi tersimpan ($_count/10).');
      try {
        final saved = await _repo.read();
        if (mounted) setState(() => _count = saved.length);
      } catch (_) {
        /* Save succeeded; a failed refresh must not report a failed save. */
      }
    } on SimulationLimitException {
      if (mounted) {
        setState(() => _count = 10);
        _message(
          'Simpanan penuh. Hapus salah satu simulasi untuk menyimpan yang baru.',
        );
      }
    } catch (e) {
      if (mounted) {
        _message(
          e is LarasApiException
              ? e.message
              : 'Simulasi belum tersimpan. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Simulasi harga',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              key: const Key('simulation_saved'),
              tooltip: 'Simulasi tersimpan',
              onPressed: _loading ? null : _saved,
              icon: const Icon(Icons.bookmarks_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 36),
                            const SizedBox(height: 16),
                            Text(_errorMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Form(
                          key: _form,
                          child: SingleChildScrollView(
                            key: const Key('simulation_scroll'),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'TEMUKAN HARGA YANG PAS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: LarasDesign.accent(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Coba harga. Lihat peluangnya.',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Geser harga jual dan lihat perkiraan untung atau rugi secara langsung.',
                                  style: TextStyle(
                                    color: LarasDesign.secondary(context),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_products.isNotEmpty) ...[
                                  LarasLabeledField(
                                    label: 'Mulai dari produk',
                                    child: DropdownButtonFormField<int>(
                                      // Recreate when opening a saved snapshot, to clear the product selection.
                                      key: ValueKey(
                                        'simulation_product_$_selectedProduct',
                                      ),
                                      initialValue: _selectedProduct,
                                      isExpanded: true,
                                      decoration: larasEntryDecoration(),
                                      items: [
                                        const DropdownMenuItem(
                                          value: -1,
                                          child: Text('Produk baru / manual'),
                                        ),
                                        for (var i = 0;
                                            i < _products.length;
                                            i++)
                                          DropdownMenuItem(
                                            value: i,
                                            child: Text(
                                              '${_products[i]['name']}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                      onChanged: (i) {
                                        if (i == null) return;
                                        setState(() {
                                          _selectedProduct = i;
                                          if (i >= 0) {
                                            _selectProduct(_products[i]);
                                          } else {
                                            _name.clear();
                                            _price.text = '0';
                                            _cost = SimulationCost();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                LarasLabeledField(
                                  label: 'Nama simulasi / produk',
                                  child: TextFormField(
                                    key: const Key('simulation_name'),
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: larasEntryDecoration(
                                      hint: 'Contoh: Batik Kawung · harga baru',
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Isi nama simulasi.'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _result(),
                                const SizedBox(height: 20),
                                LarasFormSection(
                                  title: 'Atur harga & jumlah',
                                  filled: true,
                                  children: [
                                    LarasLabeledField(
                                      label: 'Harga jual per produk',
                                      child: TextFormField(
                                        key: const Key('simulation_price'),
                                        controller: _price,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration:
                                            larasEntryDecoration(prefix: 'Rp'),
                                        validator: (_) => _validPrice == null
                                            ? 'Isi Rp0 sampai Rp10.000.000.'
                                            : null,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    if (_validPrice != null && _cost.isDefined)
                                      _inlineResult(),
                                    Column(
                                      children: [
                                        Slider(
                                          key: const Key('simulation_slider'),
                                          min: 0,
                                          max: PriceSimulation.maxPrice
                                              .toDouble(),
                                          value: (_validPrice ?? 0).toDouble(),
                                          label: LarasDesign.money(
                                              _validPrice ?? 0),
                                          semanticFormatterCallback: (v) =>
                                              '${LarasDesign.money(v)} per produk',
                                          onChanged: (v) => setState(
                                            () => _price.text = '${v.round()}',
                                          ),
                                        ),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Rp0',
                                                style: TextStyle(fontSize: 12)),
                                            Text(
                                              'Rp10 juta',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    LarasLabeledField(
                                      label: 'Jumlah produk yang dijual',
                                      child: TextFormField(
                                        key: const Key('simulation_quantity'),
                                        controller: _quantity,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: larasEntryDecoration(
                                          hint: 'Minimal 1 produk',
                                        ),
                                        validator: (_) => _validQuantity == null
                                            ? 'Isi 1 sampai 1.000.000 produk.'
                                            : null,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.layers_outlined,
                                              color:
                                                  LarasDesign.accent(context),
                                            ),
                                            const SizedBox(width: 10),
                                            const Expanded(
                                              child: Text(
                                                'Biaya produksi',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _cost.isDefined
                                              ? '${LarasDesign.money(_cost.total)} / produk'
                                              : 'Tentukan modalmu',
                                          key: const Key('simulation_hpp'),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _cost.isDefined
                                              ? '${_cost.materials.length} bahan / modal · termasuk tenaga kerja dan biaya lainnya'
                                              : 'Pilih bahan dari supplier atau masukkan modal secara manual.',
                                          style: TextStyle(
                                            color:
                                                LarasDesign.secondary(context),
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            key: const Key(
                                                'simulation_edit_cost'),
                                            onPressed: _editCost,
                                            icon: const Icon(
                                              Icons.tune_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              _cost.isDefined
                                                  ? 'Ubah rincian biaya'
                                                  : 'Atur biaya produksi',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  key: const Key('simulation_save'),
                                  onPressed:
                                      _saving || _count >= 10 ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.bookmark_add_outlined,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _saving ? 'Menyimpan…' : 'Simpan simulasi',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _saved,
                                  child: Text('Lihat simpanan · $_count/10'),
                                ),
                                if (_count >= 10)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'Simpanan penuh. Hapus satu simulasi untuk menambah yang baru.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Text(
                                  LarasApi.enabled
                                      ? 'Perkiraan ini mengasumsikan semua produk terjual. Simulasi disimpan di server akunmu dan tidak mengubah harga produk, stok, atau transaksi.'
                                      : 'Perkiraan ini mengasumsikan semua produk terjual. Simulasi tersimpan di perangkat/browser ini dan tidak mengubah harga produk, stok, atau transaksi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: LarasDesign.secondary(context),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      );

  Widget _inlineResult() {
    final profit = _validPrice! - _cost.total;
    final status = profit > 0
        ? 'Untung'
        : profit < 0
            ? 'Rugi'
            : 'Impas';
    final margin = _validPrice == 0
        ? '—'
        : '${(profit * 100 / _validPrice!).toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: profit < 0
            ? Theme.of(context).colorScheme.errorContainer
            : LarasDesign.soft(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$status ${LarasDesign.money(profit.abs())} / produk\nMargin $margin',
        key: const Key('simulation_live_price'),
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          fontWeight: FontWeight.w500,
          color: profit < 0
              ? Theme.of(context).colorScheme.onErrorContainer
              : LarasDesign.accent(context),
        ),
      ),
    );
  }

  Widget _result() {
    final valid =
        _validPrice != null && _validQuantity != null && _cost.isDefined;
    final profit = (_validPrice ?? 0) - _cost.total;
    final label = profit > 0
        ? 'Untung'
        : profit < 0
            ? 'Rugi'
            : 'Impas';
    final margin = _validPrice == null || _validPrice == 0
        ? '—'
        : '${(profit * 100 / _validPrice!).toStringAsFixed(1)}%';
    final loss = valid && profit < 0;
    return Container(
      key: const Key('simulation_result'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: loss
            ? const LinearGradient(
                colors: [Color(0xFF913C30), Color(0xFF652C28)],
              )
            : LarasDesign.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          height: 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  !valid
                      ? Icons.insights_outlined
                      : profit > 0
                          ? Icons.trending_up_rounded
                          : profit < 0
                              ? Icons.trending_down_rounded
                              : Icons.balance_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                Text(
                  valid ? 'Perkiraan $label per produk' : 'Perkiraan hasil',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valid ? LarasDesign.money(profit.abs()) : 'Siap mencoba?',
              key: const Key('simulation_profit'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            if (valid) ...[
              Text(
                'Margin $margin',
                key: const Key('simulation_margin'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0x55FFFFFF), height: 1),
              ),
              Text('$label total · $_validQuantity produk'),
              const SizedBox(height: 4),
              Text(
                LarasDesign.money((profit * _validQuantity!).abs()),
                key: const Key('simulation_total_profit'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_validPrice == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Margin tidak dihitung saat harga jual Rp0.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ] else
              Text(
                !_cost.isDefined
                    ? 'Atur biaya produksi untuk melihat untung, rugi, dan margin.'
                    : 'Perbaiki harga atau jumlah produk untuk melihat hasilnya.',
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

class SavedPriceSimulationsPage extends StatefulWidget {
  const SavedPriceSimulationsPage({super.key});
  @override
  State<SavedPriceSimulationsPage> createState() =>
      _SavedPriceSimulationsPageState();
}

class _SavedPriceSimulationsPageState extends State<SavedPriceSimulationsPage> {
  final _repo = PriceSimulationRepository();
  List<PriceSimulation> _values = [];
  bool _loading = true, _error = false, _deleting = false;
  String _readError =
      'Simpanan belum bisa dibaca. Data yang ada tetap tersimpan.';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final values = await _repo.read();
      if (mounted) {
        setState(() {
          _values = values;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readError = e is LarasApiException
              ? e.message
              : 'Simpanan belum bisa dibaca. Data yang ada tetap tersimpan.';
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _delete(PriceSimulation value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        title: const Text('Hapus simulasi?'),
        content: Text('“${value.name}” akan dihapus dari simpanan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _repo.delete(value.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Simulasi belum terhapus. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Simulasi tersimpan')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          '${_values.length} dari 10 simpanan',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buka untuk mencoba lagi. Biaya bahan mengikuti salinan saat simulasi disimpan.',
                          style: TextStyle(
                            color: LarasDesign.secondary(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error) ...[
                          Text(_readError),
                          OutlinedButton(
                            onPressed: _load,
                            child: const Text('Coba lagi'),
                          ),
                        ] else if (_values.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bookmarks_outlined,
                                  size: 48,
                                  color: LarasDesign.accent(context),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Belum ada simulasi tersimpan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Coba harga dan simpan skenario pertamamu.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        for (final value in _values)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${value.savedAt.day}/${value.savedAt.month}/${value.savedAt.year} · ${value.quantity} produk',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: LarasDesign.secondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Harga jual ${LarasDesign.money(value.price)}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Biaya ${LarasDesign.money(value.cost.total)} / produk',
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${value.totalProfit > 0 ? 'Untung' : value.totalProfit < 0 ? 'Rugi' : 'Impas'} total ${LarasDesign.money(value.totalProfit.abs())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: value.totalProfit < 0
                                          ? Theme.of(context).colorScheme.error
                                          : LarasDesign.accent(context),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _deleting
                                            ? null
                                            : () =>
                                                Navigator.pop(context, value),
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          size: 18,
                                        ),
                                        label: const Text('Buka simulasi'),
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus simulasi ${value.name}',
                                        onPressed: _deleting
                                            ? null
                                            : () => _delete(value),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      );
}
