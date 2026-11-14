import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'laras_operations_page.dart';
import 'cashflow_page.dart';

const kReserveKey = 'laras_reserve_v1';

const _yellow = Color(0xFF14935A);
const _gold = Color(0xFF0B5D3B);
const _red = Color(0xFF8A5A00);
const _muted = Color(0xFF5F766C);

class BepResult {
  BepResult({
    required this.fixedMonthly,
    required this.revenueMonthly,
    required this.variableRatio,
    required this.targetProfit,
  });
  final double fixedMonthly, revenueMonthly, variableRatio;
  final int targetProfit;

  /// Margin kontribusi: bagian tiap rupiah penjualan yang tersisa setelah
  /// biaya variabel, untuk menutup biaya tetap dan menjadi laba.
  double get contribution => 1 - variableRatio;
  bool get feasible => contribution > 0.0001;
  double get bep => feasible ? fixedMonthly / contribution : double.infinity;
  double get targetRevenue =>
      feasible ? (fixedMonthly + targetProfit) / contribution : double.infinity;
  double get safetyMargin =>
      revenueMonthly <= 0 ? 0 : (revenueMonthly - bep) / revenueMonthly;
}

/// shortcut: biaya tetap/variabel ditebak dari kata kunci kategori (lihat
/// isVariableCost); upgrade ke penandaan eksplisit bila perlu lebih akurat.
BepResult computeBep(CashflowAnalysis a, {int targetProfit = 0}) {
  final k = a.days == 0 ? 1.0 : 30 / a.days;
  return BepResult(
    fixedMonthly: a.fixed * k,
    revenueMonthly: a.inflow * k,
    variableRatio: a.inflow == 0 ? 0 : a.variable / a.inflow,
    targetProfit: targetProfit,
  );
}

class ReserveResult {
  ReserveResult(
      {required this.cash,
      required this.months,
      required this.fixedMonthly,
      required this.outflowMonthly});
  final int cash, months;
  final double fixedMonthly, outflowMonthly;

  double get target => fixedMonthly * months;
  double get gap => (target - cash).clamp(0, double.infinity);
  double get progress => target <= 0 ? 0 : (cash / target).clamp(0, 1);

  /// Hari bertahan bila tidak ada penjualan sama sekali (hanya biaya tetap).
  double? get runwayMinimalDays =>
      fixedMonthly <= 0 ? null : cash / (fixedMonthly / 30);

  /// Hari bertahan bila semua pengeluaran berjalan seperti biasa tanpa penjualan.
  double? get runwayNormalDays =>
      outflowMonthly <= 0 ? null : cash / (outflowMonthly / 30);
}

class BreakEvenPage extends StatefulWidget {
  const BreakEvenPage({super.key});
  @override
  State<BreakEvenPage> createState() => _BreakEvenPageState();
}

