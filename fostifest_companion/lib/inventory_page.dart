import 'dart:convert';

import 'package:flutter/material.dart';

import 'laras_design.dart';
import 'laras_fintech_widgets.dart';
import 'laras_components.dart';
import 'laras_forms.dart';

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
      if (mounted) {
        setState(
          () => products =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data produk tidak dapat dibaca.')),
        );
      }
    }
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    if (!await p.setString('laras_products_v1', jsonEncode(products))) {
      throw StateError('Gagal menyimpan produk');
    }
  }

  Future<void> edit([int? index]) async {
    final item = index == null ? null : products[index];
    final name = TextEditingController(text: item?['name'] as String? ?? '');
    final sku = TextEditingController(text: item?['sku'] as String? ?? '');
    final category = TextEditingController(
      text: item?['category'] as String? ?? '',
    );
    final price = TextEditingController(
      text: item == null ? '' : '${item['price']}',
    );
    final cost = TextEditingController(
      text: item == null ? '' : '${item['cost']}',
    );
    final stock = TextEditingController(
      text: item == null ? '' : '${item['stock']}',
    );
    final min = TextEditingController(
      text: item == null ? '0' : '${item['min']}',
    );
    final form = GlobalKey<FormState>();
    final result = await showLarasFormDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => LarasFormDialog(
        title: index == null ? 'Tambah produk' : 'Edit produk',
        description: 'Lengkapi informasi, harga, dan stok produk.',
        icon: Icons.inventory_2_outlined,
        body: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LarasFormSection(
                title: 'Identitas produk',
                children: [
                  LarasLabeledField(
                    label: 'Nama produk',
                    child: TextFormField(
                      key: const Key('product_name'),
                      controller: name,
                      decoration: larasEntryDecoration(
                        hint: 'Contoh: Batik motif Sekar',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Isi nama produk'
                          : null,
                    ),
                  ),
                  LarasLabeledField(
                    label: 'SKU',
                    optional: true,
                    child: TextFormField(
                      key: const Key('product_sku'),
                      controller: sku,
                      decoration: larasEntryDecoration(hint: 'Contoh: BTK-001'),
                      validator: (v) {
                        final code = v?.trim() ?? '';
                        if (code.isEmpty) return null;
                        for (var i = 0; i < products.length; i++) {
                          if (i != index &&
                              (products[i]['sku'] as String? ?? '') == code) {
                            return 'Kode sudah digunakan';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  LarasLabeledField(
                    label: 'Kategori',
                    optional: true,
                    child: TextFormField(
                      key: const Key('product_category'),
                      controller: category,
                      decoration: larasEntryDecoration(
                        hint: 'Contoh: Kain batik',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: LarasDesign.line(ctx)),
              const SizedBox(height: 16),
              LarasFormSection(
                title: 'Harga produk',
                children: [
                  LarasAdaptivePair(
                    children: [
                      for (final field in [
                        (price, 'Harga jual', 'product_price'),
                        (cost, 'Harga modal', 'product_cost'),
                      ])
                        LarasLabeledField(
                          label: field.$2,
                          child: TextFormField(
                            key: Key(field.$3),
                            controller: field.$1,
                            keyboardType: TextInputType.number,
                            decoration: larasEntryDecoration(
                              hint: '0',
                              prefix: 'Rp ',
                            ),
                            validator: (v) => int.tryParse(v ?? '') == null ||
                                    int.parse(v!) < 0
                                ? 'Isi angka nol atau lebih'
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              LarasFormSection(
                title: 'Persediaan',
                children: [
                  LarasAdaptivePair(
                    children: [
                      for (final field in [
                        (stock, 'Stok', 'product_stock'),
                        (min, 'Batas stok menipis', 'product_min'),
                      ])
                        LarasLabeledField(
                          label: field.$2,
                          child: TextFormField(
                            key: Key(field.$3),
                            controller: field.$1,
                            keyboardType: TextInputType.number,
                            decoration: larasEntryDecoration(hint: '0'),
                            validator: (v) => int.tryParse(v ?? '') == null ||
                                    int.parse(v!) < 0
                                ? 'Isi angka nol atau lebih'
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        onCancel: () => Navigator.pop(ctx),
        onSave: () {
          if (form.currentState!.validate()) {
            Navigator.pop(ctx, {
              'name': name.text.trim(),
              'sku': sku.text.trim(),
              'category': category.text.trim(),
              'price': int.parse(price.text),
              'cost': int.parse(cost.text),
              'stock': int.parse(stock.text),
              'min': int.parse(min.text),
            });
          }
        },
      ),
    );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk gagal disimpan.')),
          );
        }
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
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => products.removeAt(index));
    try {
      await persist();
    } catch (_) {
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produk gagal dihapus.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Produk dan stok')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => edit(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah produk'),
        ),
        body: products.isEmpty
            ? const Center(
                child: Text('Belum ada produk. Tambahkan produk pertama.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  final low = (p['stock'] as int) <= (p['min'] as int);
                  return LarasInventoryCard(
                    name: p['name'] as String,
                    price: LarasDesign.money(p['price'] as num),
                    cost: LarasDesign.money(p['cost'] as num),
                    stock: '${p['stock']}',
                    low: low,
                    onEdit: () => edit(index),
                    onDelete: () => remove(index),
                  );
                },
              ),
      );
}
