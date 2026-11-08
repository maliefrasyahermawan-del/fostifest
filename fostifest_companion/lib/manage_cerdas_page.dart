import 'package:flutter/material.dart';

/// Layar tab tengah: kumpulan ikon fitur manajemen operasi usaha.
class ManageCerdasPage extends StatelessWidget {
  const ManageCerdasPage({super.key, required this.onOpen});
  final ValueChanged<String> onOpen;

  static const _ink = Color(0xFF123126);
  static const _muted = Color(0xFF5F766C);

  static const _groups = <(String, String, List<(String, String, IconData)>)>[
    (
      'Kelola Usaha',
      'Operasional harian usaha batikmu',
      [
        ('keuangan', 'Keuangan', Icons.account_balance_wallet_outlined),
        ('pelanggan', 'Pelanggan', Icons.groups_2_outlined),
        ('produk', 'Produk & Stok', Icons.inventory_2_outlined),
      ]
    ),
    (
      'Pasokan & Harga',
      'Bahan baku, modal, dan margin produk',
      [
        ('supplier', 'Supplier', Icons.local_shipping_outlined),
        ('margin', 'Harga & Margin', Icons.price_change_outlined),
        ('simulasi_harga', 'Simulasi Harga', Icons.tune_rounded),
        ('laporan', 'Laporan', Icons.bar_chart_rounded),
      ]
    ),
    (
      'Catatan & Administrasi',
      'Catat transaksi dan rapikan dokumen',
      [
        ('catat', 'Catat Transaksi', Icons.edit_note_rounded),
        ('legalitas', 'Legalitas', Icons.verified_user_outlined),
        ('asisten', 'Asisten Laras', Icons.auto_awesome_outlined),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('manage_cerdas_page'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          for (final group in _groups) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE9E2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.$1,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Text(group.$2,
                        style: const TextStyle(fontSize: 12, color: _muted)),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: group.$3.length == 4 ? 4 : 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 4,
                      childAspectRatio: group.$3.length == 4 ? .75 : 1.05,
                      children: [
                        for (final item in group.$3)
                          InkWell(
                            key: Key('manage_${item.$1}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onOpen(item.$1),
                            child: Column(children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1FB36F),
                                          Color(0xFF45C98E)
                                        ]),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Icon(item.$3,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 6),
                              Text(item.$2,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                            ]),
                          ),
                      ],
                    ),
                  ]),
            ),
          ],
        ],
      );
}
