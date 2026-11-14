import 'package:flutter/material.dart';

import 'laras_operations_page.dart';
import 'supplier_page.dart';

class ProductMargin {
  ProductMargin(this.product, this.unitsSold);
  final Map<String, dynamic> product;
  final int unitsSold;
  String get name => '${product['name']}';
  int get price => (product['price'] as num? ?? 0).round();
  int get cost => (product['cost'] as num? ?? 0).round();
  int get margin => price - cost;
  double get marginPercent => price <= 0 ? 0 : margin * 100 / price;
}

class MarginBadge extends StatelessWidget {
  const MarginBadge({super.key, required this.percent});
  final double percent;
  @override
  Widget build(BuildContext context) {
    final good = percent >= 40, ok = percent >= 30;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: good
                ? const Color(0xFFD6F5E4)
                : ok
                    ? const Color(0xFFEAF7EE)
                    : const Color(0xFFFFF1D6),
            borderRadius: BorderRadius.circular(12)),
        child: Text('${percent.toStringAsFixed(0)}%',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color:
                    ok ? const Color(0xFF35A565) : const Color(0xFF8A5A00))));
  }
}

/// Detail margin satu produk: penyebab margin dan pengaturan harga.
class ProductMarginPage extends StatefulWidget {
  const ProductMarginPage(
      {super.key,
      required this.product,
      required this.unitsSold,
      required this.averageMargin});
  final Map<String, dynamic> product;
  final int unitsSold;
  final double averageMargin;
  @override
  State<ProductMarginPage> createState() => _ProductMarginPageState();
}

