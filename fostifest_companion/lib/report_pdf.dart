import 'package:flutter/material.dart' show DateTimeRange;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'break_even_page.dart' show computeBep;
import 'laras_operations_page.dart' show larasRupiah;
import 'cashflow_page.dart';
import 'debt_page.dart' show DebtSummary;

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus',
  'September', 'Oktober', 'November', 'Desember', //
];

String _pct(num v) => '${v.toStringAsFixed(v.abs() < 10 ? 1 : 0)}%';

String _delta(int now, int before) {
  if (before == 0) return 'periode lalu: -';
  final p = (now - before) * 100 / before.abs();
  return '${p >= 0 ? '+' : ''}${p.toStringAsFixed(0)}% vs periode lalu';
}

class MonthRow {
  MonthRow(this.year, this.month);
  final int year, month;
  int inflow = 0, outflow = 0;
  int get net => inflow - outflow;
  String get label => '${_monthNames[month - 1]} $year';
}

class ReportLine {
  ReportLine(this.date, this.name, this.category, this.source, this.amount);
  final DateTime date;
  final String name, category, source;
  final int amount;
}

class ReportInsight {
  ReportInsight(this.title, this.text);
  final String title, text;
}

/// Seluruh angka dan insight laporan, dipisah dari tampilan agar bisa diuji.
class ReportData {
  ReportData({
    required this.business,
    required this.range,
    required this.generatedAt,
    required this.analysis,
    required this.cogs,
    required this.incomeLines,
    required this.expenseLines,
    required this.months,
    required this.debts,
  });
  final String business;
  final DateTimeRange range;
  final DateTime generatedAt;
  final CashflowAnalysis analysis;
  final int cogs; // modal produk terjual
  final List<ReportLine> incomeLines, expenseLines;
  final List<MonthRow> months;
  final DebtSummary debts;

  int get revenue => analysis.inflow;
  int get operatingExpense => analysis.outflow;
  int get totalExpense => operatingExpense + cogs;
  int get profit => revenue - totalExpense;
  double get margin => revenue == 0 ? 0 : profit * 100 / revenue;
  int get tax => (revenue * .005).round();
  int get days => analysis.days;

  List<ReportInsight> get insights => _buildInsights(this);
}

