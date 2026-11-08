import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Map<String, dynamic>> products = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(p.getString('laras_products_v1') ?? '[]') as List;
      if (mounted)
        setState(() => products =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data produk tidak dapat dibaca.')));
    }
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (!await p.setString('laras_products_v1', jsonEncode(products)))
      throw StateError('Gagal menyimpan produk');
  }

  Future<void> edit([int? index]) async {
    final item = index == null ? null : products[index];
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final sku = TextEditingController(text: item?['sku'] as String? ?? '');
    final category =
        TextEditingController(text: item?['category'] as String? ?? '');
    final price =
        TextEditingController(text: item == null ? '' : '${item['price']}');
    final cost =
        TextEditingController(text: item == null ? '' : '${item['cost']}');
    final stock =
        TextEditingController(text: item == null ? '' : '${item['stock']}');
    final min =
        TextEditingController(text: item == null ? '0' : '${item['min']}');
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(index == null ? 'Tambah produk' : 'Edit produk'),
              content: Form(
                  key: form,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Nama produk'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Isi nama produk'
                            : null),
                    TextFormField(
                        controller: sku,
                        decoration:
                            const InputDecoration(labelText: 'SKU (opsional)'),
                        validator: (v) {
                          final code = v?.trim() ?? '';
                          if (code.isEmpty) return null;
                          for (var i = 0; i < products.length; i++) {
                            if (i != index &&
                                (products[i]['sku'] as String? ?? '') == code)
                              return 'Kode sudah digunakan';
                          }
                          return null;
                        }),
                    TextFormField(
                        controller: category,
                        decoration: const InputDecoration(
                            labelText: 'Kategori (opsional)')),
                    for (final field in [
                      (price, 'Harga jual'),
                      (cost, 'Harga modal'),
                      (stock, 'Stok'),
                      (min, 'Batas stok menipis')
                    ])
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextFormField(
                              controller: field.$1,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: field.$2),
                              validator: (v) => int.tryParse(v ?? '') == null ||
                                      int.parse(v!) < 0
                                  ? 'Isi angka nol atau lebih'
                                  : null)),
                  ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate())
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
                    child: const Text('Simpan'))
              ],
            ));
    if (result != null && mounted) {
      setState(() {
        if (index == null) {
          products.add(result);
        } else {
          products[index] = result;
        }
      });
      try {
        await persist();
      } catch (_) {
        await load();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk gagal disimpan.')));
      }
    }
    name.dispose();
    sku.dispose();
    category.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    min.dispose();
  }

  Future<void> remove(int index) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Hapus produk?'),
                content: Text(products[index]['name'] as String),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => products.removeAt(index));
    try {
      await persist();
    } catch (_) {
      await load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk gagal dihapus.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Produk dan stok')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah produk')),
        body: products.isEmpty
            ? const Center(
                child: Text('Belum ada produk. Tambahkan produk pertama.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  final low = (p['stock'] as int) <= (p['min'] as int);
                  return Card(
                      child: ListTile(
                    title: Text(p['name'] as String),
                    subtitle: Text(
                        'Jual Rp${p['price']} · Modal Rp${p['cost']}\nStok ${p['stock']}${low ? ' · Stok menipis' : ''}'),
                    isThreeLine: true,
                    onTap: () => edit(index),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus produk',
                        onPressed: () => remove(index)),
                  ));
                },
              ),
      );
}
