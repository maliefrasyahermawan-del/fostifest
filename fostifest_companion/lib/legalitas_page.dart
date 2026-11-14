import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const legalProfileKey = 'laras_legal_profile_v2';
const legalChecklistKey = 'laras_legal_checklist_v2';
const legalSectors = {'kuliner', 'fashion', 'perdagangan', 'jasa'};

Map<String, dynamic>? decodeLegalProfile(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final value = jsonDecode(raw);
    if (value is! Map) return null;
    final profile = Map<String, dynamic>.from(value);
    final sector = '${profile['sector'] ?? ''}'.toLowerCase();
    profile['sector'] = legalSectors.contains(sector) ? sector : '';
    return profile;
  } catch (_) {
    return null;
  }
}

enum BusinessScale { micro, small, medium, outside }

enum LegalRisk { unknown, low, mediumLow, mediumHigh, high }

String scaleLabel(BusinessScale v) => switch (v) {
      BusinessScale.micro => 'Mikro',
      BusinessScale.small => 'Kecil',
      BusinessScale.medium => 'Menengah',
      BusinessScale.outside => 'Di luar batas UMKM',
    };
String riskLabel(LegalRisk v) => switch (v) {
      LegalRisk.unknown => 'Belum diketahui',
      LegalRisk.low => 'Rendah',
      LegalRisk.mediumLow => 'Menengah rendah',
      LegalRisk.mediumHigh => 'Menengah tinggi',
      LegalRisk.high => 'Tinggi',
    };

BusinessScale scaleFromCapital(num value) => value <= 1000000000
    ? BusinessScale.micro
    : value <= 5000000000
        ? BusinessScale.small
        : value <= 10000000000
            ? BusinessScale.medium
            : BusinessScale.outside;
BusinessScale scaleFromRevenue(num value) => value <= 2000000000
    ? BusinessScale.micro
    : value <= 15000000000
        ? BusinessScale.small
        : value <= 50000000000
            ? BusinessScale.medium
            : BusinessScale.outside;

class LegalRecommendation {
  const LegalRecommendation({
    required this.id,
    required this.title,
    required this.status,
    required this.documents,
    required this.steps,
    required this.url,
    this.conditional = false,
  });
  final String id, title, status, url;
  final List<String> documents, steps;
  final bool conditional;
}

