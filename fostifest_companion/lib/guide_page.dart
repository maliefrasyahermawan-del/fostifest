import 'package:flutter/material.dart';

const _yellow = Color(0xFF14935A);
const _ink = Color(0xFF123126);
const _gold = Color(0xFF0B5D3B);
const _muted = Color(0xFF5F766C);

/// Satu fitur: apa itu, untuk apa, dan cara memakainya.
class GuideFeature {
  const GuideFeature(this.icon, this.name, this.what, this.why, [this.how]);
  final IconData icon;
  final String name, what, why;
  final String? how;
}

class GuideSection {
  const GuideSection(this.icon, this.title, this.intro, this.features);
  final IconData icon;
  final String title, intro;
  final List<GuideFeature> features;
}

class GuideTerm {
  const GuideTerm(this.term, this.meaning, [this.example]);
  final String term, meaning;
  final String? example;
}

const guideSections = <GuideSection>[
  GuideSection(
      Icons.home_outlined,
      'Beranda',
      'Layar pertama. Isinya ringkasan usahamu supaya langsung tahu kondisinya.',
      [
        GuideFeature(
            Icons.speed_outlined,
            'Omzet bulan ini & estimasi laba',
            'Dua kartu di atas yang menampilkan total penjualan bulan ini dan perkiraan labanya.',
            'Biar sekali lihat kamu tahu usaha sedang naik atau turun.'),
        GuideFeature(
            Icons.add_circle_outline,
            'Catat transaksi sekarang',
            'Tombol cepat untuk mencatat penjualan baru.',
            'Mencatat di hari yang sama membuat semua laporan tetap akurat.'),
        GuideFeature(
            Icons.auto_awesome,
            'AI Insight',
            'Daftar saran untuk mengembangkan usaha, dibuat otomatis dari catatanmu: margin tipis, omzet turun, produk andalan, dan lainnya.',
            'Memberi ide langkah berikutnya tanpa kamu harus menganalisa sendiri.',
            'Saran dibuat dengan aturan di HP, bukan nasihat keuangan resmi.'),
        GuideFeature(
            Icons.show_chart_rounded,
            'Tren omzet & produk terlaris',
            'Grafik penjualan per periode (1 minggu sampai 3 bulan) dan lima produk paling laku.',
            'Melihat pola penjualan dan produk mana yang layak diprioritaskan.'),
        GuideFeature(
            Icons.verified_user_outlined,
            'Legalitas usaha',
            'Pintasan ke daftar dokumen usaha.',
            'Lihat bagian Catatan & Administrasi di bawah.'),
      ]),
  GuideSection(Icons.receipt_long_outlined, 'Catatan',
      'Tempat semua catatan uang usahamu. Punya tiga tab.', [
    GuideFeature(
        Icons.list_alt_outlined,
        'Transaksi',
        'Daftar penjualan yang sudah dicatat, per bulan.',
        'Memeriksa siapa membeli apa dan kapan.',
        'Geser bulan dengan panah kiri-kanan.'),
    GuideFeature(
        Icons.calendar_month_outlined,
        'Kalender',
        'Kalender yang menandai hari ada penjualan. Ketuk tanggal untuk melihat catatan hari itu.',
        'Melihat hari ramai dan hari sepi.'),
    GuideFeature(
        Icons.content_paste_go_outlined,
        'Tempel Chat',
        'Salin pesan pesanan dari WhatsApp atau Instagram, tempel, lalu LARAS membaca barang, jumlah, harga, nama pelanggan, dan status bayarnya. Kamu memeriksa dan memperbaiki hasilnya sebelum disimpan.',
        'Mencatat pesanan dalam hitungan detik tanpa mengetik ulang.',
        'Buka Catat transaksi lalu pilih Chat. Bagian bertanda "Periksa" perlu kamu cek. DP atau belum bayar otomatis masuk Utang & Piutang.'),
    GuideFeature(
        Icons.description_outlined,
        'Laporan',
        'Ringkasan Pengeluaran dan Laba Rugi untuk rentang tanggal pilihanmu (7 hari, 30 hari, 3 bulan, atau tanggal bebas). Bisa diunduh sebagai PDF.',
        'Bahan untuk evaluasi bulanan, mengajukan pinjaman, atau pelaporan pajak.',
        'Ketuk tombol tanggal lalu pilih tanggal awal dan akhir.'),
  ]),
  GuideSection(
      Icons.grid_view_rounded,
      'Manage Cerdas',
      'Tombol bulat kuning di tengah. Pusat semua fitur pengelolaan usaha, dikelompokkan per tujuan.',
      [
        GuideFeature(
            Icons.account_balance_wallet_outlined,
            'Keuangan',
            'Mencatat dan melihat uang masuk dan uang keluar beserta kategorinya.',
            'Dasar dari semua laporan: tanpa catatan, tidak ada analisa.'),
        GuideFeature(
            Icons.groups_2_outlined,
            'Pelanggan',
            'Daftar pelanggan dan kontaknya.',
            'Memudahkan menghubungi pelanggan lama untuk penawaran.'),
        GuideFeature(
            Icons.inventory_2_outlined,
            'Produk & Stok',
            'Daftar produk dengan harga modal, harga jual, jumlah stok, dan batas stok minimum.',
            'Tahu kapan harus produksi atau belanja bahan lagi.'),
        GuideFeature(
            Icons.swap_vert_rounded,
            'Manajemen Cashflow',
            'Analisa uang masuk dan keluar: ringkasan, grafik, kategori, tipe arus kas, struktur biaya, pengaruh harga bahan baku, simulasi "bagaimana jika", dan saran.',
            'Menjaga agar uang tunai usaha tidak seret, walau penjualan terlihat bagus.',
            'Coba geser slider simulasi untuk melihat efek harga bahan naik.'),
        GuideFeature(
            Icons.handshake_outlined,
            'Utang & Piutang',
            'Mencatat uang yang belum dibayar: pelanggan yang berutang padamu (piutang) dan belanja ke supplier yang belum kamu bayar (utang), lengkap dengan jatuh tempo.',
            'Supaya tidak ada tagihan yang terlupa dan tahu kapan uang akan masuk atau harus keluar.',
            'Tekan "Terima bayar" atau "Bayar"; pembayaran otomatis masuk ke catatan keuangan.'),
        GuideFeature(
            Icons.savings_outlined,
            'Titik Impas & Dana Cadangan',
            'Titik Impas: omzet minimal agar tidak rugi. Dana Cadangan: berapa lama usaha bertahan kalau penjualan berhenti, dan target dana daruratnya.',
            'Menentukan target penjualan yang realistis dan menyiapkan diri menghadapi masa sepi.',
            'Isi saldo kas dengan tombol pensil agar lama bertahan bisa dihitung.'),
        GuideFeature(
            Icons.local_shipping_outlined,
            'Supplier',
            'Daftar pemasok, bahan baku yang dijual, harganya, dan riwayat perubahan harga.',
            'Membandingkan harga dan menyadari kalau bahan baku mulai mahal.'),
        GuideFeature(
            Icons.price_change_outlined,
            'Harga & Margin',
            'Menghitung modal tiap produk dari bahan (resep) dan menunjukkan margin keuntungannya.',
            'Menentukan harga jual yang masih untung.'),
        GuideFeature(
            Icons.bar_chart_rounded,
            'Laporan',
            'Pintasan ke tab Laporan di Catatan.',
            'Membuka laporan laba rugi dengan cepat.'),
        GuideFeature(
            Icons.edit_note_rounded,
            'Catat Transaksi',
            'Formulir mencatat penjualan, manual atau dengan memotret struk.',
            'Memasukkan data baru dengan cepat.'),
        GuideFeature(
            Icons.verified_user_outlined,
            'Legalitas',
            'Daftar lengkap izin dan dokumen UMKM (NIB, NPWP, merek, halal, P-IRT, BPJS, pajak, dan lainnya). Tiap dokumen punya penjelasan, tempat mengurus, biaya, dan langkah-langkahnya.',
            'Tahu dokumen apa yang wajib, mana yang sudah beres, dan diingatkan bila masa berlaku hampir habis.',
            'Tandai status tiap dokumen. Yang tidak relevan untuk usahamu bisa ditandai "Tidak perlu".'),
        GuideFeature(
            Icons.auto_awesome_outlined,
            'Asisten Laras',
            'Obrolan untuk membahas penjualan, biaya, dan langkah berikutnya berdasarkan catatanmu.',
            'Teman berpikir saat bingung membaca angka usaha.'),
      ]),
  GuideSection(Icons.local_shipping_outlined, 'Supplier',
      'Tab khusus untuk pemasok dan bahan baku.', [
    GuideFeature(
        Icons.storefront_outlined,
        'Daftar supplier dan bahan',
        'Tambah supplier, isi bahan beserta harga per satuan. Setiap perubahan harga tersimpan sebagai riwayat.',
        'Bahan baku biasanya biaya terbesar. Mengawasi harganya menjaga laba.',
        'Ubah harga di sini, lalu lihat dampaknya di Cashflow dan Harga & Margin.'),
    GuideFeature(
        Icons.shopping_basket_outlined,
        'Catat pembelian bahan',
        'Pembelian ke supplier tercatat sebagai pengeluaran kategori Bahan baku.',
        'Biaya bahan otomatis masuk laporan, tanpa mencatat dua kali.'),
  ]),
  GuideSection(Icons.person_outline_rounded, 'Profil',
      'Pengaturan akun dan data usaha.', [
    GuideFeature(
        Icons.badge_outlined,
        'Data usaha',
        'Nama usaha, lokasi, dan kategori. Bisa diubah kapan saja.',
        'Muncul di beranda dan di laporan PDF.'),
    GuideFeature(
        Icons.privacy_tip_outlined,
        'Privasi dan data usaha',
        'Penjelasan data apa yang disimpan dan di mana.',
        'Supaya kamu tahu datamu aman dan tetap milikmu.'),
    GuideFeature(
        Icons.dark_mode_outlined,
        'Mode gelap',
        'Mengganti tampilan menjadi gelap.',
        'Lebih nyaman di mata saat malam hari.'),
  ]),
];