class _ProductMarginPageState extends State<ProductMarginPage> {
  static const _ink = Color(0xFF123126);
  final _repo = LarasLocalRepository();
  late final TextEditingController _price;
  late int _savedPrice;
  bool _saving = false;
  int get _cost => (widget.product['cost'] as num? ?? 0).round();
  int get _draft => int.tryParse(_price.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _savedPrice = (widget.product['price'] as num? ?? 0).round();
    _price = TextEditingController(text: '$_savedPrice');
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  double _percent(int price) => price <= 0 ? 0 : (price - _cost) * 100 / price;

  /// Harga yang menghasilkan margin target, dibulatkan ke atas per Rp1.000.
  int _priceForMargin(int target) =>
      ((_cost / (1 - target / 100)) / 1000).ceil() * 1000;

  Future<void> _apply() async {
    final price = _draft;
    if (price <= _cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harga jual harus lebih tinggi dari harga modal.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final all = await _repo.read(LarasLocalRepository.products);
      final i = all.indexWhere((e) =>
          e['name'] == widget.product['name'] &&
          e['sku'] == widget.product['sku']);
      if (i < 0) throw StateError('Produk tidak ditemukan.');
      all[i] = {...all[i], 'price': price};
      await _repo.write(LarasLocalRepository.products, all);
      if (!mounted) return;
      setState(() => _savedPrice = price);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harga jual diperbarui.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harga belum tersimpan. Coba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _reasons() {
    final price = _savedPrice, percent = _percent(price);
    final costShare = price <= 0 ? 0 : _cost * 100 / price;
    final stock = (widget.product['stock'] as num? ?? 0).round();
    final out = <String>[
      'Harga modal ${larasRupiah(_cost)} memakan ${costShare.toStringAsFixed(0)}% dari harga jual ${larasRupiah(price)}, sisanya ${percent.toStringAsFixed(0)}% menjadi margin.',
    ];
    final diff = percent - widget.averageMargin;
    final avg = widget.averageMargin.toStringAsFixed(0);
    out.add(diff.abs() < 3
        ? 'Margin ini setara rata-rata seluruh produk ($avg%).'
        : diff > 0
            ? 'Margin ${diff.toStringAsFixed(0)} poin di atas rata-rata produk ($avg%).'
            : 'Margin ${(-diff).toStringAsFixed(0)} poin di bawah rata-rata produk ($avg%), sehingga produk ini ikut menekan laba.');
    if (percent < 30) {
      out.add(
          'Margin di bawah 30%: pertimbangkan menaikkan harga jual atau menurunkan harga modal (negosiasi bahan atau upah).');
    }
    if (widget.unitsSold > 0) {
      out.add(
          'Terjual ${widget.unitsSold} unit selama 90 hari terakhir, menyumbang laba kotor sekitar ${larasRupiah((price - _cost) * widget.unitsSold)}.');
    } else {
      out.add('Belum ada penjualan tercatat untuk produk ini.');
    }
    final recipe = (widget.product['recipe'] as List?) ?? const [];
    if (widget.product['costMode'] == 'resep' && recipe.isNotEmpty) {
      Map<String, dynamic>? top;
      var topValue = -1.0;
      for (final l in recipe) {
        final v = ((l['unitPrice'] as num?) ?? 0) * ((l['qty'] as num?) ?? 0);
        if (v > topValue) {
          topValue = v.toDouble();
          top = Map<String, dynamic>.from(l as Map);
        }
      }
      if (top != null && _cost > 0) {
        out.add(
            'Modal dihitung dari resep. Bahan terbesar: ${top['name']} (${(topValue * 100 / _cost).toStringAsFixed(0)}% dari modal).');
      }
    }
    if (stock > 0) {
      out.add(
          'Stok $stock unit menahan modal sekitar ${larasRupiah(stock * _cost)}.');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final percent = _percent(_savedPrice);
    final draftPercent = _percent(_draft);
    return Scaffold(
      appBar: AppBar(
          title: Text('${widget.product['name']}',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Margin saat ini',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            Text('${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: _ink)),
            Text(
                'Untung ${larasRupiah(_savedPrice - _cost)} per unit · Harga jual ${larasRupiah(_savedPrice)} · Modal ${larasRupiah(_cost)}',
                style: const TextStyle(color: _ink)),
          ]),
        ),
        const SizedBox(height: 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
                height: 14,
                child: Row(children: [
                  Expanded(
                      flex: (100 - percent).clamp(1, 99).round(),
                      child: Container(color: const Color(0xFF9FB8AA))),
                  Expanded(
                      flex: percent.clamp(1, 99).round(),
                      child: Container(color: const Color(0xFF14935A))),
                ]))),
        const SizedBox(height: 6),
        const Row(children: [
          Icon(Icons.circle, size: 10, color: Color(0xFF9FB8AA)),
          SizedBox(width: 4),
          Text('Harga modal', style: TextStyle(fontSize: 12)),
          SizedBox(width: 14),
          Icon(Icons.circle, size: 10, color: Color(0xFF14935A)),
          SizedBox(width: 4),
          Text('Margin', style: TextStyle(fontSize: 12)),
        ]),
        const SizedBox(height: 20),
        const Text('Kenapa margin segini?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final r in _reasons())
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 5, right: 10),
                    child:
                        Icon(Icons.circle, size: 7, color: Color(0xFF35A565))),
                Expanded(child: Text(r, style: const TextStyle(height: 1.4))),
              ])),
        const SizedBox(height: 14),
        const Text('Atur harga jual',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Coba harga baru dan lihat margin barunya sebelum disimpan.',
            style: TextStyle(color: Color(0xFF5F766C))),
        const SizedBox(height: 10),
        TextField(
            key: const Key('price_field'),
            controller: _price,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Harga jual baru (Rp)', prefixText: 'Rp ')),
        const SizedBox(height: 8),
        Text(
            _draft <= _cost
                ? 'Harga harus di atas harga modal.'
                : 'Margin baru ${draftPercent.toStringAsFixed(1)}% · untung ${larasRupiah(_draft - _cost)} per unit',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final t in const [30, 40, 50])
            ActionChip(
                label: Text('Target margin $t%'),
                onPressed: () =>
                    setState(() => _price.text = '${_priceForMargin(t)}')),
        ]),
        const SizedBox(height: 14),
        FilledButton.icon(
            onPressed: _saving ? null : _apply,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Terapkan harga')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            key: const Key('open_recipe'),
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductRecipePage(product: widget.product)));
              if (changed == true && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.science_outlined),
            label: Text(widget.product['costMode'] == 'resep'
                ? 'Ubah resep & modal otomatis'
                : 'Hitung modal dari resep bahan')),
      ]),
    );
  }
}
