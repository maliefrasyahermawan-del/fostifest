import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'laras_operations_page.dart';

const kDebtsKey = 'laras_debts_v1';

const _yellow = Color(0xFF14935A);
const _gold = Color(0xFF0B5D3B);
const _red = Color(0xFF8A5A00);
const _muted = Color(0xFF5F766C);

/// Satu catatan utang/piutang. kind: 'piutang' (pelanggan berutang ke kita)
/// atau 'utang' (kita berutang ke supplier).
/// {id, kind, party, amount, paid, due, note, createdAt, payments:[{amount, at}]}
int _int(Object? v) => v is num ? v.toInt() : 0;
int debtRemaining(Map<String, dynamic> d) =>
    (_int(d['amount']) - _int(d['paid'])).clamp(0, 1 << 40);

/// Data contoh utang & piutang untuk demo; tanggal dihitung dari [now].
List<Map<String, dynamic>> sampleDebts(DateTime now) {
  String at(int days) => now.add(Duration(days: days)).toIso8601String();
  Map<String, dynamic> d(String id, String kind, String party, int amount,
          int paid, int dueIn, String note,
          {int paidAgo = 7}) =>
      {
        'id': id,
        'kind': kind,
        'party': party,
        'amount': amount,
        'paid': paid,
        'due': at(dueIn),
        'note': note,
        'createdAt': at(-25),
        'payments': [
          if (paid > 0) {'amount': paid, 'at': at(-paidAgo)}
        ],
      };
  return [
    d('debt-1', 'piutang', 'Koperasi Seragam Sekolah', 3500000, 1000000, 5,
        'Pesanan seragam batik, DP sudah masuk'),
    d('debt-2', 'piutang', 'Dinda Maharani', 850000, 0, -4,
        'Pesanan kain batik tulis'),
    d('debt-3', 'piutang', 'Ibu Retno Wulandari', 1200000, 600000, 12,
        'Batik tulis Parang, dicicil dua kali'),
    d('debt-4', 'piutang', 'CV Sinar Seragam', 6400000, 0, 21,
        'Pesanan 40 seragam kantor'),
    d('debt-5', 'piutang', 'Toko Oleh-oleh Laweyan', 1800000, 0, -9,
        'Titip jual selendang, belum disetor'),
    d('debt-6', 'piutang', 'Bu Sari (Butik Kenanga)', 2250000, 2250000, -10,
        'Dress batik 5 pcs, sudah lunas',
        paidAgo: 3),
    d('debt-7', 'utang', 'Pedagang Mori Pasar Klewer', 1120000, 0, 2,
        'Kain mori, bayar tempo'),
    d('debt-8', 'utang', 'Toko Warna Batik Solo', 540000, 200000, 12,
        'Pewarna naptol, dicicil'),
    d('debt-9', 'utang', 'Toko Malam & Canting Laweyan', 650000, 0, -3,
        'Malam batik 10 kg'),
    d('debt-10', 'utang', 'Toko Sutra Kotagede', 900000, 0, 25,
        'Kain sutra untuk selendang'),
    d('debt-11', 'utang', 'Toko Kemasan Pasar Gede', 350000, 350000, -6,
        'Box dan label, sudah lunas',
        paidAgo: 2),
  ];
}

enum DebtStatus { lunas, terlambat, segera, berjalan }

DebtStatus debtStatus(Map<String, dynamic> d, DateTime now) {
  if (debtRemaining(d) == 0) return DebtStatus.lunas;
  final due = DateTime.tryParse('${d['due']}');
  if (due == null) return DebtStatus.berjalan;
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  if (dueDay.isBefore(today)) return DebtStatus.terlambat;
  if (dueDay.difference(today).inDays <= 3) return DebtStatus.segera;
  return DebtStatus.berjalan;
}