const guideTerms = <GuideTerm>[
  GuideTerm(
      'Omzet (pendapatan)',
      'Total uang yang masuk dari penjualan, sebelum dikurangi biaya apa pun.',
      'Jual 10 kain @ Rp 200.000 = omzet Rp 2.000.000.'),
  GuideTerm(
      'Laba (untung)',
      'Sisa uang setelah omzet dikurangi semua biaya. Inilah penghasilan usaha yang sebenarnya.',
      'Omzet Rp 2.000.000 dikurangi biaya Rp 1.500.000 = laba Rp 500.000.'),
  GuideTerm('Rugi', 'Kebalikan laba: biaya lebih besar dari omzet.'),
  GuideTerm('Laba rugi',
      'Laporan yang menunjukkan pendapatan, biaya, dan hasil akhirnya (untung atau rugi) pada satu periode.'),
  GuideTerm('Beban / biaya usaha',
      'Uang yang keluar untuk menjalankan usaha: bahan, upah, kemasan, listrik, dan sebagainya.'),
  GuideTerm('Modal produk terjual (HPP)',
      'Biaya bahan dan produksi dari produk yang benar-benar sudah laku. Berbeda dengan belanja bahan yang masih tersimpan sebagai stok.'),
  GuideTerm('Harga modal vs harga jual',
      'Harga modal adalah biaya membuat atau membeli satu produk. Harga jual adalah harga yang dibayar pelanggan.'),
  GuideTerm(
      'Margin',
      'Persentase keuntungan dari harga jual. Rumus: (harga jual − modal) ÷ harga jual.',
      'Jual Rp 100.000, modal Rp 60.000 → margin 40%.'),
  GuideTerm('Arus kas (cashflow)',
      'Pergerakan uang tunai: berapa yang masuk dan berapa yang keluar. Penjualan besar belum tentu berarti uang tunai cukup, karena bisa saja belum dibayar.'),
  GuideTerm('Uang masuk / uang keluar',
      'Uang yang benar-benar diterima atau dibayarkan pada periode itu.'),
  GuideTerm('Arus kas bersih',
      'Uang masuk dikurangi uang keluar. Positif berarti kas bertambah, negatif berarti kas berkurang.'),
  GuideTerm('Rasio keluar/masuk',
      'Perbandingan uang keluar terhadap uang masuk. Di bawah 100% sehat, di atas 100% berarti kas defisit.'),
  GuideTerm('Proyeksi',
      'Perkiraan masa depan berdasarkan rata-rata data sekarang. Hanya perkiraan, bukan kepastian.'),
  GuideTerm(
      'Piutang',
      'Uang yang menjadi hakmu tetapi belum dibayar, misalnya pelanggan memesan lalu membayar belakangan.',
      'Pesanan seragam Rp 3.500.000, baru DP Rp 1.000.000 → piutang Rp 2.500.000.'),
  GuideTerm('Utang',
      'Uang yang menjadi kewajibanmu tetapi belum dibayar, misalnya belanja kain ke supplier dengan tempo.'),
  GuideTerm('Jatuh tempo',
      'Batas tanggal pembayaran utang atau piutang. Lewat dari tanggal ini berarti terlambat.'),
  GuideTerm('DP (uang muka)',
      'Pembayaran sebagian di awal sebagai tanda jadi pesanan.'),
  GuideTerm(
      'Cicilan / dicicil', 'Membayar sebagian demi sebagian sampai lunas.'),
  GuideTerm('Posisi bersih',
      'Piutang dikurangi utang. Positif artinya yang akan masuk lebih besar dari yang harus dibayar.'),
  GuideTerm('Biaya tetap',
      'Biaya yang jumlahnya relatif sama berapa pun penjualan: upah tetap, sewa, listrik.'),
  GuideTerm('Biaya variabel',
      'Biaya yang ikut naik jika produksi naik: bahan baku, kemasan, ongkir.'),
  GuideTerm('Titik impas (BEP)',
      'Omzet minimal agar usaha tidak rugi: biaya tetap sudah tertutup, laba masih nol. Di atas titik ini baru untung.'),
  GuideTerm('Margin kontribusi',
      'Bagian dari tiap rupiah penjualan yang tersisa setelah biaya variabel, dipakai menutup biaya tetap dan menjadi laba.'),
  GuideTerm('Batas aman',
      'Seberapa jauh omzet boleh turun sebelum usaha mulai rugi.'),
  GuideTerm('Dana cadangan (dana darurat)',
      'Uang yang disisihkan untuk bertahan saat penjualan sepi atau ada kejadian tak terduga. Umumnya 3 sampai 6 bulan biaya tetap.'),
  GuideTerm('Lama bertahan (runway)',
      'Berapa hari atau bulan usaha bisa berjalan dengan uang yang ada kalau tidak ada penjualan.'),
  GuideTerm('Aktivitas operasional',
      'Uang masuk dan keluar dari kegiatan harian usaha: jual-beli, bahan, upah.'),
  GuideTerm('Aktivitas investasi',
      'Uang untuk membeli peralatan, mesin, atau aset yang dipakai lama.'),
  GuideTerm('Aktivitas pendanaan',
      'Uang dari atau untuk pemilik dan pemberi pinjaman: tambahan modal, pinjaman, cicilan pinjaman.'),
  GuideTerm('Modal',
      'Dalam arti umum, uang yang ditanam untuk memulai atau menjalankan usaha. Di LARAS kata "modal produk" berarti biaya pembuatan produk.'),
  GuideTerm('Stok & stok minimum',
      'Stok adalah jumlah barang tersedia. Stok minimum adalah batas bawah; di bawahnya kamu perlu produksi atau belanja lagi.'),
  GuideTerm('Supplier',
      'Pemasok: pihak tempat kamu membeli bahan baku atau barang dagangan.'),
  GuideTerm('Kategori',
      'Label pengelompokan catatan, misalnya Bahan baku atau Tenaga kerja, supaya laporan lebih mudah dibaca.'),
  GuideTerm('PPh final 0,5%',
      'Pajak penghasilan khusus UMKM sebesar 0,5% dari omzet. Angka di LARAS hanya estimasi, bukan pengganti perhitungan atau pelaporan pajak resmi.'),
  GuideTerm('Parsing (dibaca otomatis)',
      'Proses LARAS membaca teks chat dan menebak isinya menjadi data: barang, jumlah, harga, nama, dan pembayaran. Karena hanya tebakan, hasilnya selalu kamu periksa dulu.'),
  GuideTerm('SPPL',
      'Surat pernyataan kesanggupan mengelola dampak lingkungan untuk usaha kecil, penting bila usahamu menghasilkan limbah.'),
  GuideTerm('BPJS Ketenagakerjaan / Kesehatan',
      'Jaminan sosial untuk pekerja. Pemberi kerja wajib mendaftarkan dan membayar iurannya.'),
  GuideTerm('LKPM',
      'Laporan berkala kegiatan usaha bagi pemegang NIB, disampaikan lewat OSS.'),
  GuideTerm('NIB',
      'Nomor Induk Berusaha: identitas usaha dari pemerintah, dibuat lewat OSS.'),
  GuideTerm(
      'P-IRT', 'Izin edar untuk produk pangan rumahan dari dinas kesehatan.'),
  GuideTerm('Sertifikasi halal',
      'Pengakuan resmi bahwa produk memenuhi ketentuan halal.'),
];

