import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'laras_operations_page.dart';
import 'chat_parser.dart';
import 'debt_page.dart' show kDebtsKey;

const _yellow = Color(0xFF14935A);
const _ink = Color(0xFF123126);
const _gold = Color(0xFF0B5D3B);
const _amber = Color(0xFF8A5A00);
const _red = Color(0xFF8A5A00);
const _muted = Color(0xFF5F766C);

const sampleChat =
    'Kak, mau pesan 2 batik cap kawung sama 1 kemeja batik pria ya. Atas nama Bu Ani. DP 200rb dulu, sisanya nanti pas ambil tgl 20 nov';

class _ItemEdit {
  _ItemEdit(this.item)
      : name = TextEditingController(text: item.name),
        qty = TextEditingController(
            text: item.qty == item.qty.roundToDouble()
                ? '${item.qty.round()}'
                : '${item.qty}'),
        price = TextEditingController(
            text: item.unitPrice == 0 ? '' : '${item.unitPrice}');
  final ParsedItem item;
  final TextEditingController name, qty, price;
  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

/// Tempel chat WhatsApp/Instagram -> LARAS membaca pesanan -> pengguna
/// memeriksa dan memperbaiki -> disimpan ke Catatan (dan Utang & Piutang).
class ChatPastePage extends StatefulWidget {
  const ChatPastePage({super.key});
  @override
  State<ChatPastePage> createState() => _ChatPastePageState();
}

class _ChatPastePageState extends State<ChatPastePage> {
  final _repo = LarasLocalRepository();
  final _chat = TextEditingController();
  final _customer = TextEditingController();
  final _paid = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  ParsedOrder? _order;
  final _rows = <_ItemEdit>[];
  PayStatus _pay = PayStatus.lunas;
  DateTime? _due;
  bool _payGuessed = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _repo.read(LarasLocalRepository.products).then((p) {
      if (mounted) _products = p;
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _chat.dispose();
    _customer.dispose();
    _paid.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _process() {
    final o = parseChatOrder(_chat.text, products: _products);
    for (final r in _rows) {
      r.dispose();
    }
    _rows
      ..clear()
      ..addAll(o.items.map(_ItemEdit.new));
    setState(() {
      _order = o;
      _customer.text = o.customer ?? '';
      _payGuessed = o.pay == PayStatus.tidakJelas;
      _pay = o.pay == PayStatus.tidakJelas ? PayStatus.lunas : o.pay;
      _paid.text = o.paid > 0 ? '${o.paid}' : '';
      _due = o.due ?? DateTime.now().add(const Duration(days: 14));
    });
  }

  int get _total => _rows.fold(0, (s, r) => s + r.item.subtotal);

  void _syncRow(_ItemEdit r) {
    r.item.name = r.name.text.trim();
    r.item.qty = double.tryParse(r.qty.text.replaceAll(',', '.')) ?? 0;
    r.item.unitPrice = int.tryParse(r.price.text) ?? 0;
    setState(() {});
  }

  int get _paidValue => int.tryParse(_paid.text) ?? 0;

  /// Daftar alasan kenapa tombol Simpan belum aktif.
  List<String> get _problems {
    final p = <String>[];
    if (_rows.isEmpty) p.add('Tambahkan minimal satu barang.');
    for (final r in _rows) {
      if (r.item.name.isEmpty) p.add('Ada barang yang belum diberi nama.');
      if (r.item.qty <= 0) p.add('Jumlah "${r.item.name}" harus lebih dari 0.');
      if (r.item.unitPrice <= 0) {
        p.add('Harga "${r.item.name}" belum diisi.');
      }
    }
    if (_pay == PayStatus.sebagian &&
        (_paidValue <= 0 || _paidValue >= _total)) {
      p.add('Jumlah DP harus lebih dari 0 dan kurang dari total.');
    }
    return p.toSet().toList();
  }

  String get _summaryName {
    final first = _rows.isEmpty ? 'pesanan' : _rows.first.item.name;
    final more = _rows.length > 1 ? ' +${_rows.length - 1}' : '';
    return '$first$more';
  }

  Future<void> _save() async {
    if (_problems.isNotEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final who = _customer.text.trim();
      final label = who.isEmpty ? 'Tanpa nama' : who;
      final now = DateTime.now().toIso8601String();
      final total = _total;
      final income = await _repo.read(LarasLocalRepository.income);
      final newIncome = <Map<String, dynamic>>[];
      Map<String, dynamic>? debt;
      final note = _rows.map((r) => '${r.item.name} x${r.qtyText}').join(', ');
      if (_pay == PayStatus.lunas) {
        newIncome.add(_income('Pesanan $label ($_summaryName)', total, now));
      } else {
        final paid = _pay == PayStatus.sebagian ? _paidValue : 0;
        if (paid > 0) newIncome.add(_income('DP $label', paid, now));
        debt = {
          'id': _repo.id(),
          'kind': 'piutang',
          'party': label,
          'amount': total,
          'paid': paid,
          'due': (_due ?? DateTime.now().add(const Duration(days: 14)))
              .toIso8601String(),
          'note': note,
          'createdAt': now,
          'payments': [
            if (paid > 0) {'amount': paid, 'at': now}
          ],
        };
      }
      if (newIncome.isNotEmpty) {
        await _repo
            .write(LarasLocalRepository.income, [...newIncome, ...income]);
      }
      if (debt != null) {
        final debts = await _repo.read(kDebtsKey);
        await _repo.write(kDebtsKey, [debt, ...debts]);
      }
      if (who.isNotEmpty) {
        final customers = await _repo.read(LarasLocalRepository.customers);
        final exists = customers
            .any((c) => '${c['name']}'.toLowerCase() == who.toLowerCase());
        if (!exists) {
          await _repo.write(LarasLocalRepository.customers, [
            {
              'id': _repo.id(),
              'name': who,
              'detail': 'Ditambahkan dari Tempel Chat',
              'createdAt': now,
            },
            ...customers,
          ]);
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pesanan belum tersimpan. Coba lagi.')));
      }
    }
  }

  Map<String, dynamic> _income(String name, int amount, String at) => {
        'id': _repo.id(),
        'name': name,
        'amount': amount,
        'category': 'Pesanan usaha',
        'date': at,
        'source': 'Tempel chat',
      };

  @override
  Widget build(BuildContext context) {
    final verifying = _order != null;
    return PopScope(
      canPop: !verifying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && verifying) setState(() => _order = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(verifying ? 'Periksa Pesanan' : 'Tempel Chat',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(child: verifying ? _verify() : _paste()),
      ),
    );
  }

  // ---------- Langkah 1: tempel ----------
  Widget _paste() => ListView(
        key: const Key('chat_paste_step'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          const Text(
              'Salin pesan pesanan dari WhatsApp atau caption Instagram, lalu tempel di sini. LARAS akan membaca barang, jumlah, harga, dan pembayarannya.',
              style: TextStyle(color: _muted, height: 1.45)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('chat_input'),
            controller: _chat,
            minLines: 9,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Tempel chat di sini...',
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.all(16)),
          ),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.spaceBetween, children: [
            TextButton.icon(
              key: const Key('chat_sample'),
              onPressed: () => setState(() => _chat.text = sampleChat),
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('Isi contoh'),
            ),
            TextButton.icon(
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                if (d?.text != null && mounted) {
                  setState(() => _chat.text = d!.text!);
                }
              },
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Tempel dari salinan'),
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('chat_process'),
            onPressed: _chat.text.trim().isEmpty ? null : _process,
            style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54)),
            child: const Text('Proses dengan LARAS',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          const Text(
              'Hasil bacaan selalu kamu periksa dulu sebelum disimpan. Chat tidak dikirim ke mana pun, semuanya diproses di HP-mu.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4)),
        ],
      );

  // ---------- Langkah 2: verifikasi ----------
  Widget _flag(bool ok,
          {String okText = 'Terbaca', String warnText = 'Periksa'}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: (ok ? _gold : _amber).withValues(alpha: .14),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              size: 13, color: ok ? _gold : _amber),
          const SizedBox(width: 4),
          Text(ok ? okText : warnText,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ok ? _gold : _amber)),
        ]),
      );

