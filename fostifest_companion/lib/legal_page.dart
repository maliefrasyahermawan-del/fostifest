import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guide_page.dart' show AccordionCard;

const _yellow = Color(0xFF14935A);
const _ink = Color(0xFF123126);
const _gold = Color(0xFF0B5D3B);
const _amber = Color(0xFF8A5A00);
const _red = Color(0xFF8A5A00);
const _muted = Color(0xFF5F766C);

const kLegalKey = 'laras_legal_v1';

enum LegalStatus { belum, diurus, sudah, tidakPerlu }

enum LegalTag { wajib, disarankan, sesuaiUsaha }

class LegalDoc {
  const LegalDoc({
    required this.id,
    required this.icon,
    required this.title,
    required this.tag,
    required this.what,
    required this.why,
    required this.where,
    required this.cost,
    required this.steps,
    this.reminder,
  });
  final String id, title, what, why, where, cost;
  final IconData icon;
  final LegalTag tag;
  final List<String> steps;

  /// Hal yang perlu dilakukan berkala (mis. lapor pajak).
  final String? reminder;
}

class LegalGroup {
  const LegalGroup(this.title, this.subtitle, this.docs);
  final String title, subtitle;
  final List<LegalDoc> docs;
}

/// Informasi bersifat umum dan bisa berubah; selalu cek instansi resmi.
const legalGroups = <LegalGroup>[
  LegalGroup('Dasar usaha', 'Identitas resmi supaya usahamu diakui', [
    LegalDoc(
      id: 'nib',
      icon: Icons.badge_outlined,
      title: 'NIB (Nomor Induk Berusaha)',
      tag: LegalTag.wajib,
      what:
          'Identitas resmi usahamu dari pemerintah. Untuk usaha mikro dan kecil berisiko rendah, NIB sudah cukup sebagai izin berusaha.',
      why:
          'Dibutuhkan untuk membuka rekening usaha, masuk marketplace, ikut program pemerintah, dan mengajukan pembiayaan.',
      where: 'Online di oss.go.id (OSS)',
      cost: 'Gratis',
      steps: [
        'Siapkan KTP dan NPWP (atau NIK).',
        'Daftar akun di oss.go.id.',
        'Isi data usaha dan pilih bidang usaha (KBLI).',
        'Unduh NIB setelah terbit.',
      ],
    ),
    LegalDoc(
      id: 'npwp',
      icon: Icons.receipt_long_outlined,
      title: 'NPWP',
      tag: LegalTag.wajib,
      what:
          'Nomor pokok wajib pajak. Untuk orang pribadi, NIK berfungsi sebagai NPWP.',
      why:
          'Syarat membuat NIB dan mengajukan pinjaman. UMKM umumnya dikenai PPh final 0,5% dari omzet; omzet sampai Rp500 juta per tahun untuk orang pribadi tidak dikenai pajak.',
      where: 'Kantor Pajak (KPP) atau situs DJP',
      cost: 'Gratis',
      steps: [
        'Cek apakah NIK-mu sudah aktif sebagai NPWP di situs DJP.',
        'Jika belum, daftar online atau datang ke KPP.',
        'Simpan nomornya untuk NIB dan laporan pajak.',
      ],
    ),
    LegalDoc(
      id: 'sku',
      icon: Icons.home_work_outlined,
      title: 'Surat Keterangan Usaha / Domisili',
      tag: LegalTag.disarankan,
      what:
          'Surat dari kelurahan atau desa yang menyatakan usahamu berjalan di alamat tertentu.',
      why:
          'Sering diminta bank, mitra, atau pemilik gedung sebagai bukti alamat dan usaha.',
      where: 'Kantor kelurahan atau desa',
      cost: 'Gratis atau biaya administrasi kecil',
      steps: [
        'Bawa KTP, KK, dan bukti alamat usaha.',
        'Isi formulir di kelurahan atau desa.',
        'Minta surat yang sudah ditandatangani dan dicap.',
      ],
    ),
    LegalDoc(
      id: 'akta',
      icon: Icons.account_balance_outlined,
      title: 'Akta Badan Usaha (CV / PT)',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Dokumen pendirian badan usaha lewat notaris dan disahkan Kemenkumham. Usaha perorangan tidak wajib.',
      why:
          'Diperlukan bila ingin ikut tender, menggandeng investor, atau memisahkan harta pribadi dan usaha.',
      where: 'Notaris dan situs AHU Kemenkumham',
      cost: 'Berbayar, bervariasi',
      steps: [
        'Putuskan bentuk usaha (perorangan, CV, atau PT).',
        'Konsultasi dengan notaris.',
        'Urus pengesahan lalu daftarkan NIB atas nama badan usaha.',
      ],
    ),
  ]),
  LegalGroup('Produk & merek', 'Melindungi dan melegalkan produkmu', [
    LegalDoc(
      id: 'merek',
      icon: Icons.verified_outlined,
      title: 'Merek Terdaftar',
      tag: LegalTag.disarankan,
      what:
          'Pendaftaran nama atau logo produkmu ke DJKI supaya tidak bisa dipakai pihak lain.',
      why:
          'Mencegah merek ditiru atau didaftarkan orang lain, dan membangun kepercayaan pembeli.',
      where: 'Online di dgip.go.id (DJKI)',
      cost: 'Berbayar, ada tarif lebih ringan untuk UMK',
      steps: [
        'Cek ketersediaan nama merek di situs DJKI.',
        'Siapkan logo, data pemohon, dan surat keterangan UMK.',
        'Ajukan permohonan dan bayar biayanya.',
      ],
    ),
    LegalDoc(
      id: 'hakcipta',
      icon: Icons.draw_outlined,
      title: 'Hak Cipta Motif / Desain',
      tag: LegalTag.disarankan,
      what:
          'Pencatatan karya seperti motif batik, desain, atau foto produk atas namamu.',
      why:
          'Hak cipta lahir otomatis, tapi pencatatan menjadi bukti kuat jika motifmu ditiru.',
      where: 'Online di dgip.go.id (DJKI)',
      cost: 'Berbayar, relatif ringan',
      steps: [
        'Siapkan contoh karya dan data pencipta.',
        'Isi permohonan pencatatan hak cipta.',
        'Simpan surat pencatatan.',
      ],
    ),
    LegalDoc(
      id: 'halal',
      icon: Icons.mosque_outlined,
      title: 'Sertifikasi Halal',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Sertifikat dari BPJPH bahwa produk memenuhi ketentuan halal. Untuk UMK ada jalur pernyataan mandiri.',
      why:
          'Wajib untuk produk makanan, minuman, kosmetik, dan sebagian produk lain. Kewajibannya bertahap, jadi cek tenggat terbaru.',
      where: 'Online di halal.go.id (SIHALAL)',
      cost: 'Bisa gratis lewat program tertentu',
      steps: [
        'Siapkan NIB dan daftar bahan produk.',
        'Ajukan lewat SIHALAL dengan pendamping proses produk halal.',
        'Tunggu penetapan dan unduh sertifikat.',
      ],
    ),
    LegalDoc(
      id: 'pirt',
      icon: Icons.cookie_outlined,
      title: 'P-IRT (Pangan Industri Rumah Tangga)',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Izin edar dari Dinas Kesehatan untuk makanan atau minuman olahan rumahan.',
      why:
          'Syarat menjual pangan kemasan rumahan secara sah dan dipercaya pembeli.',
      where: 'Dinas Kesehatan kabupaten atau kota',
      cost: 'Umumnya gratis',
      steps: [
        'Ikuti penyuluhan keamanan pangan.',
        'Siapkan NIB, data produk, dan label kemasan.',
        'Ajukan dan tunggu nomor P-IRT.',
      ],
    ),
    LegalDoc(
      id: 'bpom',
      icon: Icons.science_outlined,
      title: 'Izin Edar BPOM',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Pendaftaran produk pangan olahan tertentu, kosmetik, atau obat tradisional ke BPOM.',
      why:
          'Wajib untuk produk yang tidak cukup dengan P-IRT, atau bila ingin dijual lebih luas.',
      where: 'Online di BPOM (e-registration)',
      cost: 'Bervariasi',
      steps: [
        'Cek apakah produkmu termasuk yang wajib BPOM.',
        'Siapkan NIB, data produk, dan hasil uji bila diminta.',
        'Ajukan lewat sistem pendaftaran BPOM.',
      ],
    ),
    LegalDoc(
      id: 'sni',
      icon: Icons.workspace_premium_outlined,
      title: 'SNI (Standar Nasional Indonesia)',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Tanda produk memenuhi standar mutu. Hanya wajib untuk produk tertentu.',
      why: 'Wajib untuk kelompok produk yang diatur pemerintah.',
      where: 'Lembaga sertifikasi produk (LSPro) terakreditasi',
      cost: 'Berbayar, bervariasi',
      steps: [
        'Cek apakah produkmu termasuk yang diwajibkan SNI.',
        'Pilih lembaga sertifikasi terakreditasi.',
        'Ikuti uji dan audit sampai sertifikat terbit.',
      ],
    ),
  ]),
  LegalGroup('Lingkungan & pekerja', 'Tanggung jawab saat usahamu berkembang', [
    LegalDoc(
      id: 'sppl',
      icon: Icons.eco_outlined,
      title: 'SPPL (Pengelolaan Lingkungan)',
      tag: LegalTag.disarankan,
      what:
          'Surat pernyataan kesanggupan mengelola dampak lingkungan untuk usaha kecil.',
      why:
          'Penting bila usahamu menghasilkan limbah, misalnya pewarna batik, pencucian, atau pengolahan makanan.',
      where: 'OSS atau Dinas Lingkungan Hidup setempat',
      cost: 'Gratis',
      steps: [
        'Isi data kegiatan dan jenis limbah.',
        'Buat pernyataan kesanggupan mengelola limbah.',
        'Simpan salinan SPPL.',
      ],
    ),
    LegalDoc(
      id: 'bpjstk',
      icon: Icons.engineering_outlined,
      title: 'BPJS Ketenagakerjaan',
      tag: LegalTag.sesuaiUsaha,
      what:
          'Jaminan kecelakaan kerja dan kematian untuk pekerja, termasuk pengrajin dan karyawan harian.',
      why: 'Wajib bagi pemberi kerja yang memiliki pekerja.',
      where: 'Online di bpjsketenagakerjaan.go.id atau kantor cabang',
      cost: 'Iuran bulanan, terjangkau',
      steps: [
        'Daftarkan usaha sebagai pemberi kerja.',
        'Daftarkan data pekerja.',
        'Bayar iuran tiap bulan.',
      ],
      reminder: 'Bayar iuran setiap bulan.',
    ),
    LegalDoc(
      id: 'bpjskes',
      icon: Icons.health_and_safety_outlined,
      title: 'BPJS Kesehatan Pekerja',
      tag: LegalTag.sesuaiUsaha,
      what: 'Jaminan kesehatan untuk pekerja dan keluarganya.',
      why: 'Wajib bagi pemberi kerja yang memiliki pekerja.',
      where: 'Online di bpjs-kesehatan.go.id atau kantor cabang',
      cost: 'Iuran bulanan',
      steps: [
        'Daftarkan badan usaha.',
        'Daftarkan pekerja dan keluarganya.',
        'Bayar iuran tiap bulan.',
      ],
      reminder: 'Bayar iuran setiap bulan.',
    ),
  ]),
  LegalGroup('Keuangan & pajak', 'Kebiasaan yang menjaga usaha tetap sehat', [
    LegalDoc(
      id: 'rekening',
      icon: Icons.account_balance_wallet_outlined,
      title: 'Rekening Khusus Usaha',
      tag: LegalTag.disarankan,
      what: 'Rekening bank atau dompet digital yang dipakai hanya untuk usaha.',
      why:
          'Memudahkan pencatatan, membuat laporan lebih rapi, dan jadi bukti saat mengajukan pinjaman.',
      where: 'Bank atau penyedia dompet digital',
      cost: 'Gratis atau biaya admin kecil',
      steps: [
        'Siapkan KTP, NPWP, dan NIB atau surat usaha.',
        'Buka rekening khusus usaha.',
        'Pisahkan uang pribadi dan uang usaha.',
      ],
    ),
    LegalDoc(
      id: 'spt',
      icon: Icons.event_available_outlined,
      title: 'Setor Pajak & Lapor SPT',
      tag: LegalTag.wajib,
      what:
          'Menyetor PPh final tiap bulan dan melaporkan SPT Tahunan sesuai tenggat.',
      why: 'Menghindari denda dan menjaga usahamu patuh pajak.',
      where: 'Situs DJP dan kode billing pembayaran',
      cost: 'Pajak sesuai omzet',
      steps: [
        'Hitung omzet bulanan dari catatan LARAS.',
        'Buat kode billing lalu bayar.',
        'Laporkan SPT Tahunan: orang pribadi paling lambat 31 Maret, badan 30 April.',
      ],
      reminder: 'Setor pajak tiap bulan, lapor SPT tiap tahun.',
    ),
    LegalDoc(
      id: 'lkpm',
      icon: Icons.assignment_turned_in_outlined,
      title: 'Laporan Kegiatan Usaha (LKPM)',
      tag: LegalTag.wajib,
      what:
          'Laporan berkala kegiatan usaha bagi pemegang NIB lewat OSS. Usaha mikro dan kecil umumnya melapor per semester.',
      why: 'Kewajiban pemegang NIB agar izin tetap berlaku.',
      where: 'Online di oss.go.id',
      cost: 'Gratis',
      steps: [
        'Masuk ke akun OSS.',
        'Pilih menu laporan kegiatan usaha.',
        'Isi data lalu kirim. Cek jadwal terbaru di OSS.',
      ],
      reminder: 'Lapor berkala sesuai jadwal OSS.',
    ),
  ]),
];