ReportData buildReportData({
  required String business,
  required DateTimeRange range,
  required List<Map<String, dynamic>> income,
  required List<Map<String, dynamic>> expenses,
  required int cogs,
  required List<Map<String, dynamic>> debts,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final a = analyzeCashflow(
      income: income, expenses: expenses, materials: const [], range: range);
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final start = day(range.start), end = day(range.end);
  bool inRange(DateTime d) => !day(d).isBefore(start) && !day(d).isAfter(end);

  final inc = <ReportLine>[], exp = <ReportLine>[];
  for (final e in income) {
    final d = DateTime.tryParse('${e['date']}');
    if (d == null || !inRange(d)) continue;
    inc.add(ReportLine(d, '${e['name']}', '${e['category'] ?? 'Penjualan'}',
        '${e['source'] ?? '-'}', (e['amount'] as num).toInt()));
  }
  for (final e in expenses) {
    final d = DateTime.tryParse('${e['createdAt']}');
    if (d == null || !inRange(d)) continue;
    exp.add(ReportLine(d, '${e['name']}', '${e['category'] ?? 'Lainnya'}',
        '${e['source'] ?? '-'}', (e['amount'] as num).toInt()));
  }
  inc.sort((x, y) => x.date.compareTo(y.date));
  exp.sort((x, y) => x.date.compareTo(y.date));

  final months = <MonthRow>[];
  var cur = DateTime(start.year, start.month);
  while (!cur.isAfter(end)) {
    months.add(MonthRow(cur.year, cur.month));
    cur = DateTime(cur.year, cur.month + 1);
  }
  MonthRow? rowOf(DateTime d) {
    for (final m in months) {
      if (m.year == d.year && m.month == d.month) return m;
    }
    return null;
  }

  for (final l in inc) {
    rowOf(l.date)?.inflow += l.amount;
  }
  for (final l in exp) {
    rowOf(l.date)?.outflow += l.amount;
  }

  return ReportData(
    business: business,
    range: range,
    generatedAt: today,
    analysis: a,
    cogs: cogs,
    incomeLines: inc,
    expenseLines: exp,
    months: months,
    debts: DebtSummary(debts, today),
  );
}

List<ReportInsight> _buildInsights(ReportData r) {
  final a = r.analysis;
  final out = <ReportInsight>[];
  if (r.incomeLines.isEmpty && r.expenseLines.isEmpty) {
    return [
      ReportInsight('Belum ada data',
          'Belum ada transaksi pada periode ini. Catat penjualan dan pengeluaran agar laporan bisa dianalisis.')
    ];
  }

  // 1. Kinerja laba
  final profitWord = r.profit >= 0 ? 'laba' : 'rugi';
  var perf =
      'Usaha mencatat $profitWord bersih ${larasRupiah(r.profit.abs())} dari omzet ${larasRupiah(r.revenue)}';
  if (r.revenue > 0) perf += ' (margin laba ${_pct(r.margin)})';
  perf += '. ';
  if (a.prevInflow > 0) {
    final p = (r.revenue - a.prevInflow) * 100 / a.prevInflow;
    perf +=
        'Omzet ${p >= 0 ? 'naik' : 'turun'} ${p.abs().toStringAsFixed(0)}% dibanding periode sebelumnya yang sama panjang (${larasRupiah(a.prevInflow)}).';
  } else {
    perf += 'Belum ada data periode sebelumnya untuk dibandingkan.';
  }
  out.add(ReportInsight('Kinerja usaha', perf));

  // 2. Pendapatan
  if (a.inByCategory.isNotEmpty) {
    final top =
        a.inByCategory.entries.reduce((x, y) => x.value >= y.value ? x : y);
    final share = r.revenue == 0 ? 0 : top.value * 100 / r.revenue;
    var t =
        'Sumber pendapatan terbesar adalah "${top.key}" (${larasRupiah(top.value)}, ${_pct(share)} dari omzet). ';
    t += share > 60
        ? 'Pendapatan terlalu bertumpu pada satu sumber. Pertimbangkan menambah kanal atau produk lain agar tidak rentan.'
        : 'Sumber pendapatan cukup beragam.';
    out.add(ReportInsight('Sumber pendapatan', t));
  }

  // 3. Bulan terbaik / terlemah
  final active = r.months.where((m) => m.inflow > 0 || m.outflow > 0).toList();
  if (active.length >= 2) {
    final best = active.reduce((x, y) => x.net >= y.net ? x : y);
    final worst = active.reduce((x, y) => x.net <= y.net ? x : y);
    out.add(ReportInsight('Tren bulanan',
        'Bulan terkuat adalah ${best.label} (arus kas bersih ${larasRupiah(best.net)}), terlemah ${worst.label} (${worst.net < 0 ? '-' : ''}${larasRupiah(worst.net.abs())}). Pelajari apa yang berbeda di kedua bulan itu untuk menjaga ritme usaha.'));
  }

  // 4. Struktur biaya
  if (a.outflow > 0) {
    final varShare = a.variable * 100 / a.outflow;
    var t =
        'Biaya variabel ${_pct(varShare)} dan biaya tetap ${_pct(100 - varShare)} dari pengeluaran operasional (${larasRupiah(a.outflow)}). ';
    if (a.bahanBaku > 0) {
      t +=
          'Bahan baku ${_pct(a.bahanBaku * 100 / a.outflow)} dari pengeluaran. ';
    }
    final topExp =
        a.outByCategory.entries.reduce((x, y) => x.value >= y.value ? x : y);
    t +=
        'Pengeluaran terbesar: "${topExp.key}" (${larasRupiah(topExp.value)}).';
    out.add(ReportInsight('Struktur biaya', t));
  }
  if (a.prevOutflow > 0 && a.outflow > a.prevOutflow * 1.2) {
    out.add(ReportInsight('Biaya meningkat',
        'Pengeluaran operasional naik ${((a.outflow - a.prevOutflow) * 100 / a.prevOutflow).toStringAsFixed(0)}% dibanding periode sebelumnya. Telusuri kategori yang naik paling tajam.'));
  }

  // 5. Titik impas
  final bep = computeBep(a);
  if (bep.feasible && bep.fixedMonthly > 0) {
    out.add(ReportInsight('Titik impas',
        'Perkiraan omzet impas ${larasRupiah(bep.bep)} per bulan; omzet bulananmu sekitar ${larasRupiah(bep.revenueMonthly)}. ${bep.revenueMonthly >= bep.bep ? 'Batas aman ${_pct(bep.safetyMargin * 100)}: omzet boleh turun sebesar itu sebelum rugi.' : 'Omzet masih di bawah titik impas, usaha berisiko rugi.'}'));
  } else if (!bep.feasible) {
    out.add(ReportInsight('Titik impas',
        'Biaya variabel sudah menyamai atau melebihi omzet, sehingga usaha tidak bisa impas berapa pun penjualannya. Periksa harga jual dan harga bahan.'));
  }

  // 6. Arus kas
  final proj = (a.avgNetPerDay * 30).round();
  out.add(ReportInsight('Arus kas',
      'Uang masuk ${larasRupiah(a.inflow)}, uang keluar ${larasRupiah(a.outflow)}, arus kas bersih ${a.net < 0 ? '-' : ''}${larasRupiah(a.net.abs())}. Jika pola ini berlanjut, kas bertambah sekitar ${proj < 0 ? 'minus ' : ''}${larasRupiah(proj.abs())} dalam 30 hari ke depan.'));

  // 7. Piutang dan utang
  final d = r.debts;
  if (d.piutang > 0 || d.utang > 0) {
    var t =
        'Piutang belum diterima ${larasRupiah(d.piutang)}, utang belum dibayar ${larasRupiah(d.utang)} (posisi bersih ${d.net < 0 ? '-' : ''}${larasRupiah(d.net.abs())}). ';
    if (d.piutangLate > 0) {
      t +=
          '${larasRupiah(d.piutangLate)} piutang sudah lewat jatuh tempo: segera tagih. ';
    }
    if (d.utangLate > 0) {
      t +=
          '${larasRupiah(d.utangLate)} utang terlambat dibayar: jaga hubungan baik dengan supplier.';
    }
    out.add(ReportInsight('Utang dan piutang', t));
  }

  // 8. Rekomendasi
  final recs = <String>[];
  if (r.margin < 20 && r.revenue > 0) {
    recs.add(
        'Naikkan margin: cek harga bahan di Supplier atau naikkan harga jual hingga margin minimal 20-30%.');
  }
  if (a.net < 0) {
    recs.add(
        'Tahan pengeluaran yang belum mendesak dan percepat penagihan piutang.');
  }
  if (d.piutangLate > 0)
    recs.add('Tagih piutang yang terlambat lewat WhatsApp hari ini.');
  if (a.bahanBaku > 0 && a.outflow > 0 && a.bahanBaku / a.outflow > .5) {
    recs.add('Bandingkan harga antar supplier untuk menekan biaya bahan baku.');
  }
  if (a.inByCategory.length <= 1) {
    recs.add(
        'Tambah kanal penjualan (marketplace atau media sosial) agar omzet tidak bertumpu pada satu sumber.');
  }
  if (r.profit > 0) {
    recs.add(
        'Sisihkan sebagian laba sebagai dana cadangan dan lunasi utang sebelum jatuh tempo.');
  }
  recs.add(
      'Catat transaksi di hari yang sama agar laporan berikutnya lebih akurat.');
  out.add(ReportInsight('Rekomendasi tindakan',
      recs.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')));
  return out;
}

// ---------------------------------------------------------------- PDF ----

const _black = PdfColors.black;
const _grey1 = PdfColor.fromInt(0xFFF2F2F2);
const _grey2 = PdfColor.fromInt(0xFFD9D9D9);
const _grey3 = PdfColor.fromInt(0xFF595959);

pw.Document buildFinanceReportPdf(ReportData r) {
  final doc =
      pw.Document(title: 'Laporan Keuangan ${r.business}', author: 'LARAS');
  final a = r.analysis;

  pw.Widget heading(String n, String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$n. ${t.toUpperCase()}',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Container(height: 1.2, color: _black),
            ]),
      );

  bool isStrong(List<String> row) {
    for (final c in row.take(2)) {
      if (c.startsWith(' ') || c.isEmpty) continue;
      return RegExp(r'^(PENDAPATAN|BEBAN USAHA|LABA|RUGI|Total|Posisi bersih)')
          .hasMatch(c);
    }
    return false;
  }

  pw.Widget table(List<String> headers, List<List<String>> rows,
      {Set<int> right = const {}, List<double>? widths}) {
    pw.Widget cell(String t, int col,
            {bool head = false, bool strong = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: pw.Text(t,
              textAlign:
                  right.contains(col) ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: head || strong
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: head ? PdfColors.white : _black)),
        );
    return pw.Table(
      columnWidths: widths == null
          ? null
          : {
              for (var i = 0; i < widths.length; i++)
                i: pw.FlexColumnWidth(widths[i])
            },
      border: const pw.TableBorder(
          bottom: pw.BorderSide(color: _black, width: .8),
          horizontalInside: pw.BorderSide(color: _grey2, width: .4)),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _black),
          children: [
            for (var i = 0; i < headers.length; i++)
              cell(headers[i], i, head: true)
          ],
        ),
        for (final (i, row) in rows.indexed)
          pw.TableRow(
            decoration: pw.BoxDecoration(
                color: isStrong(row) ? _grey2 : (i.isOdd ? _grey1 : null)),
            children: [
              for (var c = 0; c < row.length; c++)
                cell(row[c], c, strong: isStrong(row))
            ],
          ),
      ],
    );
  }

  pw.Widget kpi(String label, String value, String note) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration:
              pw.BoxDecoration(border: pw.Border.all(color: _black, width: .8)),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _grey3)),
                pw.SizedBox(height: 4),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(note,
                    style: const pw.TextStyle(fontSize: 7, color: _grey3)),
              ]),
        ),
      );

  pw.Widget bar(double f, {bool dark = true}) => pw.Container(
        height: 7,
        width: 150,
        color: _grey1,
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
            width: 150 * f.clamp(0, 1).toDouble(),
            color: dark ? _black : PdfColors.grey500),
      );

  pw.Widget shareRows(Map<String, int> data, int total) {
    final rows = data.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    return pw.Column(children: [
      for (final e in rows)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 110,
                child:
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 8.5))),
            bar(total == 0 ? 0 : e.value / total),
            pw.SizedBox(width: 8),
            pw.SizedBox(
                width: 80,
                child: pw.Text(larasRupiah(e.value),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 8.5))),
            pw.SizedBox(
                width: 36,
                child: pw.Text(_pct(total == 0 ? 0 : e.value * 100 / total),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 8.5, color: _grey3))),
          ]),
        ),
    ]);
  }

  final multiMonth = r.months.length > 1;
  final maxMonth = r.months.fold<int>(
      1, (m, e) => [m, e.inflow, e.outflow].reduce((x, y) => x > y ? x : y));

  doc.addPage(pw.MultiPage(
    pageTheme: const pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(40, 40, 40, 44)),
    footer: (c) => pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _grey2, width: .5))),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LARAS - ${r.business}',
                style: const pw.TextStyle(fontSize: 7.5, color: _grey3)),
            pw.Text('Halaman ${c.pageNumber} dari ${c.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _grey3)),
          ]),
    ),
    build: (c) => [
      // --- Kop ---
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Text('LAPORAN KEUANGAN USAHA',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(r.business, style: const pw.TextStyle(fontSize: 11)),
            ])),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Periode',
              style: const pw.TextStyle(fontSize: 7.5, color: _grey3)),
          pw.Text('${_d(r.range.start)} - ${_d(r.range.end)}',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('${r.days} hari',
              style: const pw.TextStyle(fontSize: 8, color: _grey3)),
        ]),
      ]),
      pw.SizedBox(height: 6),
      pw.Container(height: 2.5, color: _black),
      pw.SizedBox(height: 10),

      // --- 1. Ringkasan ---
      pw.Text('Dibuat ${_d(r.generatedAt)} oleh LARAS',
          style: const pw.TextStyle(fontSize: 7.5, color: _grey3)),
      heading('1', 'Ringkasan eksekutif'),
      pw.Row(children: [
        kpi('TOTAL PENDAPATAN', larasRupiah(r.revenue),
            _delta(r.revenue, a.prevInflow)),
        kpi('TOTAL BEBAN', larasRupiah(r.totalExpense),
            'operasional + modal produk'),
        kpi(
            '${r.profit >= 0 ? 'LABA' : 'RUGI'} BERSIH',
            '${r.profit < 0 ? '-' : ''}${larasRupiah(r.profit.abs())}',
            'margin ${_pct(r.margin)}'),
        kpi('EST. PPh FINAL 0,5%', larasRupiah(r.tax), 'dari omzet'),
      ]),

      // --- 2. Laba rugi ---
      heading('2', 'Laporan laba rugi'),
      table(
        ['Keterangan', 'Nominal'],
        [
          ['PENDAPATAN', ''],
          for (final e
              in (a.inByCategory.entries.toList()
                ..sort((x, y) => y.value.compareTo(x.value))))
            ['   ${e.key}', larasRupiah(e.value)],
          ['Total pendapatan', larasRupiah(r.revenue)],
          ['BEBAN USAHA', ''],
          for (final e
              in (a.outByCategory.entries.toList()
                ..sort((x, y) => y.value.compareTo(x.value))))
            ['   ${e.key}', '(${larasRupiah(e.value)})'],
          if (r.cogs > 0)
            ['   Modal produk terjual', '(${larasRupiah(r.cogs)})'],
          ['Total beban', '(${larasRupiah(r.totalExpense)})'],
          [
            '${r.profit >= 0 ? 'LABA' : 'RUGI'} BERSIH',
            '${r.profit < 0 ? '-' : ''}${larasRupiah(r.profit.abs())}'
          ],
        ],
        right: {1},
        widths: [3, 1.4],
      ),

      // --- 3. Arus kas ---
      heading('3', 'Arus kas'),
      pw.Row(children: [
        kpi('UANG MASUK', larasRupiah(a.inflow),
            _delta(a.inflow, a.prevInflow)),
        kpi('UANG KELUAR', larasRupiah(a.outflow),
            _delta(a.outflow, a.prevOutflow)),
        kpi(
            'ARUS KAS BERSIH',
            '${a.net < 0 ? '-' : ''}${larasRupiah(a.net.abs())}',
            'masuk dikurangi keluar'),
        kpi(
            'RASIO KELUAR/MASUK',
            a.inflow == 0 ? '-' : _pct(a.outflow * 100 / a.inflow),
            'di bawah 100% = sehat'),
      ]),
      if (multiMonth) ...[
        pw.SizedBox(height: 10),
        table(
          ['Bulan', 'Uang masuk', 'Uang keluar', 'Arus kas bersih'],
          [
            for (final m in r.months)
              [
                m.label,
                larasRupiah(m.inflow),
                larasRupiah(m.outflow),
                '${m.net < 0 ? '-' : ''}${larasRupiah(m.net.abs())}'
              ],
            [
              'Total',
              larasRupiah(r.months.fold(0, (s, m) => s + m.inflow)),
              larasRupiah(r.months.fold(0, (s, m) => s + m.outflow)),
              '${a.net < 0 ? '-' : ''}${larasRupiah(a.net.abs())}'
            ],
          ],
          right: {1, 2, 3},
          widths: [2, 2, 2, 2],
        ),
        pw.SizedBox(height: 8),
        pw.Text('Grafik bulanan (hitam: masuk, abu: keluar)',
            style: const pw.TextStyle(fontSize: 7.5, color: _grey3)),
        pw.SizedBox(height: 4),
        for (final m in r.months)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(children: [
              pw.SizedBox(
                  width: 80,
                  child:
                      pw.Text(m.label, style: const pw.TextStyle(fontSize: 8))),
              pw.Column(children: [
                bar(m.inflow / maxMonth),
                pw.SizedBox(height: 1.5),
                bar(m.outflow / maxMonth, dark: false),
              ]),
            ]),
          ),
      ],

      // --- 4. Kategori ---
      heading('4', 'Analisis kategori'),
      pw.Text('Uang masuk per kategori',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      if (a.inByCategory.isEmpty)
        pw.Text('Belum ada data.', style: const pw.TextStyle(fontSize: 8.5))
      else
        shareRows(a.inByCategory, a.inflow),
      pw.SizedBox(height: 10),
      pw.Text('Uang keluar per kategori',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      if (a.outByCategory.isEmpty)
        pw.Text('Belum ada data.', style: const pw.TextStyle(fontSize: 8.5))
      else
        shareRows(a.outByCategory, a.outflow),
      pw.SizedBox(height: 10),
      table(
        ['Tipe arus kas', 'Selisih masuk - keluar'],
        [
          for (final e in a.byType.entries)
            [e.key, '${e.value < 0 ? '-' : ''}${larasRupiah(e.value.abs())}']
        ],
        right: {1},
        widths: [3, 2],
      ),

      // --- 5. Insight ---
      heading('5', 'Insight dan rekomendasi'),
      for (final i in r.insights)
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 7),
          padding: const pw.EdgeInsets.fromLTRB(9, 6, 9, 7),
          decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: _black, width: 2.5)),
              color: _grey1),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(i.title,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(i.text,
                    style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 2)),
              ]),
        ),

      // --- 6. Rincian transaksi ---
      heading('6', 'Rincian pendapatan'),
      if (r.incomeLines.isEmpty)
        pw.Text('Belum ada pendapatan tercatat pada periode ini.',
            style: const pw.TextStyle(fontSize: 8.5))
      else
        table(
          ['Tanggal', 'Keterangan', 'Kategori', 'Nominal'],
          [
            for (final l in r.incomeLines)
              [_d(l.date), l.name, l.category, larasRupiah(l.amount)],
            ['', 'Total pendapatan', '', larasRupiah(r.revenue)],
          ],
          right: {3},
          widths: [1.2, 3.4, 1.8, 1.8],
        ),
      heading('7', 'Rincian beban'),
      if (r.expenseLines.isEmpty)
        pw.Text('Belum ada pengeluaran tercatat pada periode ini.',
            style: const pw.TextStyle(fontSize: 8.5))
      else
        table(
          ['Tanggal', 'Keterangan', 'Kategori', 'Nominal'],
          [
            for (final l in r.expenseLines)
              [_d(l.date), l.name, l.category, larasRupiah(l.amount)],
            [
              '',
              'Total beban operasional',
              '',
              larasRupiah(r.operatingExpense)
            ],
          ],
          right: {3},
          widths: [1.2, 3.4, 1.8, 1.8],
        ),

      // --- 8. Utang piutang ---
      if (r.debts.piutang > 0 || r.debts.utang > 0) ...[
        heading('8', 'Posisi utang dan piutang'),
        table(
          ['Keterangan', 'Total', 'Terlambat'],
          [
            [
              'Piutang (akan masuk)',
              larasRupiah(r.debts.piutang),
              larasRupiah(r.debts.piutangLate)
            ],
            [
              'Utang (harus dibayar)',
              larasRupiah(r.debts.utang),
              larasRupiah(r.debts.utangLate)
            ],
            [
              'Posisi bersih',
              '${r.debts.net < 0 ? '-' : ''}${larasRupiah(r.debts.net.abs())}',
              ''
            ],
          ],
          right: {1, 2},
          widths: [3, 2, 2],
        ),
      ],

      // --- Catatan ---
      pw.SizedBox(height: 16),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration:
            pw.BoxDecoration(border: pw.Border.all(color: _grey2, width: .6)),
        child: pw.Text(
            'Catatan: Laporan ini adalah rangkuman internal dari catatan yang dimasukkan di LARAS dan bukan laporan yang diaudit. Laba dihitung dari pendapatan dikurangi beban operasional dan modal produk terjual; modal untuk transaksi manual yang tidak menyimpan harga modal belum dihitung. Arus kas berbasis uang yang benar-benar masuk dan keluar. Estimasi PPh final 0,5% hanya perkiraan dan bukan pengganti perhitungan atau pelaporan pajak resmi. Insight dibuat otomatis dari data dan bukan nasihat keuangan.',
            style: const pw.TextStyle(
                fontSize: 7.5, color: _grey3, lineSpacing: 2)),
      ),
    ],
  ));
  return doc;
}
