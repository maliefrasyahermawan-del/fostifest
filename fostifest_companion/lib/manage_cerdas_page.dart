import 'package:flutter/material.dart';

import 'laras_design.dart';
import 'laras_fintech_widgets.dart';

class ManageCerdasPage extends StatelessWidget {
  const ManageCerdasPage({super.key, required this.onOpen});
  final ValueChanged<String> onOpen;
  static const _groups =
      <(String, String, IconData, List<(String, String, IconData)>)>[
    (
      'Kelola Usaha',
      'Semua yang kamu perlukan, setiap hari.',
      Icons.storefront_outlined,
      [
        ('keuangan', 'Keuangan', Icons.account_balance_wallet_outlined),
        ('pelanggan', 'Pelanggan', Icons.groups_2_outlined),
        ('produk', 'Produk & Stok', Icons.inventory_2_outlined),
      ],
    ),
    (
      'Pasokan & Harga',
      'Jaga pasokan. Temukan harga yang pas.',
      Icons.trending_up_rounded,
      [
        ('supplier', 'Supplier', Icons.local_shipping_outlined),
        ('margin', 'Harga & Margin', Icons.price_change_outlined),
        ('simulasi', 'Simulasi Harga', Icons.tune_rounded),
        ('laporan', 'Laporan', Icons.bar_chart_rounded),
      ],
    ),
    (
      'Catatan & Administrasi',
      'Biar catatan dan dokumen tetap rapi.',
      Icons.task_alt_rounded,
      [
        ('catat', 'Catat Transaksi', Icons.edit_note_rounded),
        ('legalitas', 'Legalitas', Icons.verified_user_outlined),
        ('asisten', 'Asisten Laras', Icons.auto_awesome_outlined),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('manage_cerdas_page'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Semua kebutuhan usaha,\ndalam satu tempat.',
            style: TextStyle(
              fontSize: 24,
              height: 1.35,
              letterSpacing: -.5,
              fontWeight: FontWeight.w600,
              color: LarasDesign.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih yang ingin kamu kelola hari ini.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: LarasDesign.secondary(context),
            ),
          ),
          for (var i = 0; i < _groups.length; i++) ...[
            const SizedBox(height: 28),
            Text(
              _groups[i].$1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LarasDesign.text(context),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _groups[i].$2,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: LarasDesign.secondary(context),
              ),
            ),
            const SizedBox(height: 14),
            LarasShortcutGrid(
              children: [
                for (var j = 0; j < _groups[i].$4.length; j++)
                  LarasQuickAction(
                    key: Key('manage_${_groups[i].$4[j].$1}'),
                    label: _groups[i].$4[j].$2,
                    icon: _groups[i].$4[j].$3,
                    tone: i + j,
                    onTap: () => onOpen(_groups[i].$4[j].$1),
                  ),
              ],
            ),
          ],
        ],
      );
}
