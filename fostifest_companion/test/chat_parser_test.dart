import 'package:fostifest_companion/chat_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 14);
  final products = [
    {'name': 'Batik Cap Kawung 2m', 'price': 275000},
    {'name': 'Kemeja Batik Pria', 'price': 245000},
  ];

  test('pesanan katalog dengan DP, nama, dan tanggal', () {
    final o = parseChatOrder(
        'Kak, mau pesan 2 batik cap kawung sama 1 kemeja batik pria ya. Atas nama Bu Ani. DP 200rb dulu, sisanya nanti pas ambil tgl 20 nov',
        products: products,
        now: now);
    expect(o.customer, 'Bu Ani');
    expect(o.items.length, 2);
    expect(o.items[0].name, 'Batik Cap Kawung 2m');
    expect(o.items[0].qty, 2);
    expect(o.items[0].unitPrice, 275000);
    expect(o.items[1].qty, 1);
    expect(o.total, 795000);
    expect(o.pay, PayStatus.sebagian);
    expect(o.paid, 200000);
    expect(o.due, DateTime(2026, 11, 20));
  });

  test('pesanan bebas dengan harga satuan, total, dan lunas', () {
    final o = parseChatOrder(
        'Halo, pesan seragam batik 30 pcs @ 120.000, total 3.600.000, transfer sudah ya atas nama Pak Budi',
        now: now);
    expect(o.customer, 'Pak Budi');
    expect(o.items.length, 1);
    expect(o.items.first.name, 'Seragam Batik');
    expect(o.items.first.qty, 30);
    expect(o.items.first.unitPrice, 120000);
    expect(o.statedTotal, 3600000);
    expect(o.totalMismatch, isFalse);
    expect(o.pay, PayStatus.lunas);
  });

  test('belum bayar dengan jatuh tempo', () {
    final o = parseChatOrder(
        'pesan batik tulis parang 1 potong harga 850rb, belum bayar, jatuh tempo 5 des',
        now: now);
    expect(o.items.single.qty, 1);
    expect(o.items.single.unitPrice, 850000);
    expect(o.pay, PayStatus.belum);
    expect(o.due, DateTime(2026, 12, 5));
  });

  test('format ekspor WhatsApp dan angka jutaan', () {
    final o = parseChatOrder(
        '[12/11/25 10.23] Ani: pesan 2 tas tote 95rb\n[12/11/25 10.24] Ani: total 1,5jt',
        now: now);
    expect(o.items.single.name, 'Tas Tote');
    expect(o.items.single.qty, 2);
    expect(o.statedTotal, 1500000);
    expect(o.totalMismatch, isTrue); // 2 x 95rb = 190rb, beda dengan 1,5jt
  });

  test('teks tanpa pesanan menghasilkan daftar kosong, bukan error', () {
    final o = parseChatOrder('halo kak, apa kabar?', now: now);
    expect(o.items, isEmpty);
    expect(o.customer, isNull);
    expect(o.pay, PayStatus.tidakJelas);
  });
}
