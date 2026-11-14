/// Membaca chat pesanan (WhatsApp/Instagram) menjadi data pesanan.
///
/// shortcut: aturan kata kunci dan regex bahasa Indonesia, berjalan offline di
/// HP. Cukup untuk kalimat pesanan umum; upgrade ke model bahasa bila format
/// chat pelanggan sangat bebas. Hasilnya SELALU diverifikasi pengguna.
library;

enum PayStatus { lunas, sebagian, belum, tidakJelas }

class ParsedItem {
  ParsedItem({
    required this.name,
    this.qty = 1,
    this.unitPrice = 0,
    this.fromCatalog = false,
  });
  String name;
  double qty;
  int unitPrice;

  /// Nama dan harga dicocokkan dengan produk yang sudah ada di Produk & Stok.
  final bool fromCatalog;

  int get subtotal => (qty * unitPrice).round();
  bool get needsCheck => unitPrice <= 0 || qty <= 0;
}

class ParsedOrder {
  String? customer;
  final items = <ParsedItem>[];
  int? statedTotal; // total yang tertulis di chat
  PayStatus pay = PayStatus.tidakJelas;
  int paid = 0; // jumlah yang sudah dibayar (DP)
  DateTime? due;

  int get total => items.fold(0, (s, i) => s + i.subtotal);
  bool get totalMismatch => statedTotal != null && statedTotal != total;
}

class _Money {
  _Money(this.value, this.start, this.end, this.explicit);
  final int value;
  final int start, end;

  /// Ada "Rp" atau satuan rb/jt/k, jadi pasti uang (bukan jumlah barang).
  final bool explicit;
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'jun': 6, 'jul': 7,
  'agu': 8, 'agt': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12, //
};

final _moneyRe = RegExp(
    r'(rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d+)?)\s*(juta|jt|ribu|rb|k)?(?![a-z0-9])',
    caseSensitive: false);

List<_Money> _findMoney(String text) {
  final out = <_Money>[];
  for (final m in _moneyRe.allMatches(text)) {
    final rp = m.group(1) != null;
    final unit = m.group(3)?.toLowerCase();
    final raw = m.group(2)!;
    final grouped = RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(raw);
    double v;
    if (grouped) {
      v = double.parse(raw.replaceAll(RegExp(r'[.,]'), ''));
    } else {
      v = double.parse(raw.replaceAll(',', '.'));
    }
    if (unit != null) {
      v *= (unit == 'juta' || unit == 'jt') ? 1000000 : 1000;
    }
    final isMoney = rp || unit != null || grouped || v >= 10000;
    if (!isMoney) continue;
    out.add(_Money(v.round(), m.start, m.end, rp || unit != null));
  }
  return out;
}

String _blank(String s, int a, int b) => s.replaceRange(a, b, ' ' * (b - a));

const _units =
    r'(?:pcs|pc|buah|biji|potong|lembar|meter|mtr|set|kodi|lusin|stel|helai|botol|pak|kg|roll|m)';

const _stop = {
  'pesan', 'mau', 'order', 'beli', 'minta', 'kak', 'halo', 'hai', 'selamat',
  'pagi', 'siang', 'sore', 'malam', 'tolong', 'ya', 'dong', 'nih', 'yg',
  'yang', 'atas', 'nama', 'bu', 'pak', 'ibu', 'bapak', 'mbak', 'mas', 'tgl',
  'tanggal', 'dp', 'total', 'lunas', 'sudah', 'transfer', 'kirim', 'ambil',
  'diambil', 'dikirim', 'ke', 'di', 'jam', 'pukul', 'hari', 'minggu',
  'bulan', 'besok', 'lusa', 'dulu', 'sisanya', 'sisa', 'nanti', 'pas',
  'untuk', 'buat', 'dan', 'sama', 'dengan', 'itu', 'ini', 'saja', 'aja',
  'harga', 'per', 'tiap', 'ukuran', 'warna', 'size', 'terima', 'kasih',
  'makasih', 'trims', 'thanks', 'admin', 'toko', 'min', 'jadi', 'ada',
  'bisa', 'apa', 'berapa', 'cod', 'tf', 'bayar', //
};

