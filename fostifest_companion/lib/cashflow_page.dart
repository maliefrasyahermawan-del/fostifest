import 'package:flutter/material.dart';

import 'laras_operations_page.dart';
import 'supplier_page.dart' show kMaterialsKey;

const _yellow = Color(0xFF14935A);
const _inkOut = Color(0xFF1F4D39);
const _gold = Color(0xFF0B5D3B);
const _red = Color(0xFF8A5A00);

/// Jenis arus kas ala laporan arus kas (operasional / investasi / pendanaan).
/// shortcut: klasifikasi berdasarkan kata kunci kategori, upgrade ke pilihan
/// jenis eksplisit per transaksi bila pengguna butuh akurasi akuntansi.
String cashType(String category) {
  final c = category.toLowerCase();
  if (RegExp(r'modal|pinjam|cicil|prive|investor|hibah').hasMatch(c)) {
    return 'Pendanaan';
  }
  if (RegExp(r'peralatan|mesin|aset|renovasi|kendaraan|investasi')
      .hasMatch(c)) {
    return 'Investasi';
  }
  return 'Operasional';
}

bool isVariableCost(String category, String name) => RegExp(
        r'bahan|kain|kemasan|ongkir|kirim|komisi|packing|label|benang|malam|warna')
    .hasMatch('$category $name'.toLowerCase());

class MaterialImpact {
  MaterialImpact(this.name, this.pct, this.spend, this.extra);
  final String name;
  final double pct; // perubahan harga, 0.08 = naik 8%
  final int spend; // belanja bahan ini pada periode
  final int extra; // tambahan biaya akibat perubahan harga
}

class Bucket {
  Bucket(this.start);
  final DateTime start;
  int inflow = 0, outflow = 0;
}

class CashflowAnalysis {
  int inflow = 0, outflow = 0, prevInflow = 0, prevOutflow = 0;
  int bahanBaku = 0, variable = 0, fixed = 0;
  final inByCategory = <String, int>{};
  final outByCategory = <String, int>{};
  final byType = <String, int>{
    'Operasional': 0,
    'Investasi': 0,
    'Pendanaan': 0
  };
  final buckets = <Bucket>[];
  final impacts = <MaterialImpact>[];
  late int days;

  int get net => inflow - outflow;
  int get prevNet => prevInflow - prevOutflow;
  int get extraFromPrices => impacts.fold(0, (s, e) => s + e.extra);
  double get avgNetPerDay => days == 0 ? 0 : net / days;
}

DateTime? _date(Object? v) => DateTime.tryParse('$v');
int _amt(Object? v) => (v is num) ? v.toInt() : 0;
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