  Widget _section(String title, Widget flag, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15))),
              flag,
            ]),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  Widget _verify() {
    final o = _order!;
    final problems = _problems;
    final okItems = _rows.isNotEmpty && _rows.every((r) => !r.item.needsCheck);
    final checks = [
      _customer.text.trim().isNotEmpty,
      okItems,
      !_payGuessed,
    ];
    final good = checks.where((c) => c).length;
    final total = _total;
    final diff = o.statedTotal == null ? 0 : o.statedTotal! - total;

    return Column(children: [
      Expanded(
        child: ListView(
          key: const Key('chat_verify_step'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: (good == checks.length ? _yellow : _amber)
                      .withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(
                    good == checks.length
                        ? Icons.fact_check_outlined
                        : Icons.rule_rounded,
                    color: _gold),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        good == checks.length
                            ? 'Semua data terbaca. Cek sekali lagi lalu simpan.'
                            : 'LARAS membaca $good dari ${checks.length} bagian. Periksa yang bertanda "Periksa".',
                        style: const TextStyle(height: 1.35))),
              ]),
            ),
            const SizedBox(height: 12),
            _section(
              'Pelanggan',
              _flag(_customer.text.trim().isNotEmpty,
                  warnText: 'Belum ada nama'),
              TextField(
                key: const Key('chat_customer'),
                controller: _customer,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Nama pelanggan (opsional)'),
              ),
            ),
            const SizedBox(height: 12),
            _section(
              'Barang pesanan',
              _flag(okItems, warnText: 'Periksa harga'),
              Column(spacing: 12, children: [
                for (final (i, r) in _rows.indexed) _itemEditor(i, r),
                OutlinedButton.icon(
                  key: const Key('chat_add_item'),
                  onPressed: () => setState(
                      () => _rows.add(_ItemEdit(ParsedItem(name: '', qty: 1)))),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah barang'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44)),
                ),
                Row(children: [
                  const Expanded(
                      child: Text('Total pesanan',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  Text(larasRupiah(total),
                      key: const Key('chat_total'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                ]),
                if (o.statedTotal != null && diff != 0)
                  _totalMismatch(o.statedTotal!, diff),
              ]),
            ),
            const SizedBox(height: 12),
            _section(
              'Pembayaran',
              _flag(!_payGuessed, warnText: 'Tidak tertulis'),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    if (_payGuessed)
                      const Text(
                          'Status bayar tidak tertulis di chat. Pilih yang sesuai.',
                          style: TextStyle(fontSize: 12.5, color: _amber)),
                    Wrap(spacing: 8, children: [
                      for (final e in const {
                        PayStatus.lunas: 'Lunas',
                        PayStatus.sebagian: 'Sebagian (DP)',
                        PayStatus.belum: 'Belum bayar',
                      }.entries)
                        ChoiceChip(
                          key: Key('chat_pay_${e.key.name}'),
                          label: Text(e.value),
                          showCheckmark: false,
                          selected: _pay == e.key,
                          onSelected: (_) => setState(() {
                            _pay = e.key;
                            _payGuessed = false;
                          }),
                        ),
                    ]),
                    if (_pay == PayStatus.sebagian)
                      TextField(
                        key: const Key('chat_paid'),
                        controller: _paid,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            labelText: 'Sudah dibayar / DP (Rp)'),
                      ),
                    if (_pay != PayStatus.lunas)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              initialDate: _due ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100));
                          if (d != null) setState(() => _due = d);
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                            'Jatuh tempo: ${_due == null ? '-' : '${_due!.day}/${_due!.month}/${_due!.year}'}'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46)),
                      ),
                    Text(
                        switch (_pay) {
                          PayStatus.lunas =>
                            'Dicatat sebagai uang masuk ${larasRupiah(total)}.',
                          PayStatus.sebagian =>
                            'DP dicatat sebagai uang masuk, sisanya masuk Utang & Piutang.',
                          _ =>
                            'Seluruhnya masuk Utang & Piutang sampai dibayar.',
                        },
                        style: const TextStyle(fontSize: 12, color: _muted)),
                  ]),
            ),
            const SizedBox(height: 12),
            Card(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Lihat chat asli',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_chat.text,
                        style: const TextStyle(height: 1.4, color: _muted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: Color(0xFFDDE9E2)))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (problems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(problems.first,
                  key: const Key('chat_problem'),
                  style: const TextStyle(fontSize: 12.5, color: _red)),
            ),
          Row(children: [
            TextButton(
              onPressed: () => setState(() => _order = null),
              child: const Text('Ubah chat'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: const Key('chat_save'),
                onPressed: problems.isEmpty && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('Simpan pesanan',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }

  Widget _totalMismatch(int stated, int diff) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _amber.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Di chat tertulis total ${larasRupiah(stated)}, hasil hitungan ${larasRupiah(_total)}. Periksa jumlah dan harga.',
              style: const TextStyle(fontSize: 12.5, height: 1.35)),
          if (diff > 0)
            TextButton(
              key: const Key('chat_fix_total'),
              onPressed: () => setState(() => _rows.add(_ItemEdit(ParsedItem(
                  name: 'Biaya lain / ongkir', qty: 1, unitPrice: diff)))),
              child: Text(
                  'Tambah selisih ${larasRupiah(diff)} sebagai biaya lain'),
            ),
        ]),
      );

  Widget _itemEditor(int i, _ItemEdit r) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(
                color: r.item.needsCheck
                    ? _amber.withValues(alpha: .6)
                    : const Color(0xFFDDE9E2)),
            borderRadius: BorderRadius.circular(14)),
        child: Column(spacing: 10, children: [
          Row(children: [
            Expanded(
              child: TextField(
                key: Key('chat_item_name_$i'),
                controller: r.name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _syncRow(r),
                decoration: const InputDecoration(labelText: 'Nama barang'),
              ),
            ),
            IconButton(
              tooltip: 'Hapus barang',
              onPressed: () => setState(() {
                _rows.remove(r);
                r.dispose();
              }),
              icon: const Icon(Icons.delete_outline),
            ),
          ]),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                SizedBox(
                  width: 86,
                  child: TextField(
                    key: Key('chat_item_qty_$i'),
                    controller: r.qty,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _syncRow(r),
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: Key('chat_item_price_$i'),
                    controller: r.price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncRow(r),
                    decoration: InputDecoration(
                        labelText: 'Harga satuan (Rp)',
                        helperText:
                            r.item.fromCatalog ? 'Dari Produk & Stok' : null),
                  ),
                ),
              ]),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Subtotal ${larasRupiah(r.item.subtotal)}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

extension on _ItemEdit {
  String get qtyText => item.qty == item.qty.roundToDouble()
      ? '${item.qty.round()}'
      : '${item.qty}';
}