List<LegalDoc> get allLegalDocs => [for (final g in legalGroups) ...g.docs];

class LegalEntry {
  LegalEntry({this.status = LegalStatus.belum, this.number = '', this.expiry});
  LegalStatus status;
  String number;
  DateTime? expiry;

  Map<String, dynamic> toJson() => {
        's': status.name,
        'n': number,
        if (expiry != null) 'e': expiry!.toIso8601String(),
      };

  static LegalEntry fromJson(Map<String, dynamic> j) => LegalEntry(
        status: LegalStatus.values.firstWhere((e) => e.name == j['s'],
            orElse: () => LegalStatus.belum),
        number: '${j['n'] ?? ''}',
        expiry: DateTime.tryParse('${j['e']}'),
      );
}

/// Ringkasan kelengkapan: dokumen "tidak perlu" tidak dihitung.
({int done, int total, double fraction}) legalProgress(
    Map<String, LegalEntry> state) {
  var done = 0, total = 0;
  for (final d in allLegalDocs) {
    final s = state[d.id]?.status ?? LegalStatus.belum;
    if (s == LegalStatus.tidakPerlu) continue;
    total++;
    if (s == LegalStatus.sudah) done++;
  }
  return (done: done, total: total, fraction: total == 0 ? 0 : done / total);
}