class LegalRuleEngine {
  static List<LegalRecommendation> evaluate({
    required String sector,
    required String product,
    required String kbli,
    required String scope,
    required LegalRisk risk,
    required BusinessScale scale,
  }) {
    final enough = sector.isNotEmpty &&
        product.trim().isNotEmpty &&
        kbli.trim().isNotEmpty &&
        scope.trim().isNotEmpty;
    final out = <LegalRecommendation>[
      LegalRecommendation(
        id: 'nib',
        title: 'NIB melalui OSS',
        status: enough
            ? 'Dasar identitas dan perizinan berusaha'
            : 'Lengkapi profil agar data OSS tidak keliru',
        documents: const [
          'NIK penanggung jawab',
          'NPWP (bila ada/wajib)',
          'Alamat, modal, tenaga kerja, dan data kegiatan usaha',
          'KBLI yang sesuai kegiatan nyata',
        ],
        steps: const [
          'Buat/masuk akun OSS',
          'Isi data pelaku dan kegiatan usaha',
          'Periksa KBLI, lokasi, skala, serta risiko',
          'Terbitkan dan simpan NIB',
        ],
        url: 'https://oss.go.id/',
      ),
    ];
    if (!enough || risk == LegalRisk.unknown) {
      out.add(
        const LegalRecommendation(
          id: 'risk_check',
          title: 'Verifikasi KBLI 2025 & risiko di OSS',
          status: 'Belum cukup informasi untuk menentukan izin lanjutan',
          conditional: true,
          documents: [
            'Uraian kegiatan utama',
            'Produk/jasa dan cara penjualannya',
            'Lokasi serta ruang lingkup kegiatan',
          ],
          steps: [
            'Cari kegiatan yang paling sesuai di OSS',
            'Konfirmasi uraian KBLI, bukan hanya judul',
            'Gunakan tingkat risiko yang dihitung OSS',
            'Kembali dan pilih risiko yang tampil',
          ],
          url: 'https://oss.go.id/informasi/kbli-berbasis-risiko',
        ),
      );
    } else if (risk == LegalRisk.mediumLow) {
      out.add(
        const LegalRecommendation(
          id: 'standard',
          title: 'Sertifikat Standar',
          status: 'Pernyataan mandiri sesuai hasil OSS',
          documents: ['NIB', 'Pernyataan pemenuhan standar usaha'],
          steps: [
            'Buka kegiatan usaha di OSS',
            'Baca dan setujui standar yang berlaku',
            'Terbitkan Sertifikat Standar',
          ],
          url: 'https://oss.go.id/',
        ),
      );
    } else if (risk == LegalRisk.mediumHigh) {
      out.add(
        const LegalRecommendation(
          id: 'standard_verified',
          title: 'Sertifikat Standar terverifikasi',
          status: 'Perlu pemenuhan dan verifikasi sesuai hasil OSS',
          documents: [
            'NIB',
            'Dokumen pemenuhan standar sektoral',
            'Persyaratan dasar bila ditampilkan OSS',
          ],
          steps: [
            'Unggah pemenuhan persyaratan di OSS',
            'Ajukan verifikasi kepada instansi berwenang',
            'Pantau sampai status terverifikasi',
          ],
          url: 'https://oss.go.id/',
        ),
      );
    } else if (risk == LegalRisk.high) {
      out.add(
        const LegalRecommendation(
          id: 'permit',
          title: 'Izin berusaha',
          status: 'Risiko tinggi—ikuti persyaratan spesifik dari OSS',
          documents: [
            'NIB',
            'Dokumen persyaratan izin sektoral',
            'Persyaratan dasar bila ditampilkan OSS',
          ],
          steps: [
            'Buka menu pemenuhan persyaratan',
            'Lengkapi dokumen yang diminta OSS',
            'Ajukan dan tunggu persetujuan izin',
          ],
          url: 'https://oss.go.id/',
        ),
      );
    }
    if (sector == 'kuliner') {
      out.add(
        LegalRecommendation(
          id: 'halal',
          title: 'Sertifikat Halal',
          status: scale == BusinessScale.medium
              ? 'Kewajiban berlaku untuk produk terkait; periksa kategori produk'
              : 'Persiapkan selama masa penahapan UMK dan cek kelayakan skema self-declare',
          conditional: true,
          documents: const [
            'NIB',
            'Daftar produk, bahan, dan proses produksi',
            'Manual/Sistem Jaminan Produk Halal',
            'Dokumen penyelia halal sesuai skema',
          ],
          steps: const [
            'Buat akun SIHALAL',
            'Pilih skema yang sesuai',
            'Lengkapi data bahan dan proses',
            'Ikuti pemeriksaan/pendampingan sesuai skema',
          ],
          url: 'https://ptsp.halal.go.id/',
        ),
      );
      out.add(
        const LegalRecommendation(
          id: 'food_permit',
          title: 'Cek izin edar pangan',
          status:
              'Bersyarat—SPP-IRT atau izin BPOM bergantung jenis, proses, daya simpan, dan cara edar',
          conditional: true,
          documents: [
            'Komposisi dan proses produksi',
            'Label dan kemasan',
            'Informasi masa simpan dan jalur distribusi',
          ],
          steps: [
            'Identifikasi kategori produk secara tepat',
            'Konsultasikan ke Dinas Kesehatan/DPMPTSP atau BPOM',
            'Ikuti hasil penilaian; jangan memilih izin hanya dari nama produk',
          ],
          url: 'https://sppirt.pom.go.id/',
        ),
      );
    }
    out.add(
      const LegalRecommendation(
        id: 'brand',
        title: 'Pelindungan merek',
        status: 'Opsional, disarankan untuk melindungi nama/logo usaha',
        conditional: true,
        documents: [
          'Etiket/label merek',
          'Tanda tangan pemohon',
          'Surat rekomendasi/keterangan dan pernyataan UMK untuk tarif UMK',
        ],
        steps: [
          'Telusuri merek serupa di PDKI',
          'Tentukan kelas barang/jasa',
          'Ajukan permohonan merek secara daring',
          'Simpan tanda terima dan pantau status',
        ],
        url: 'https://merek.dgip.go.id/',
      ),
    );
    return out;
  }
}