String _title(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// [products]: daftar produk (map dengan 'name' dan 'price') untuk pencocokan.
ParsedOrder parseChatOrder(String raw,
    {List<Map<String, dynamic>> products = const [], DateTime? now}) {
  final today = now ?? DateTime.now();
  final order = ParsedOrder();

  // Buang awalan ekspor WhatsApp: "[12/11/25 10.23] Nama: " atau "12/11/25, 10.23 - Nama: ".
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((l) => l.replaceFirst(
          RegExp(
              r'^\s*\[?\d{1,2}/\d{1,2}/\d{2,4},?\s*\d{1,2}[.:]\d{2}(?::\d{2})?\]?\s*-?\s*[^:]{1,30}:\s*'),
          ''))
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final original = lines.join('\n');
  var work = original.toLowerCase();

  // --- nama pelanggan ---
  final cust = RegExp(
          r'\b(?:atas nama|a\.?\s?n\.?|nama(?:nya| saya)?)\s*[:=]?\s+((?:bu|ibu|pak|bapak|kak|mba|mbak|mas|bang)\.?\s+)?([a-z]+(?:\s+[a-z]+){0,2})',
          caseSensitive: false)
      .firstMatch(original);
  if (cust != null) {
    final words = ('${cust.group(1) ?? ''}${cust.group(2)!}')
        .trim()
        .split(RegExp(r'\s+'))
        .toList();
    // Berhenti di kata yang bukan bagian nama.
    final keep = <String>[];
    for (final w in words) {
      final lw = w.toLowerCase().replaceAll('.', '');
      if (keep.isNotEmpty && _stop.contains(lw)) break;
      keep.add(w);
    }
    if (keep.isNotEmpty) order.customer = _title(keep.join(' '));
    work = _blank(work, cust.start, cust.end);
  }

  // --- uang: total, DP, harga satuan ---
  final unitPrices = <_Money>[];
  var money = _findMoney(work);
  for (final m in money) {
    final before =
        work.substring((m.start - 22).clamp(0, work.length), m.start);
    final after = work.substring(m.end, (m.end + 12).clamp(0, work.length));
    if (RegExp(r'(dp|uang muka|panjar|bayar dulu|transfer dulu|tf dulu|cicil\w*)\s*(sebesar|senilai|=|:)?\s*(rp\.?)?\s*$')
            .hasMatch(before) ||
        RegExp(r'^\s*(dulu|dp)\b').hasMatch(after)) {
      order.paid = m.value;
      order.pay = PayStatus.sebagian;
    } else if (RegExp(
            r'(total|jumlah|semuanya|seluruhnya|ttl|jadi|sebesar|tagihan)\w*\s*(=|:)?\s*(rp\.?)?\s*$')
        .hasMatch(before)) {
      order.statedTotal = m.value;
    } else if (RegExp(r'sisa\w*\s*(=|:)?\s*(rp\.?)?\s*$').hasMatch(before)) {
      // sisa pembayaran: sudah tercermin dari total - DP
    } else {
      unitPrices.add(m);
    }
  }
  // Hapus semua uang dari teks kerja agar tidak dikira jumlah barang.
  for (final m in money.reversed) {
    work = _blank(work, m.start, m.end);
  }

  // --- tanggal jatuh tempo / ambil ---
  DateTime? due;
  final dm = RegExp(
          r'(?:tgl\.?|tanggal)?\s*(\d{1,2})\s*(jan|feb|mar|apr|mei|jun|jul|agu|agt|sep|okt|nov|des)[a-z]*(?:\s+(\d{2,4}))?')
      .firstMatch(work);
  final dn = RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b').firstMatch(work);
  if (dm != null) {
    var y = int.tryParse(dm.group(3) ?? '') ?? today.year;
    if (y < 100) y += 2000;
    due = DateTime(y, _months[dm.group(2)!]!, int.parse(dm.group(1)!));
    if (dm.group(3) == null &&
        due.isBefore(today.subtract(const Duration(days: 1)))) {
      due = DateTime(y + 1, due.month, due.day);
    }
    work = _blank(work, dm.start, dm.end);
  } else if (dn != null) {
    var y = int.tryParse(dn.group(3) ?? '') ?? today.year;
    if (y < 100) y += 2000;
    final mo = int.parse(dn.group(2)!), d = int.parse(dn.group(1)!);
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
      due = DateTime(y, mo, d);
      work = _blank(work, dn.start, dn.end);
    }
  } else if (RegExp(r'\bbesok\b').hasMatch(work)) {
    due = DateTime(today.year, today.month, today.day + 1);
  } else if (RegExp(r'\blusa\b').hasMatch(work)) {
    due = DateTime(today.year, today.month, today.day + 2);
  } else if (RegExp(r'minggu depan').hasMatch(work)) {
    due = DateTime(today.year, today.month, today.day + 7);
  } else if (RegExp(r'bulan depan').hasMatch(work)) {
    due = DateTime(today.year, today.month + 1, today.day);
  } else {
    final nd = RegExp(r'(\d+)\s*hari\s*(?:lagi|lg)').firstMatch(work);
    if (nd != null) {
      due = DateTime(
          today.year, today.month, today.day + int.parse(nd.group(1)!));
    }
  }
  order.due = due;
  // Nomor telepon panjang jangan dibaca sebagai jumlah.
  work = work.replaceAll(RegExp(r'\d{8,}'), ' ');

  // --- status bayar ---
  if (order.pay != PayStatus.sebagian) {
    if (RegExp(
            r'belum\s+(?:di)?bayar|bayar\s+nanti|nanti\s+bayar|bayar\s+(?:pas|saat|waktu)\s+(?:ambil|diambil|terima|datang)|\bcod\b|tempo|hutang|ngutang|kasbon|utang')
        .hasMatch(work)) {
      order.pay = PayStatus.belum;
    } else if (RegExp(
            r'lunas|(?:transfer|tf)\s+(?:sudah|udah|sdh)|(?:sudah|udah|sdh|dah)\s+(?:di)?(?:transfer|tf|bayar|dibayar|lunasi)|cash|tunai')
        .hasMatch(work)) {
      order.pay = PayStatus.lunas;
    }
  }

  // --- item: cocokkan dengan produk yang ada ---
  final used = <List<int>>[];
  bool overlaps(int a, int b) => used.any((u) => a < u[1] && b > u[0]);
  for (final p in products) {
    final full = '${p['name']}'.toLowerCase().trim();
    final core = full
        .replaceFirst(
            RegExp(r'\s+\d+(?:[.,]\d+)?\s*(?:m|cm|mtr|meter|kg|pcs)$'), '')
        .trim();
    var name = full;
    var idx = work.indexOf(name);
    if (idx < 0 && core.length >= 3) {
      name = core;
      idx = work.indexOf(name);
    }
    if (name.length < 3 || idx < 0 || overlaps(idx, idx + name.length))
      continue;
    final end = idx + name.length;
    double qty = 1;
    var qs = idx, qe = end;
    final pre = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:x\s*)?' + _units + r'?\s*$')
        .firstMatch(work.substring((idx - 14).clamp(0, idx), idx));
    final post = RegExp(
            r'^\s*(?:x|@)?\s*(\d+(?:[.,]\d+)?)\s*' + _units + r'?(?![\d.,a-z])')
        .firstMatch(work.substring(end, (end + 14).clamp(0, work.length)));
    if (pre != null) {
      qty = double.parse(pre.group(1)!.replaceAll(',', '.'));
      qs = idx -
          (work.substring((idx - 14).clamp(0, idx), idx).length - pre.start);
    } else if (post != null) {
      qty = double.parse(post.group(1)!.replaceAll(',', '.'));
      qe = end + post.end;
    }
    used.add([qs, qe]);
    order.items.add(ParsedItem(
        name: '${p['name']}',
        qty: qty,
        unitPrice: (p['price'] as num?)?.toInt() ?? 0,
        fromCatalog: true));
  }
  var rest = work;
  for (final u in used) {
    rest = _blank(rest, u[0], u[1]);
  }

  // --- item: nama bebas "2 batik tulis" ---
  final generic = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:x\s*)?' +
      _units +
      r'?\s+(?!' +
      _units +
      r'\b)([a-z][a-z0-9\-/ ]*?)(?=\s*(?:,|;|\n|\.|\bdan\b|\bsama\b|\+|@|\bdp\b|\btotal\b|\batas\b|\bya\b|\bkak\b|\buntuk\b|\bbuat\b|\bwarna\b|\bukuran\b|$))');
  for (final m in generic.allMatches(rest)) {
    final words = m
        .group(2)!
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    while (words.isNotEmpty && _stop.contains(words.first)) {
      words.removeAt(0);
    }
    while (words.isNotEmpty && _stop.contains(words.last)) {
      words.removeLast();
    }
    if (words.isEmpty || words.join(' ').length < 3) continue;
    final qty = double.parse(m.group(1)!.replaceAll(',', '.'));
    if (qty <= 0 || qty > 9999) continue;
    order.items
        .add(ParsedItem(name: _title(words.take(5).join(' ')), qty: qty));
  }

  // --- item: "seragam batik 30 pcs" (nama dulu, jumlah belakangan) ---
  if (order.items.isEmpty) {
    for (final seg in rest.split(RegExp(r'[,;\n.]'))) {
      final m = RegExp(r'^(.*?)(\d+(?:[.,]\d+)?)\s*' + _units + r'\b')
          .firstMatch(seg.trim());
      if (m == null) continue;
      final words = m
          .group(1)!
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      while (words.isNotEmpty && _stop.contains(words.first)) {
        words.removeAt(0);
      }
      while (words.isNotEmpty && _stop.contains(words.last)) {
        words.removeLast();
      }
      final qty = double.parse(m.group(2)!.replaceAll(',', '.'));
      if (words.isEmpty || qty <= 0 || qty > 9999) continue;
      order.items
          .add(ParsedItem(name: _title(words.take(5).join(' ')), qty: qty));
    }
  }

  // --- harga satuan untuk item yang belum punya harga ---
  final noPrice = order.items.where((i) => i.unitPrice == 0).toList();
  if (noPrice.length == 1 &&
      unitPrices.length == 1 &&
      order.items.length == 1) {
    noPrice.first.unitPrice = unitPrices.first.value;
  } else if (noPrice.length == 1 &&
      order.statedTotal != null &&
      order.items.length == 1) {
    final q = noPrice.first.qty;
    if (q > 0) noPrice.first.unitPrice = (order.statedTotal! / q).round();
  } else if (noPrice.isNotEmpty && unitPrices.length >= noPrice.length) {
    // Harga ditulis berurutan sesuai urutan item.
    for (var i = 0; i < noPrice.length; i++) {
      noPrice[i].unitPrice = unitPrices[i].value;
    }
  }

  // Satu item tanpa harga tapi ada total di chat: turunkan dari total.
  if (order.items.length == 1 &&
      order.items.first.unitPrice == 0 &&
      order.statedTotal != null &&
      order.items.first.qty > 0) {
    order.items.first.unitPrice =
        (order.statedTotal! / order.items.first.qty).round();
  }

  // Pembayaran sebagian yang nilainya sama dengan total = lunas.
  if (order.pay == PayStatus.sebagian &&
      order.statedTotal != null &&
      order.paid >= order.statedTotal!) {
    order.pay = PayStatus.lunas;
    order.paid = order.statedTotal!;
  }
  return order;
}