class LarasGuidePage extends StatefulWidget {
  const LarasGuidePage({super.key});
  @override
  State<LarasGuidePage> createState() => _LarasGuidePageState();
}

class _LarasGuidePageState extends State<LarasGuidePage> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : const Color(0xFFF3F6F4),
        appBar: AppBar(title: const Text('Panduan LARAS UMKM')),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('Fitur'),
                      icon: Icon(Icons.apps_rounded)),
                  ButtonSegment(
                      value: 1,
                      label: Text('Istilah'),
                      icon: Icon(Icons.menu_book_outlined)),
                ],
                selected: {_tab},
                onSelectionChanged: (v) => setState(() => _tab = v.first),
              ),
            ),
            Expanded(child: _tab == 0 ? _features() : _glossary()),
          ]),
        ),
      );

  Widget _features() => ListView(
        key: const Key('guide_features'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Mulai mengelola usaha',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
              'LARAS membantu mencatat uang usaha, memahami kondisinya, dan memutuskan langkah berikutnya. Semua data tersimpan di HP-mu.',
              style: TextStyle(color: _muted, height: 1.4)),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFEAF7EE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alur cepat',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 8),
                    for (final (i, t) in const [
                      'Catat setiap penjualan dan pengeluaran di hari yang sama.',
                      'Isi produk, stok, dan harga bahan di Supplier.',
                      'Catat piutang dan utang kalau ada pembayaran yang tertunda.',
                      'Buka Cashflow dan Titik Impas untuk membaca kondisi kas.',
                      'Lihat AI Insight di Beranda untuk ide langkah berikutnya.',
                    ].indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                  radius: 11,
                                  backgroundColor: _yellow,
                                  foregroundColor: Colors.white,
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(t,
                                      style: const TextStyle(
                                          height: 1.35, color: _ink))),
                            ]),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                        'Tidak paham sebuah kata? Buka tab Istilah di atas.',
                        style: TextStyle(fontSize: 12, color: _muted)),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          for (final s in guideSections)
            AccordionCard(
              key: Key('guide_section_${s.title}'),
              leading: s.icon,
              title: s.title,
              subtitle: s.intro,
              children: [
                for (final (i, f) in s.features.indexed) ...[
                  if (i > 0) const Divider(height: 22),
                  _feature(f),
                ],
              ],
            ),
        ],
      );

  Widget _feature(GuideFeature f) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(f.icon, size: 20, color: _gold),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(f.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(f.what, style: const TextStyle(height: 1.4, fontSize: 13)),
                const SizedBox(height: 3),
                Text('Tujuan: ${f.why}',
                    style: const TextStyle(
                        height: 1.4, fontSize: 12.5, color: _muted)),
                if (f.how != null) ...[
                  const SizedBox(height: 3),
                  Text('Tips: ${f.how}',
                      style: const TextStyle(
                          height: 1.4, fontSize: 12.5, color: _gold)),
                ],
              ])),
        ]),
      );

  Widget _glossary() {
    final q = _query.trim().toLowerCase();
    final terms = guideTerms
        .where((t) =>
            q.isEmpty ||
            t.term.toLowerCase().contains(q) ||
            t.meaning.toLowerCase().contains(q))
        .toList();
    return ListView(
      key: const Key('guide_glossary'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        TextField(
          key: const Key('guide_search'),
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari istilah, mis. piutang',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        if (terms.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Istilah tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted))),
        for (final t in terms)
          AccordionCard(
            key: ValueKey('term-${t.term}-${q.isNotEmpty}'),
            title: t.term,
            initiallyExpanded: q.isNotEmpty && terms.length <= 3,
            children: [
              Text(t.meaning,
                  style: const TextStyle(
                      height: 1.45, fontSize: 14, color: _muted)),
              if (t.example != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _yellow.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Contoh: ${t.example}',
                      style: const TextStyle(
                          height: 1.4, fontSize: 13, color: _ink)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Kartu tanya-jawab: judul + panah, isi terbuka saat diketuk.
class AccordionCard extends StatefulWidget {
  const AccordionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.initiallyExpanded = false,
  });
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData? leading;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<AccordionCard> createState() => _AccordionCardState();
}

class _AccordionCardState extends State<AccordionCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0B2E20) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(children: [
                if (widget.leading != null) ...[
                  Icon(widget.leading, color: _gold),
                  const SizedBox(width: 12),
                ],
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                      if (widget.subtitleWidget != null) widget.subtitleWidget!,
                      if (widget.subtitle != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(widget.subtitle!,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: _muted))),
                    ])),
                const SizedBox(width: 8),
                AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 28, color: _open ? _gold : null)),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }
}
