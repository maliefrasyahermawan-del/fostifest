import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'laras_design.dart';
import 'laras_forms.dart';
import 'price_simulation.dart';

class SimulationCostPage extends StatefulWidget {
  const SimulationCostPage({
    super.key,
    required this.cost,
    required this.materials,
    required this.suppliers,
  });
  final SimulationCost cost;
  final List<Map<String, dynamic>> materials, suppliers;
  @override
  State<SimulationCostPage> createState() => _SimulationCostPageState();
}

class _SimulationCostPageState extends State<SimulationCostPage> {
  final _form = GlobalKey<FormState>();
  late final List<SimulationMaterial> _lines = [...widget.cost.materials];
  late final _labor = TextEditingController(text: '${widget.cost.labor}');
  late final _overhead = TextEditingController(text: '${widget.cost.overhead}');
  @override
  void dispose() {
    _labor.dispose();
    _overhead.dispose();
    super.dispose();
  }

  int get _total => (_lines.fold(0.0, (sum, m) => sum + m.subtotal) +
          (int.tryParse(_labor.text) ?? 0) +
          (int.tryParse(_overhead.text) ?? 0))
      .round();
  Future<void> _edit([int? index]) async {
    final line = await Navigator.push<SimulationMaterial>(
      context,
      MaterialPageRoute(
        builder: (_) => _SimulationMaterialPage(
          initial: index == null ? null : _lines[index],
          materials: widget.materials,
          suppliers: widget.suppliers,
        ),
      ),
    );
    if (line != null && mounted) {
      setState(() {
        if (index == null) {
          _lines.add(line);
        } else {
          _lines[index] = line;
        }
      });
    }
  }