CashflowAnalysis analyzeCashflow({
  required List<Map<String, dynamic>> income,
  required List<Map<String, dynamic>> expenses,
  required List<Map<String, dynamic>> materials,
  required DateTimeRange range,
}) {
  final a = CashflowAnalysis();
  final start = _day(range.start);
  final end = _day(range.end);
  a.days = end.difference(start).inDays + 1;
  final prevStart = start.subtract(Duration(days: a.days));
  bool within(DateTime d, DateTime s, DateTime e) =>
      !_day(d).isBefore(s) && !_day(d).isAfter(e);

  final count = a.days <= 7 ? a.days : (a.days / 7).ceil().clamp(2, 8);
  final span = (a.days / count).ceil();
  for (var i = 0; i < count; i++) {
    a.buckets.add(Bucket(start.add(Duration(days: i * span))));
  }
  Bucket bucketOf(DateTime d) {
    final i = (_day(d).difference(start).inDays ~/ span).clamp(0, count - 1);
    return a.buckets[i];
  }

  for (final e in income) {
    final d = _date(e['date']);
    if (d == null) continue;
    final v = _amt(e['amount']);
    if (within(d, start, end)) {
      a.inflow += v;
      final c = '${e['category'] ?? 'Penjualan'}';
      a.inByCategory[c] = (a.inByCategory[c] ?? 0) + v;
      a.byType[cashType(c)] = a.byType[cashType(c)]! + v;
      bucketOf(d).inflow += v;
    } else if (within(d, prevStart, start.subtract(const Duration(days: 1)))) {
      a.prevInflow += v;
    }
  }
  for (final e in expenses) {
    final d = _date(e['createdAt']);
    if (d == null) continue;
    final v = _amt(e['amount']);
    if (within(d, start, end)) {
      a.outflow += v;
      final c = '${e['category'] ?? 'Lainnya'}';
      a.outByCategory[c] = (a.outByCategory[c] ?? 0) + v;
      a.byType[cashType(c)] = a.byType[cashType(c)]! - v;
      if (c.toLowerCase().contains('bahan')) a.bahanBaku += v;
      if (isVariableCost(c, '${e['name']}')) {
        a.variable += v;
      } else {
        a.fixed += v;
      }
      bucketOf(d).outflow += v;
    } else if (within(d, prevStart, start.subtract(const Duration(days: 1)))) {
      a.prevOutflow += v;
    }
  }

  for (final m in materials) {
    final h = (m['priceHistory'] as List?) ?? const [];
    if (h.length < 2) continue;
    final prev = _amt(h[h.length - 2]['price']);
    final now = _amt(h.last['price']);
    if (prev <= 0 || prev == now) continue;
    final pct = (now - prev) / prev;
    final name = '${m['name']}'.toLowerCase();
    var spend = 0;
    for (final e in expenses) {
      final d = _date(e['createdAt']);
      if (d != null &&
          within(d, start, end) &&
          '${e['name']}'.toLowerCase().contains(name)) {
        spend += _amt(e['amount']);
      }
    }
    a.impacts.add(MaterialImpact(
        '${m['name']}', pct, spend, (spend * pct / (1 + pct)).round()));
  }
  a.impacts.sort((x, y) => y.extra.abs().compareTo(x.extra.abs()));
  return a;
}

/// Saran otomatis berbasis aturan dari hasil analisis (offline).
List<(IconData, String)> cashflowInsights(CashflowAnalysis a) {
  final out = <(IconData, String)>[];
  if (a.inflow == 0 && a.outflow == 0) {
    return [(Icons.edit_note_rounded, 'Belum ada transaksi pada periode ini.')];
  }
  if (a.net < 0) {
    out.add((
      Icons.warning_amber_rounded,
      'Uang keluar melebihi uang masuk sebesar ${larasRupiah(-a.net)}. Tunda belanja yang belum mendesak dan tagih pembayaran yang tertunda.'
    ));
  } else {
    out.add((
      Icons.check_circle_outline_rounded,
      'Arus kas bersih positif ${larasRupiah(a.net)}. Sisihkan sebagian untuk dana cadangan operasional.'
    ));
  }
  if (a.outflow > 0 && a.bahanBaku / a.outflow > 0.5) {
    out.add((
      Icons.inventory_2_outlined,
      'Bahan baku ${(a.bahanBaku * 100 / a.outflow).round()}% dari uang keluar. Bandingkan harga antar supplier di menu Supplier.'
    ));
  }
  if (a.extraFromPrices > 0) {
    out.add((
      Icons.trending_up_rounded,
      'Kenaikan harga bahan menambah biaya sekitar ${larasRupiah(a.extraFromPrices)} pada periode ini. Pertimbangkan menyesuaikan harga jual.'
    ));
  }
  if (a.prevInflow > 0 && a.inflow < a.prevInflow * 0.8) {
    out.add((
      Icons.trending_down_rounded,
      'Uang masuk turun ${((1 - a.inflow / a.prevInflow) * 100).round()}% dibanding periode sebelumnya. Coba promo atau hubungi pelanggan lama.'
    ));
  }
  return out;
}