class _BreakEvenPageState extends State<BreakEvenPage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _income = [], _expenses = [];
  bool _loaded = false;
  int _days = 30;
  int _cash = 0, _months = 3;
  int _targetProfit = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final i = await _repo.read(LarasLocalRepository.income);
    final e = await _repo.read(LarasLocalRepository.expenses);
    final r = await _repo.read(kReserveKey);
    if (!mounted) return;
    setState(() {
      _income = i;
      _expenses = e;
      if (r.isNotEmpty) {
        _cash = (r.first['cash'] as num?)?.toInt() ?? 0;
        _months = (r.first['months'] as num?)?.toInt() ?? 3;
      }
      _loaded = true;
    });
  }

  Future<void> _saveReserve() => _repo.write(kReserveKey, [
        {'cash': _cash, 'months': _months}
      ]);

  CashflowAnalysis get _analysis {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    return analyzeCashflow(
        income: _income,
        expenses: _expenses,
        materials: const [],
        range: DateTimeRange(
            start: end.subtract(Duration(days: _days - 1)), end: end));
  }

  Future<void> _editCash() async {
    final c = TextEditingController(text: _cash == 0 ? '' : '$_cash');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo kas & dana cadangan'),
        content: TextField(
            key: const Key('reserve_cash_field'),
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Uang yang kamu pegang sekarang (Rp)',
                border: OutlineInputBorder())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              key: const Key('reserve_cash_save'),
              onPressed: () => Navigator.pop(ctx, int.tryParse(c.text) ?? 0),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (v == null) return;
    setState(() => _cash = v);
    await _saveReserve();
  }

  String _rp(num v) => '${v < 0 ? '-' : ''}${larasRupiah(v.abs())}';

  Widget _card(String title, String subtitle, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: _muted))),
            child,
          ]),
        ),
      );

  Widget _row(String l, String v, {Color? color, String? note}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l),
                if (note != null)
                  Text(note,
                      style: const TextStyle(fontSize: 11, color: _muted)),
              ])),
          Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    final bep = computeBep(a, targetProfit: _targetProfit);
    final reserve = ReserveResult(
        cash: _cash,
        months: _months,
        fixedMonthly: bep.fixedMonthly,
        outflowMonthly: a.outflow * (a.days == 0 ? 1 : 30 / a.days));
    return Scaffold(
      appBar: AppBar(
          title: const Text('Titik Impas & Dana Cadangan',
              style: TextStyle(fontWeight: FontWeight.w900))),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: const Key('bep_page'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text('Dihitung dari data'),
                        for (final d in const [30, 90])
                          ChoiceChip(
                            label: Text('$d hari'),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            selected: _days == d,
                            onSelected: (_) => setState(() => _days = d),
                          ),
                      ]),
                  const SizedBox(height: 8),
                  _bepCard(bep),
                  const SizedBox(height: 14),
                  _reserveCard(reserve, a),
                ],
              ),
      ),
    );
  }

  Widget _bepCard(BepResult b) {
    final enough = b.feasible && b.revenueMonthly >= b.bep;
    return _card(
      'Titik Impas (BEP)',
      'Omzet minimal per bulan supaya usaha tidak rugi',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!b.feasible)
          const Text(
              'Biaya variabel (bahan, kemasan, dll) sudah sama dengan atau melebihi omzet, jadi usaha tidak akan impas berapa pun penjualannya. Cek harga jual dan harga bahan.',
              style: TextStyle(color: _red, height: 1.35))
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _yellow.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('OMZET IMPAS PER BULAN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_rp(b.bep),
                  key: const Key('bep_value'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text('≈ ${_rp(b.bep / 30)} per hari',
                  style: const TextStyle(fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  minHeight: 9,
                  value:
                      b.bep <= 0 ? 1 : (b.revenueMonthly / b.bep).clamp(0, 1),
                  color: enough ? _yellow : _red,
                  backgroundColor: _yellow.withValues(alpha: .2))),
          const SizedBox(height: 6),
          Text(
              enough
                  ? 'Omzet bulananmu ${_rp(b.revenueMonthly)} sudah di atas titik impas. Batas aman ${(b.safetyMargin * 100).round()}%: omzet boleh turun sebesar itu sebelum rugi.'
                  : 'Omzet bulananmu ${_rp(b.revenueMonthly)}, masih kurang ${_rp(b.bep - b.revenueMonthly)} dari titik impas.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.35, color: enough ? null : _red)),
        ],
        const Divider(height: 24),
        _row('Biaya tetap per bulan', _rp(b.fixedMonthly),
            note: 'Upah, sewa, listrik, dan biaya rutin lain'),
        _row('Biaya variabel per Rp1 penjualan',
            'Rp${(b.variableRatio * 1000).round()} / 1000',
            note: 'Bahan baku, kemasan, ongkir: ikut naik dengan penjualan'),
        _row('Margin kontribusi', '${(b.contribution * 100).round()}%',
            note:
                'Sisa tiap penjualan untuk menutup biaya tetap dan jadi laba'),
        const Divider(height: 24),
        const Text('Target laba bulanan',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
            key: const Key('bep_target_field'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) =>
                setState(() => _targetProfit = int.tryParse(v) ?? 0),
            decoration: const InputDecoration(
                labelText: 'Laba yang kamu inginkan (Rp)',
                border: OutlineInputBorder())),
        if (_targetProfit > 0 && b.feasible) ...[
          const SizedBox(height: 8),
          Text(
              'Untuk laba ${_rp(_targetProfit)} per bulan, omzet yang dibutuhkan ${_rp(b.targetRevenue)}.',
              key: const Key('bep_target_result'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }

  Widget _reserveCard(ReserveResult r, CashflowAnalysis a) {
    String days(double? d) => d == null
        ? '-'
        : d >= 60
            ? '${d.round()} hari (±${(d / 30).toStringAsFixed(1)} bulan)'
            : '${d.round()} hari';
    return _card(
      'Dana Cadangan',
      'Seberapa lama usaha bertahan kalau penjualan terhenti',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _yellow.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SALDO KAS SAAT INI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_rp(r.cash),
                  key: const Key('reserve_cash_value'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
          )),
          const SizedBox(width: 8),
          IconButton.filledTonal(
              key: const Key('reserve_edit'),
              tooltip: 'Ubah saldo',
              onPressed: _editCash,
              icon: const Icon(Icons.edit_outlined)),
        ]),
        const SizedBox(height: 12),
        _row('Bertahan tanpa penjualan (hanya biaya tetap)',
            days(r.runwayMinimalDays),
            color: (r.runwayMinimalDays ?? 999) < 30 ? _red : _gold),
        _row('Bertahan bila semua biaya jalan normal', days(r.runwayNormalDays),
            color: (r.runwayNormalDays ?? 999) < 30 ? _red : _gold),
        const Divider(height: 24),
        const Text('Target dana darurat',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          for (final m in const [3, 6, 9])
            ChoiceChip(
              label: Text('$m bulan'),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selected: _months == m,
              onSelected: (_) {
                setState(() => _months = m);
                _saveReserve();
              },
            ),
        ]),
        const SizedBox(height: 10),
        _row('Target (biaya tetap × $_months bulan)', _rp(r.target)),
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                minHeight: 9,
                value: r.progress,
                color: _yellow,
                backgroundColor: _yellow.withValues(alpha: .2))),
        const SizedBox(height: 6),
        Text(
            r.target <= 0
                ? 'Belum ada biaya tetap tercatat, jadi target belum bisa dihitung.'
                : r.gap == 0
                    ? 'Target dana darurat sudah tercapai.'
                    : 'Terkumpul ${(r.progress * 100).round()}%, kurang ${_rp(r.gap)}.${a.net > 0 ? ' Dengan laba sekarang (${_rp(a.net * (30 / a.days))}/bulan) target tercapai dalam ±${(r.gap / (a.net * (30 / a.days))).ceil()} bulan bila seluruh laba disisihkan.' : ''}',
            style: const TextStyle(fontSize: 12.5, height: 1.35)),
        const SizedBox(height: 8),
        const Text(
            'Saldo kas diisi manual dan hanya tersimpan di HP ini. Hasil adalah estimasi dari catatanmu, bukan nasihat keuangan.',
            style: TextStyle(fontSize: 11, color: _muted)),
      ]),
    );
  }
}