class DebtSummary {
  DebtSummary(List<Map<String, dynamic>> all, DateTime now) {
    for (final d in all) {
      final r = debtRemaining(d);
      if (r == 0) continue;
      final late = debtStatus(d, now) == DebtStatus.terlambat;
      if (d['kind'] == 'piutang') {
        piutang += r;
        if (late) piutangLate += r;
      } else {
        utang += r;
        if (late) utangLate += r;
      }
    }
  }
  int piutang = 0, utang = 0, piutangLate = 0, utangLate = 0;
  int get net => piutang - utang;
}

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});
  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  final _repo = LarasLocalRepository();
  List<Map<String, dynamic>> _all = [];
  bool _loaded = false;
  String _kind = 'piutang';
  bool _showPaid = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.read(kDebtsKey);
    if (!mounted) return;
    setState(() {
      _all = rows;
      _loaded = true;
    });
  }

  Future<void> _save() => _repo.write(kDebtsKey, _all);

  String _date(String? iso) {
    final d = DateTime.tryParse('$iso');
    return d == null ? '-' : '${d.day}/${d.month}/${d.year}';
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _addOrEdit() async {
    final party = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    DateTime? due = DateTime.now().add(const Duration(days: 14));
    final isPiutang = _kind == 'piutang';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPiutang ? 'Catat piutang baru' : 'Catat utang baru',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      isPiutang
                          ? 'Pelanggan yang belum membayar pesanan.'
                          : 'Belanja ke supplier yang belum kamu bayar.',
                      style: const TextStyle(fontSize: 12, color: _muted)),
                  const SizedBox(height: 14),
                  TextField(
                      key: const Key('debt_party'),
                      controller: party,
                      decoration: InputDecoration(
                          labelText:
                              isPiutang ? 'Nama pelanggan' : 'Nama supplier',
                          border: const OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('debt_amount'),
                      controller: amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Nominal (Rp)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: () async {
                        final p = await showDatePicker(
                            context: ctx,
                            initialDate: due ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100));
                        if (p != null) setSheet(() => due = p);
                      },
                      icon: const Icon(Icons.event_outlined),
                      label:
                          Text('Jatuh tempo: ${_date(due?.toIso8601String())}'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: note,
                      decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  FilledButton(
                      key: const Key('debt_save'),
                      onPressed: () {
                        final v = int.tryParse(amount.text) ?? 0;
                        if (party.text.trim().isEmpty || v <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content:
                                  Text('Isi nama dan nominal lebih dari 0.')));
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: _yellow,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52)),
                      child: const Text('Simpan')),
                ]),
          ),
        ),
      ),
    );
    if (saved != true) return;
    final entry = {
      'id': _repo.id(),
      'kind': _kind,
      'party': party.text.trim(),
      'amount': int.parse(amount.text),
      'paid': 0,
      'due': due?.toIso8601String(),
      'note': note.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'payments': <Map<String, dynamic>>[],
    };
    setState(() => _all = [entry, ..._all]);
    await _save();
    _toast('Tersimpan.');
  }

  /// Pembayaran dicatat juga sebagai uang masuk (piutang) / uang keluar (utang)
  /// supaya Cashflow dan laporan ikut terbarui.
  Future<void> _pay(Map<String, dynamic> d) async {
    final remaining = debtRemaining(d);
    final ctrl = TextEditingController(text: '$remaining');
    final isPiutang = d['kind'] == 'piutang';
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPiutang ? 'Terima pembayaran' : 'Bayar utang'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${d['party']} · sisa ${larasRupiah(remaining)}'),
          const SizedBox(height: 12),
          TextField(
              key: const Key('debt_pay_amount'),
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              key: const Key('debt_pay_confirm'),
              onPressed: () {
                final v = int.tryParse(ctrl.text) ?? 0;
                Navigator.pop(ctx, v);
              },
              child: const Text('Catat')),
        ],
      ),
    );
    if (value == null) return;
    if (value <= 0 || value > remaining) {
      _toast('Nominal harus antara 1 dan sisa ${larasRupiah(remaining)}.');
      return;
    }
    final now = DateTime.now().toIso8601String();
    d['paid'] = _int(d['paid']) + value;
    d['payments'] = [
      ...((d['payments'] as List?) ?? const []),
      {'amount': value, 'at': now}
    ];
    await _save();
    if (isPiutang) {
      final tx = await _repo.read(LarasLocalRepository.income);
      await _repo.write(LarasLocalRepository.income, [
        {
          'id': _repo.id(),
          'name': 'Pelunasan piutang ${d['party']}',
          'amount': value,
          'category': 'Pelunasan piutang',
          'date': now,
          'source': 'Utang & Piutang'
        },
        ...tx,
      ]);
    } else {
      final ex = await _repo.read(LarasLocalRepository.expenses);
      await _repo.write(LarasLocalRepository.expenses, [
        {
          'id': _repo.id(),
          'name': 'Bayar utang ${d['party']}',
          'detail': '${d['note'] ?? ''}',
          'amount': value,
          'category': 'Pembayaran utang',
          'createdAt': now,
          'source': 'Utang & Piutang'
        },
        ...ex,
      ]);
    }
    if (!mounted) return;
    setState(() {});
    _toast(isPiutang
        ? 'Pembayaran dicatat sebagai uang masuk.'
        : 'Pembayaran dicatat sebagai uang keluar.');
  }

  Future<void> _delete(Map<String, dynamic> d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text(
            '${d['party']} akan dihapus. Pembayaran yang sudah tercatat di Catatan keuangan tidak ikut terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _all = _all.where((e) => e['id'] != d['id']).toList());
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final s = DebtSummary(_all, now);
    final rows = _all
        .where((d) => d['kind'] == _kind)
        .where((d) => _showPaid || debtRemaining(d) > 0)
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse('${a['due']}') ?? DateTime(2100);
        final db = DateTime.tryParse('${b['due']}') ?? DateTime(2100);
        return da.compareTo(db);
      });
    return Scaffold(
      appBar: AppBar(
          title: const Text('Utang & Piutang',
              style: TextStyle(fontWeight: FontWeight.w900))),
      floatingActionButton: FloatingActionButton.extended(
          key: const Key('debt_add'),
          onPressed: _addOrEdit,
          backgroundColor: _yellow,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_kind == 'piutang' ? 'Catat piutang' : 'Catat utang')),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: const Key('debt_page'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Row(children: [
                    _tile(
                        'PIUTANG (AKAN MASUK)',
                        s.piutang,
                        _yellow,
                        s.piutangLate > 0
                            ? '${larasRupiah(s.piutangLate)} terlambat'
                            : 'Tidak ada yang terlambat'),
                    const SizedBox(width: 8),
                    _tile(
                        'UTANG (HARUS BAYAR)',
                        s.utang,
                        const Color(0xFF1F4D39),
                        s.utangLate > 0
                            ? '${larasRupiah(s.utangLate)} terlambat'
                            : 'Tidak ada yang terlambat'),
                  ]),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.balance_outlined, color: _gold),
                      title: const Text('Posisi bersih'),
                      subtitle: const Text('Piutang dikurangi utang'),
                      trailing: Text(
                          '${s.net < 0 ? '-' : ''}${larasRupiah(s.net.abs())}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: s.net < 0 ? _red : null)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'piutang', label: Text('Piutang')),
                      ButtonSegment(value: 'utang', label: Text('Utang')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (v) => setState(() => _kind = v.first),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Tampilkan yang sudah lunas'),
                    value: _showPaid,
                    onChanged: (v) => setState(() => _showPaid = v),
                  ),
                  if (rows.isEmpty)
                    Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(spacing: 12, children: [
                          Text(
                              _kind == 'piutang'
                                  ? 'Belum ada piutang. Catat pesanan yang belum dibayar pelanggan.'
                                  : 'Belum ada utang. Catat belanja yang belum kamu bayar ke supplier.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _muted)),
                          if (_all.isEmpty)
                            OutlinedButton.icon(
                              key: const Key('debt_seed'),
                              onPressed: () async {
                                setState(
                                    () => _all = sampleDebts(DateTime.now()));
                                await _save();
                              },
                              icon: const Icon(Icons.auto_fix_high_outlined),
                              label: const Text('Isi data contoh'),
                            ),
                        ]))
                  else
                    for (final d in rows) _row(d, now),
                  const SizedBox(height: 8),
                  const Text(
                      'Uang baru masuk ke Cashflow saat pembayaran dicatat, bukan saat piutang atau utang dibuat.',
                      style: TextStyle(fontSize: 11.5, color: _muted)),
                ],
              ),
      ),
    );
  }

  Widget _tile(String label, int v, Color c, String note) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: c.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(larasRupiah(v),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900))),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      );

  Widget _row(Map<String, dynamic> d, DateTime now) {
    final st = debtStatus(d, now);
    final (label, color) = switch (st) {
      DebtStatus.lunas => ('Lunas', _gold),
      DebtStatus.terlambat => ('Terlambat', _red),
      DebtStatus.segera => ('Segera jatuh tempo', const Color(0xFF8A5A00)),
      DebtStatus.berjalan => ('Berjalan', _muted),
    };
    final total = _int(d['amount']);
    final paid = _int(d['paid']);
    return Card(
      key: Key('debt_${d['id']}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('${d['party']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15))),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color))),
          ]),
          const SizedBox(height: 4),
          Text(
              'Jatuh tempo ${_date('${d['due']}')}${'${d['note']}'.isEmpty ? '' : ' · ${d['note']}'}',
              style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  minHeight: 7,
                  value: total == 0 ? 0 : paid / total,
                  color: _yellow,
                  backgroundColor: _yellow.withValues(alpha: .2))),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Sisa ${larasRupiah(debtRemaining(d))}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('dari ${larasRupiah(total)}',
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ])),
            Text('${total == 0 ? 0 : (paid * 100 / total).round()}% terbayar',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (st != DebtStatus.lunas)
              FilledButton.tonalIcon(
                  key: Key('debt_pay_${d['id']}'),
                  onPressed: () => _pay(d),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label:
                      Text(d['kind'] == 'piutang' ? 'Terima bayar' : 'Bayar')),
            const Spacer(),
            IconButton(
                tooltip: 'Hapus',
                onPressed: () => _delete(d),
                icon: const Icon(Icons.delete_outline)),
          ]),
        ]),
      ),
    );
  }
}