class CashflowPage extends StatefulWidget {
  const CashflowPage({super.key});
  @override
  State<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _income = [], _expenses = [], _materials = [];
  bool _loaded = false;
  late DateTimeRange _range;
  double _priceShock = 0, _salesShift = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
        start: _day(now).subtract(const Duration(days: 29)), end: _day(now));
    _load();
  }

  Future<void> _load() async {
    final i = await _repo.read(LarasLocalRepository.income);
    final e = await _repo.read(LarasLocalRepository.expenses);
    final m = await _repo.read(kMaterialsKey);
    if (!mounted) return;
    setState(() {
      _income = i;
      _expenses = e;
      _materials = m;
      _loaded = true;
    });
  }

  Map<String, DateTimeRange> get _presets {
    final now = DateTime.now();
    final today = _day(now);
    return {
      '7 hari': DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
      '30 hari': DateTimeRange(
          start: today.subtract(const Duration(days: 29)), end: today),
      'Bulan ini': DateTimeRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1, 0)),
      '90 hari': DateTimeRange(
          start: today.subtract(const Duration(days: 89)), end: today),
    };
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: _range,
        helpText: 'Pilih rentang tanggal',
        saveText: 'Terapkan');
    if (r != null) setState(() => _range = r);
  }

  String _d(DateTime d) => '${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final a = analyzeCashflow(
        income: _income,
        expenses: _expenses,
        materials: _materials,
        range: _range);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Manajemen Cashflow',
              style: TextStyle(fontWeight: FontWeight.w900))),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: const Key('cashflow_page'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _rangeBar(),
                  const SizedBox(height: 14),
                  _summary(a),
                  const SizedBox(height: 14),
                  _chart(a),
                  const SizedBox(height: 14),
                  _types(a),
                  const SizedBox(height: 14),
                  _categories('Uang masuk per kategori', a.inByCategory,
                      a.inflow, _yellow),
                  const SizedBox(height: 14),
                  _categories('Uang keluar per kategori', a.outByCategory,
                      a.outflow, _inkOut),
                  const SizedBox(height: 14),
                  _costStructure(a),
                  const SizedBox(height: 14),
                  _materialImpact(a),
                  const SizedBox(height: 14),
                  _simulator(a),
                  const SizedBox(height: 14),
                  _insights(a),
                ],
              ),
      ),
    );
  }

  Widget _card(String title, Widget child, {String? subtitle}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            if (subtitle != null)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF5F766C)))),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  Widget _rangeBar() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
          key: const Key('cashflow_range_button'),
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range_outlined),
          label: Text(
              '${_range.start.day}/${_range.start.month}/${_range.start.year} – ${_range.end.day}/${_range.end.month}/${_range.end.year}'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final e in _presets.entries)
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.key),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: e.value == _range,
                      onSelected: (_) => setState(() => _range = e.value),
                    )),
            ])),
      ]);

  Widget _delta(int now, int before, {bool upIsGood = true}) {
    if (before == 0) return const SizedBox.shrink();
    final p = ((now - before) * 100 / before.abs()).round();
    final good = upIsGood ? p >= 0 : p <= 0;
    return Text('${p >= 0 ? '+' : ''}$p% vs periode lalu',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: good ? _gold : _red));
  }

  Widget _summary(CashflowAnalysis a) {
    Widget tile(String label, int v, Color c, Widget extra) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: c.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(larasRupiah(v),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900))),
              const SizedBox(height: 4),
              extra,
            ]),
          ),
        );
    final proj = (a.avgNetPerDay * 30).round();
    return _card(
      'Ringkasan arus kas',
      Column(children: [
        Row(children: [
          tile('UANG MASUK', a.inflow, _yellow, _delta(a.inflow, a.prevInflow)),
          const SizedBox(width: 8),
          tile('UANG KELUAR', a.outflow, _inkOut,
              _delta(a.outflow, a.prevOutflow, upIsGood: false)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          tile('ARUS KAS BERSIH', a.net, a.net >= 0 ? _yellow : _red,
              _delta(a.net, a.prevNet)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RASIO KELUAR/MASUK',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        a.inflow == 0
                            ? '-'
                            : '${(a.outflow * 100 / a.inflow).round()}%',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        a.inflow == 0 || a.outflow <= a.inflow
                            ? 'Di bawah 100% = sehat'
                            : 'Di atas 100% = defisit',
                        style: const TextStyle(fontSize: 11)),
                  ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.insights_outlined, size: 18, color: _gold),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  'Proyeksi 30 hari ke depan (rata-rata periode ini): ${proj >= 0 ? '+' : '-'}${larasRupiah(proj.abs())}',
                  style: const TextStyle(fontSize: 12.5))),
        ]),
      ]),
    );
  }

  Widget _chart(CashflowAnalysis a) {
    final maxV = a.buckets.fold<int>(
        1, (m, b) => [m, b.inflow, b.outflow].reduce((x, y) => x > y ? x : y));
    return _card(
      'Uang masuk vs keluar',
      Column(children: [
        SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final b in a.buckets)
              Expanded(
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bar(b.inflow / maxV, _yellow),
                          const SizedBox(width: 3),
                          _bar(b.outflow / maxV, _inkOut),
                        ]),
                  ),
                  const SizedBox(height: 4),
                  Text(_d(b.start),
                      style: const TextStyle(
                          fontSize: 9.5, color: Color(0xFF5F766C))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legend(_yellow, 'Masuk'),
          const SizedBox(width: 16),
          _legend(_inkOut, 'Keluar'),
        ]),
      ]),
      subtitle: 'Dikelompokkan per ${(a.days / a.buckets.length).ceil()} hari',
    );
  }

  Widget _bar(double f, Color c) => Container(
      width: 11,
      height: 1 + 120 * f.clamp(0, 1),
      decoration: BoxDecoration(
          color: c,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))));

  Widget _legend(Color c, String t) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(fontSize: 12)),
      ]);

  Widget _types(CashflowAnalysis a) => _card(
        'Tipe arus kas',
        Column(children: [
          for (final e in a.byType.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  switch (e.key) {
                    'Investasi' => Icons.precision_manufacturing_outlined,
                    'Pendanaan' => Icons.account_balance_outlined,
                    _ => Icons.storefront_outlined,
                  },
                  color: _gold),
              title: Text(e.key,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                  switch (e.key) {
                    'Investasi' => 'Beli peralatan, mesin, atau aset usaha',
                    'Pendanaan' => 'Modal pemilik, pinjaman, cicilan',
                    _ => 'Jual-beli dan biaya harian usaha',
                  },
                  style: const TextStyle(fontSize: 11.5)),
              trailing: Text(
                  '${e.value < 0 ? '-' : ''}${larasRupiah(e.value.abs())}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: e.value < 0 ? _red : null)),
            ),
        ]),
        subtitle: 'Masuk dikurangi keluar untuk tiap jenis aktivitas',
      );

  Widget _categories(
      String title, Map<String, int> data, int total, Color color) {
    final rows = data.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    return _card(
      title,
      rows.isEmpty
          ? const Text('Belum ada data pada periode ini.',
              style: TextStyle(color: Color(0xFF5F766C)))
          : Column(children: [
              for (final e in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      Text(larasRupiah(e.value),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(
                          width: 44,
                          child: Text(
                              '${total == 0 ? 0 : (e.value * 100 / total).round()}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF5F766C)))),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            minHeight: 7,
                            value: total == 0 ? 0 : e.value / total,
                            color: color,
                            backgroundColor: color.withValues(alpha: .15))),
                  ]),
                ),
            ]),
    );
  }

  Widget _costStructure(CashflowAnalysis a) {
    final t = a.variable + a.fixed;
    Widget row(String l, int v, String note) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(note, style: const TextStyle(fontSize: 11.5)),
        trailing: Text(
            '${larasRupiah(v)} · ${t == 0 ? 0 : (v * 100 / t).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w900)));
    return _card(
      'Struktur biaya',
      Column(children: [
        row('Biaya variabel', a.variable,
            'Ikut naik-turun dengan produksi: bahan, kemasan, ongkir'),
        row('Biaya tetap & lainnya', a.fixed,
            'Relatif tetap: upah, sewa, listrik, operasional'),
      ]),
    );
  }

  Widget _materialImpact(CashflowAnalysis a) => _card(
        'Pengaruh harga bahan baku',
        a.impacts.isEmpty
            ? const Text(
                'Belum ada perubahan harga bahan. Ubah harga di menu Supplier untuk melihat dampaknya ke kas.',
                style: TextStyle(color: Color(0xFF5F766C)))
            : Column(children: [
                for (final m in a.impacts)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        m.pct > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: m.pct > 0 ? _red : _gold),
                    title: Text(m.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${m.pct > 0 ? 'Naik' : 'Turun'} ${(m.pct.abs() * 100).round()}% · belanja periode ini ${larasRupiah(m.spend)}',
                        style: const TextStyle(fontSize: 11.5)),
                    trailing: Text(
                        m.spend == 0
                            ? '-'
                            : '${m.extra >= 0 ? '+' : '-'}${larasRupiah(m.extra.abs())}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: m.extra > 0 ? _red : _gold)),
                  ),
                const Divider(),
                Text(
                    'Total efek harga ke uang keluar: ${a.extraFromPrices >= 0 ? '+' : '-'}${larasRupiah(a.extraFromPrices.abs())}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
        subtitle: 'Estimasi dari riwayat harga terakhir di menu Supplier',
      );

  Widget _simulator(CashflowAnalysis a) {
    final inP = a.inflow * (1 + _salesShift / 100);
    final bahanP =
        a.bahanBaku * (1 + _salesShift / 100) * (1 + _priceShock / 100);
    final outP = (a.outflow - a.bahanBaku) + bahanP;
    final netP = (inP - outP).round();
    Widget slider(String label, double v, double min, double max,
            ValueChanged<double> on, Key k) =>
        Column(children: [
          Row(children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${v >= 0 ? '+' : ''}${v.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          Slider(
              key: k,
              value: v,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: on),
        ]);
    return _card(
      'Simulasi "bagaimana jika"',
      Column(children: [
        slider(
            'Harga bahan baku',
            _priceShock,
            -20,
            40,
            (v) => setState(() => _priceShock = v),
            const Key('cashflow_price_slider')),
        slider(
            'Volume penjualan',
            _salesShift,
            -30,
            30,
            (v) => setState(() => _salesShift = v),
            const Key('cashflow_sales_slider')),
        const Divider(),
        Row(children: [
          const Expanded(child: Text('Arus kas bersih (proyeksi)')),
          Text('${netP < 0 ? '-' : ''}${larasRupiah(netP.abs())}',
              key: const Key('cashflow_projected_net'),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: netP < 0 ? _red : null)),
        ]),
        const SizedBox(height: 4),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Selisih dari kondisi sekarang: ${netP - a.net >= 0 ? '+' : '-'}${larasRupiah((netP - a.net).abs())}',
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF5F766C)))),
      ]),
      subtitle:
          'Geser untuk melihat efek ke kas. Anggap bahan baku ikut naik-turun dengan penjualan.',
    );
  }

  Widget _insights(CashflowAnalysis a) => _card(
        'Analisa & saran',
        Column(children: [
          for (final t in cashflowInsights(a))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(t.$1, size: 20, color: _gold),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(t.$2, style: const TextStyle(height: 1.35))),
              ]),
            ),
          const Text(
              'Saran otomatis dari data catatanmu, bukan nasihat keuangan.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5F766C))),
        ]),
      );
}