  void _apply() {
    if (!_form.currentState!.validate()) return;
    try {
      final cost = SimulationCost(
        materials: _lines,
        labor: int.parse(_labor.text),
        overhead: int.parse(_overhead.text),
      );
      if (!cost.isDefined) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tambahkan bahan atau isi biaya produksi terlebih dahulu.',
            ),
          ),
        );
        return;
      }
      Navigator.pop(context, cost);
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total biaya maksimal Rp1 miliar per produk.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Biaya produksi')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Hitung untuk 1 produk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih bahan dari supplier atau masukkan sendiri. Semua biaya di halaman ini dihitung per produk.',
                        style: TextStyle(
                          color: LarasDesign.secondary(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: LarasDesign.soft(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total biaya per produk'),
                            const SizedBox(height: 6),
                            Text(
                              LarasDesign.money(_total),
                              key: const Key('simulation_cost_total'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: LarasDesign.accent(context),
                              ),
                            ),
                            const Text(
                              'Bahan + tenaga kerja + biaya lainnya',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Bahan & modal',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (_lines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Belum ada bahan. Kamu juga bisa memasukkan total modal secara manual.',
                            style: TextStyle(
                                color: LarasDesign.secondary(context)),
                          ),
                        ),
                      for (var i = 0; i < _lines.length; i++)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lines[i].name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _lines[i].supplierName ?? 'Input manual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LarasDesign.secondary(context),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_lines[i].quantity} ${_lines[i].unit} × ${LarasDesign.money(_lines[i].unitPrice)}',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      LarasDesign.money(_lines[i].subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _edit(i),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Ubah'),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus bahan ${_lines[i].name}',
                                      onPressed: () =>
                                          setState(() => _lines.removeAt(i)),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        key: const Key('simulation_add_material'),
                        onPressed: _edit,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah bahan / modal'),
                      ),
                      const SizedBox(height: 28),
                      LarasFormSection(
                        title: 'Biaya tambahan per produk',
                        filled: true,
                        children: [
                          _numberField(
                              'Tenaga kerja', 'simulation_labor', _labor),
                          _numberField(
                            'Biaya lainnya',
                            'simulation_overhead',
                            _overhead,
                          ),
                          Text(
                            'Contoh biaya lainnya: listrik, kemasan, dan transportasi yang dialokasikan untuk 1 produk.',
                            style: TextStyle(
                              fontSize: 12,
                              color: LarasDesign.secondary(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('simulation_apply_cost'),
                        onPressed: _apply,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Gunakan biaya ini'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Perubahan berlaku setelah kamu menekan “Gunakan biaya ini”.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.5),
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
  Widget _numberField(
    String label,
    String key,
    TextEditingController controller,
  ) =>
      LarasLabeledField(
        label: label,
        child: TextFormField(
          key: Key(key),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: larasEntryDecoration(prefix: 'Rp'),
          validator: simulationCostValidator,
          onChanged: (_) => setState(() {}),
        ),
      );
}

String? simulationCostValidator(String? value) {
  final amount = int.tryParse(value ?? '');
  return amount == null || amount < 0 || amount > 1000000000
      ? 'Isi Rp0 sampai Rp1 miliar.'
      : null;
}

class _SimulationMaterialPage extends StatefulWidget {
  const _SimulationMaterialPage({
    this.initial,
    required this.materials,
    required this.suppliers,
  });
  final SimulationMaterial? initial;
  final List<Map<String, dynamic>> materials, suppliers;
  @override
  State<_SimulationMaterialPage> createState() =>
      _SimulationMaterialPageState();
}

class _SimulationMaterialPageState extends State<_SimulationMaterialPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _unit = TextEditingController(text: widget.initial?.unit ?? 'pcs');
  late final _quantity = TextEditingController(
    text: '${widget.initial?.quantity ?? 1}',
  );
  late final _price = TextEditingController(
    text: '${widget.initial?.unitPrice ?? 0}',
  );
  String? _supplierId, _materialId;
  bool _supplierMode = false;
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null &&
        widget.materials.any((m) => m['id'] == initial.materialId) &&
        widget.suppliers.any((s) => s['id'] == initial.supplierId)) {
      _supplierMode = true;
      _supplierId = initial.supplierId;
      _materialId = initial.materialId;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _unit, _quantity, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    try {
      final supplier = widget.suppliers.where((s) => s['id'] == _supplierId);
      Navigator.pop(
        context,
        SimulationMaterial(
          name: _name.text.trim(),
          unit: _unit.text.trim(),
          quantity: double.parse(_quantity.text.replaceAll(',', '.')),
          unitPrice: int.parse(_price.text),
          materialId: _supplierMode ? _materialId : null,
          supplierId: _supplierMode ? _supplierId : null,
          supplierName: _supplierMode && supplier.isNotEmpty
              ? '${supplier.first['name']}'
              : null,
        ),
      );
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subtotal bahan maksimal Rp1 miliar per produk.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials =
        widget.materials.where((m) => m['supplierId'] == _supplierId).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null
              ? 'Tambah bahan / modal'
              : 'Ubah bahan / modal',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sumber biaya',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Input manual'),
                          selected: !_supplierMode,
                          onSelected: (_) =>
                              setState(() => _supplierMode = false),
                        ),
                        ChoiceChip(
                          key: const Key('simulation_source_supplier'),
                          label: const Text('Dari supplier'),
                          selected: _supplierMode,
                          onSelected: (_) =>
                              setState(() => _supplierMode = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_supplierMode) ...[
                      if (widget.suppliers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Belum ada supplier. Tambahkan melalui menu Supplier atau gunakan input manual.',
                          ),
                        ),
                      LarasLabeledField(
                        label: 'Supplier',
                        child: DropdownButtonFormField<String>(
                          key: const Key('simulation_supplier'),
                          initialValue: _supplierId,
                          isExpanded: true,
                          decoration: larasEntryDecoration(
                            hint: 'Pilih supplier',
                          ),
                          items: widget.suppliers
                              .map(
                                (s) => DropdownMenuItem(
                                  value: '${s['id']}',
                                  child: Text(
                                    '${s['name']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (v) => v == null
                              ? 'Pilih supplier terlebih dahulu.'
                              : null,
                          onChanged: (v) => setState(() {
                            _supplierId = v;
                            _materialId = null;
                            _name.clear();
                            _unit.text = 'pcs';
                            _price.text = '0';
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LarasLabeledField(
                        label: 'Bahan supplier',
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('simulation_material_$_supplierId'),
                          initialValue: _materialId,
                          isExpanded: true,
                          decoration: larasEntryDecoration(hint: 'Pilih bahan'),
                          items: materials
                              .map(
                                (m) => DropdownMenuItem(
                                  value: '${m['id']}',
                                  child: Text(
                                    '${m['name']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (v) => v == null
                              ? 'Pilih bahan dari supplier ini.'
                              : null,
                          onChanged: (v) => setState(() {
                            _materialId = v;
                            final material = materials.firstWhere(
                              (m) => m['id'] == v,
                            );
                            _name.text = '${material['name']}';
                            _unit.text = '${material['unit']}';
                            _price.text =
                                '${(material['pricePerUnit'] as num).round()}';
                          }),
                        ),
                      ),
                      if (_supplierId != null && materials.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Supplier ini belum memiliki bahan. Gunakan input manual atau tambah bahan di menu Supplier.',
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                    LarasLabeledField(
                      label: 'Nama bahan / modal',
                      child: TextFormField(
                        key: const Key('simulation_material_name'),
                        controller: _name,
                        readOnly: _supplierMode,
                        decoration: larasEntryDecoration(
                          hint: 'Contoh: kain mori atau modal produksi',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Isi nama bahan / modal.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LarasLabeledField(
                      label: 'Jumlah untuk 1 produk',
                      child: TextFormField(
                        key: const Key('simulation_material_quantity'),
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (old, next) => RegExp(r'^\d*([.,]\d{0,4})?$')
                                    .hasMatch(next.text)
                                ? next
                                : old,
                          ),
                        ],
                        decoration: larasEntryDecoration(hint: 'Contoh: 2,3'),
                        validator: (v) {
                          final q = double.tryParse(
                            (v ?? '').replaceAll(',', '.'),
                          );
                          return q == null ||
                                  !q.isFinite ||
                                  q <= 0 ||
                                  q > 1000000
                              ? 'Isi jumlah di atas 0, maksimal 1 juta.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    LarasLabeledField(
                      label: 'Satuan bahan',
                      child: TextFormField(
                        key: const Key('simulation_material_unit'),
                        controller: _unit,
                        readOnly: _supplierMode,
                        decoration: larasEntryDecoration(
                          hint: 'Contoh: meter, kg, pcs',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Isi satuan bahan.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LarasLabeledField(
                      label: 'Harga per satuan bahan',
                      child: TextFormField(
                        key: const Key('simulation_material_price'),
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: larasEntryDecoration(prefix: 'Rp'),
                        validator: simulationCostValidator,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _supplierMode
                          ? 'Harga supplier terisi otomatis. Kamu boleh mencoba nominal lain di simulasi ini.'
                          : 'Untuk total modal manual, isi jumlah 1 dan masukkan nominal modal per produk.',
                      style: TextStyle(
                        color: LarasDesign.secondary(context),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      key: const Key('simulation_apply_material'),
                      onPressed: _save,
                      child: const Text('Gunakan bahan ini'),
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
  }
}