class LegalitasPage extends StatefulWidget {
  const LegalitasPage({super.key});
  @override
  State<LegalitasPage> createState() => _LegalitasPageState();
}

class _LegalitasPageState extends State<LegalitasPage> {
  final _capital = TextEditingController(text: '0'),
      _revenue = TextEditingController(text: '0'),
      _product = TextEditingController(),
      _kbli = TextEditingController(),
      _scope = TextEditingController();
  String _sector = '';
  LegalRisk _risk = LegalRisk.unknown;
  Set<String> _checked = {};
  bool _loading = true;
  int _num(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  BusinessScale get _capitalScale => scaleFromCapital(_num(_capital));
  BusinessScale get _revenueScale => scaleFromRevenue(_num(_revenue));
  BusinessScale get _scale =>
      BusinessScale.values[_capitalScale.index > _revenueScale.index
          ? _capitalScale.index
          : _revenueScale.index];
  List<LegalRecommendation> get _rules => LegalRuleEngine.evaluate(
        sector: _sector,
        product: _product.text,
        kbli: _kbli.text,
        scope: _scope.text,
        risk: _risk,
        scale: _scale,
      );
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_capital, _revenue, _product, _kbli, _scope]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(legalProfileKey);
    final checklist = p.getStringList(legalChecklistKey) ?? [];
    final profile = decodeLegalProfile(raw);
    if (profile != null) {
      _sector = '${profile['sector'] ?? ''}';
      _product.text = '${profile['product'] ?? ''}';
      _kbli.text = '${profile['kbli'] ?? ''}';
      _scope.text = '${profile['scope'] ?? ''}';
      _capital.text = '${profile['capital'] ?? 0}';
      _revenue.text = '${profile['revenue'] ?? 0}';
      _risk = LegalRisk.values.firstWhere(
        (e) => e.name == profile['risk'],
        orElse: () => LegalRisk.unknown,
      );
    } else if (raw != null) {
      // Profil lama/rusak diabaikan agar halaman tetap dapat dibuka.
      await p.remove(legalProfileKey);
    }
    final migrated = <String>{...checklist};
    if (p.getBool('legal_nib') == true) migrated.add('nib');
    if (p.getBool('legal_brand') == true) migrated.add('brand');
    if (p.getBool('legal_halal') == true) migrated.add('halal');
    if (migrated.length != checklist.length)
      await p.setStringList(legalChecklistKey, migrated.toList());
    if (mounted)
      setState(() {
        _checked = migrated;
        _loading = false;
      });
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      legalProfileKey,
      jsonEncode({
        'sector': _sector,
        'product': _product.text,
        'kbli': _kbli.text,
        'scope': _scope.text,
        'capital': _num(_capital),
        'revenue': _num(_revenue),
        'risk': _risk.name,
      }),
    );
    await p.setStringList(legalChecklistKey, _checked.toList());
    await p.setBool('legal_nib', _checked.contains('nib'));
    await p.setBool('legal_brand', _checked.contains('brand'));
    await p.setBool('legal_halal', _checked.contains('halal'));
  }

  void _changed() {
    setState(() {});
    _persist();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      );

  Future<void> _showDetail(LegalRecommendation r) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF8FAF9),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          maxChildSize: .94,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAD5D0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(r.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(r.status, style: const TextStyle(color: Color(0xFF5F766C))),
              const SizedBox(height: 20),
              Text(
                r.conditional
                    ? 'Perlu dikonfirmasi sesuai kondisi usaha'
                    : 'Dokumen yang disiapkan',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              for (final document in r.documents)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined,
                      color: Color(0xFF087A55)),
                  title: Text(document),
                ),
              const SizedBox(height: 10),
              const Text('Langkah pengurusan',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              for (var i = 0; i < r.steps.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFFDDF3EA),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Color(0xFF087A55),
                            fontWeight: FontWeight.w900)),
                  ),
                  title: Text(r.steps[i]),
                ),
              const SizedBox(height: 12),
              const Text('Situs pemerintah',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              SelectableText(r.url,
                  style: const TextStyle(
                      color: Color(0xFF087A55), fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final conflicting = _capitalScale != _revenueScale;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6F5),
        surfaceTintColor: Colors.transparent,
        title: const Text('Legalitas usaha',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        key: const Key('legalitas_page'),
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
                  'Peta legalitas usaha',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scaleLabel(_scale),
                  key: const Key('business_scale'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  conflicting
                      ? 'Modal: ${scaleLabel(_capitalScale)} · Omzet: ${scaleLabel(_revenueScale)}. Ditampilkan kategori yang lebih tinggi.'
                      : 'Berdasarkan modal dan omzet tahunan.',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hasil ini panduan persiapan, bukan verifikasi atau nasihat hukum. Keputusan resmi mengikuti OSS dan instansi berwenang.',
            style: TextStyle(color: Color(0xFF5F766C), height: 1.4),
          ),
          const SizedBox(height: 10),
          Card(
            child: CheckboxListTile(
              key: const Key('legal_nib_quick'),
              value: _checked.contains('nib'),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _checked.add('nib');
                  } else {
                    _checked.remove('nib');
                  }
                });
                _persist();
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('NIB sudah dimiliki',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text(
                  'Checklist cepat; detail rekomendasi mengikuti profil di bawah.'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Profil kegiatan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _sector.isEmpty ? null : _sector,
            decoration: _dec('Sektor usaha'),
            items: const [
              DropdownMenuItem(value: 'kuliner', child: Text('Kuliner')),
              DropdownMenuItem(value: 'fashion', child: Text('Fashion')),
              DropdownMenuItem(
                value: 'perdagangan',
                child: Text('Perdagangan'),
              ),
              DropdownMenuItem(value: 'jasa', child: Text('Jasa')),
            ],
            onChanged: (v) {
              _sector = v ?? '';
              _changed();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _product,
            decoration: _dec(
              'Produk atau jasa utama',
              hint: 'Contoh: sambal kemasan',
            ),
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _kbli,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dec(
              'KBLI 2025',
              hint: 'Isi kode setelah dicocokkan di OSS',
            ),
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _scope,
            maxLines: 2,
            decoration: _dec(
              'Ruang lingkup kegiatan',
              hint: 'Apa yang dibuat/dijual, proses, lokasi, dan cara edar',
            ),
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LegalRisk>(
            value: _risk,
            decoration: _dec('Tingkat risiko dari OSS'),
            items: [
              for (final r in LegalRisk.values)
                DropdownMenuItem(value: r, child: Text(riskLabel(r))),
            ],
            onChanged: (v) {
              _risk = v ?? LegalRisk.unknown;
              _changed();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _capital,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec(
                    'Modal usaha',
                    hint: 'Di luar tanah/bangunan',
                  ),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _revenue,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Omzet per tahun'),
                  onChanged: (_) => _changed(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Rekomendasi & checklist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${_checked.intersection(_rules.map((e) => e.id).toSet()).length} dari ${_rules.length} ditandai selesai',
            style: const TextStyle(color: Color(0xFF5F766C)),
          ),
          const SizedBox(height: 8),
          for (final r in _rules.where((item) => item.id != 'nib'))
            Card(
              child: CheckboxListTile(
                key: Key('legal_${r.id}'),
                value: _checked.contains(r.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _checked.add(r.id);
                    } else {
                      _checked.remove(r.id);
                    }
                  });
                  _persist();
                },
                title: Text(r.title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${r.status}\nKetuk untuk melihat persyaratan'),
                isThreeLine: true,
                controlAffinity: ListTileControlAffinity.leading,
                secondary: IconButton(
                  tooltip: 'Lihat persyaratan',
                  onPressed: () => _showDetail(r),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                tileColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