/// Hari menuju habis masa berlaku; negatif bila sudah lewat; null bila tidak ada.
int? legalDaysLeft(LegalEntry e, DateTime now) {
  if (e.status != LegalStatus.sudah || e.expiry == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final end = DateTime(e.expiry!.year, e.expiry!.month, e.expiry!.day);
  return end.difference(today).inDays;
}

class LegalitasPage extends StatefulWidget {
  const LegalitasPage({super.key});
  @override
  State<LegalitasPage> createState() => _LegalitasPageState();
}

class _LegalitasPageState extends State<LegalitasPage> {
  final _state = <String, LegalEntry>{};
  bool _loading = true;
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(kLegalKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) => _state[k] =
            LegalEntry.fromJson(Map<String, dynamic>.from(v as Map)));
      } else {
        // Migrasi dari versi lama (tiga kotak centang).
        if (prefs.getBool('legal_nib') == true) {
          _state['nib'] = LegalEntry(status: LegalStatus.sudah);
        }
        if (prefs.getBool('legal_brand') == true) {
          _state['merek'] = LegalEntry(status: LegalStatus.sudah);
        }
        if (prefs.getBool('legal_halal') == true) {
          _state['halal'] = LegalEntry(status: LegalStatus.sudah);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(kLegalKey,
        jsonEncode({for (final e in _state.entries) e.key: e.value.toJson()}));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status legalitas gagal disimpan.')));
    }
  }

  LegalEntry _entry(String id) => _state.putIfAbsent(id, LegalEntry.new);

  void _update(void Function() change) {
    setState(change);
    _persist();
  }

  bool _matches(LegalDoc d) {
    final st = _entry(d.id).status;
    return switch (_filter) {
      'Wajib' => d.tag == LegalTag.wajib,
      'Belum selesai' =>
        st != LegalStatus.sudah && st != LegalStatus.tidakPerlu,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final now = DateTime.now();
    final p = legalProgress(_state);
    final alerts = [
      for (final d in allLegalDocs)
        if ((legalDaysLeft(_entry(d.id), now) ?? 999) <= 60) d
    ];
    final next = allLegalDocs.where((d) {
      final s = _entry(d.id).status;
      return d.tag == LegalTag.wajib &&
          (s == LegalStatus.belum || s == LegalStatus.diurus);
    }).firstOrNull;

    return ListView(
      key: const Key('legal_list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text('Legalitas usaha',
            key: Key('legalitas_page'),
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 6),
        const Text(
            'Daftar izin dan dokumen yang umumnya perlu dimiliki UMKM. Tandai statusnya agar tahu mana yang sudah beres.',
            style: TextStyle(color: _muted, height: 1.4)),
        const SizedBox(height: 16),
        _summary(p, next),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final d in alerts) _alert(d, now),
        ],
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in const ['Semua', 'Wajib', 'Belum selesai'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('legal_filter_$f'),
                  label: Text(f),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        for (final g in legalGroups) ...[
          if (g.docs.any(_matches)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(g.subtitle,
                        style: const TextStyle(fontSize: 12.5, color: _muted)),
                  ]),
            ),
            for (final d in g.docs.where(_matches)) _docCard(d),
          ],
        ],
        const SizedBox(height: 8),
        const Text(
            'Informasi ini bersifat umum dan bisa berubah. Pastikan ke instansi resmi (OSS, DJP, DJKI, BPJPH, dan lainnya) sebelum mengurus. Status di sini hanya catatan pribadimu, bukan verifikasi resmi.',
            style: TextStyle(fontSize: 11.5, color: _muted, height: 1.4)),
      ],
    );
  }

  Widget _summary(({int done, int total, double fraction}) p, LegalDoc? next) =>
      Card(
        color: const Color(0xFFEAF7EE),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                      child: CircularProgressIndicator(
                    value: p.fraction,
                    strokeWidth: 7,
                    color: _yellow,
                    backgroundColor: _yellow.withValues(alpha: .25),
                  )),
                  Text('${(p.fraction * 100).round()}%',
                      key: const Key('legal_percent'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: _ink)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Kelengkapan legalitas',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 2),
                    Text('${p.done} dari ${p.total} dokumen sudah dimiliki',
                        style: const TextStyle(fontSize: 13, color: _ink)),
                  ])),
            ]),
            if (next != null) ...[
              const Divider(height: 22),
              Row(children: [
                const Icon(Icons.flag_outlined, size: 18, color: _gold),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Langkah berikutnya: ${next.title}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink))),
              ]),
            ],
          ]),
        ),
      );

  Widget _alert(LegalDoc d, DateTime now) {
    final days = legalDaysLeft(_entry(d.id), now)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: (days < 0 ? _red : _amber).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.notifications_active_outlined,
            size: 20, color: days < 0 ? _red : _amber),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                days < 0
                    ? '${d.title} sudah habis masa berlakunya. Segera perpanjang.'
                    : '${d.title} habis dalam $days hari. Siapkan perpanjangan.',
                style: const TextStyle(fontSize: 13, height: 1.35))),
      ]),
    );
  }

  Widget _tagChip(LegalTag t) {
    final (label, color) = switch (t) {
      LegalTag.wajib => ('Wajib', _red),
      LegalTag.disarankan => ('Disarankan', _gold),
      LegalTag.sesuaiUsaha => ('Sesuai usaha', _muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _docCard(LegalDoc d) {
    final e = _entry(d.id);
    final (statusLabel, statusColor) = switch (e.status) {
      LegalStatus.sudah => ('Sudah punya', _gold),
      LegalStatus.diurus => ('Sedang diurus', _amber),
      LegalStatus.tidakPerlu => ('Tidak perlu', _muted),
      LegalStatus.belum => ('Belum punya', _muted),
    };
    return AccordionCard(
      key: Key('legal_${d.id}'),
      leading: d.icon,
      title: d.title,
      subtitleWidget: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(spacing: 6, runSpacing: 4, children: [
          _tagChip(d.tag),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor)),
          ),
        ]),
      ),
      children: [
        Text(d.what, style: const TextStyle(height: 1.45, fontSize: 14)),
        const SizedBox(height: 10),
        _info(Icons.help_outline_rounded, 'Kenapa penting', d.why),
        _info(Icons.place_outlined, 'Diurus di', d.where),
        _info(Icons.payments_outlined, 'Biaya', d.cost),
        if (d.reminder != null)
          _info(Icons.event_repeat_outlined, 'Berkala', d.reminder!),
        const SizedBox(height: 8),
        const Text('Cara mengurus',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        const SizedBox(height: 6),
        for (final (i, s) in d.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                  radius: 10,
                  backgroundColor: _yellow,
                  foregroundColor: Colors.white,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900))),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(s,
                      style: const TextStyle(fontSize: 13, height: 1.35))),
            ]),
          ),
        const Divider(height: 26),
        const Text('Statusmu',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in const {
            LegalStatus.belum: 'Belum punya',
            LegalStatus.diurus: 'Sedang diurus',
            LegalStatus.sudah: 'Sudah punya',
            LegalStatus.tidakPerlu: 'Tidak perlu',
          }.entries)
            ChoiceChip(
              key: Key('legal_${d.id}_${s.key.name}'),
              label: Text(s.value),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selected: e.status == s.key,
              onSelected: (_) => _update(() => e.status = s.key),
            ),
        ]),
        if (e.status == LegalStatus.sudah) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: Key('legal_${d.id}_number'),
            initialValue: e.number,
            onChanged: (v) {
              e.number = v.trim();
              _persist();
            },
            decoration:
                const InputDecoration(labelText: 'Nomor dokumen (opsional)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: e.expiry ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Masa berlaku sampai');
              if (picked != null) _update(() => e.expiry = picked);
            },
            icon: const Icon(Icons.event_outlined),
            label: Text(e.expiry == null
                ? 'Tambah masa berlaku (untuk pengingat)'
                : 'Berlaku sampai ${e.expiry!.day}/${e.expiry!.month}/${e.expiry!.year}'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46)),
          ),
        ],
      ],
    );
  }

  Widget _info(IconData icon, String label, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: _gold),
          const SizedBox(width: 8),
          Expanded(
              child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: text),
          ], style: const TextStyle(fontSize: 13, height: 1.4)))),
        ]),
      );
}
