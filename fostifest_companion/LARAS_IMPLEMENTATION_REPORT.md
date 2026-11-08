# LARAS UMKM — Implementation Report

> **Catatan:** dokumen ini mencatat implementasi pada tahap awal. Sebagian fitur, terutama Legalitas dan desain antarmuka, sudah diperbarui. Lihat [README utama](../README.md) dan [CHANGELOG.md](../CHANGELOG.md) untuk kondisi terkini.

## Ringkasan

LARAS adalah aplikasi manajemen keuangan UMKM berbasis Flutter dengan data lokal. Refactor ini menghapus total Kasir/POS, piutang, QRIS, payment link, rekening bank, gateway pembayaran, dan fitur pembayaran digital. Aplikasi tidak menerima, memproses, atau memverifikasi pembayaran otomatis.

## Struktur final

1. Beranda: kas bersih, pemasukan, pengeluaran, stok menipis, aksi cepat, dan insight.
2. Keuangan: pemasukan, pengeluaran, kategori kas, dan riwayat transaksi.
3. Pelanggan: kontak serta catatan pelanggan tanpa tagihan atau piutang.
4. Produk & Stok: katalog, SKU, kategori, stok minimum, dan penyesuaian stok manual.
5. Laporan: omzet, laba-rugi dari catatan, nilai persediaan, dan evaluasi margin.
6. Legalitas: catatan NIB, merek/P-IRT, serta halal.
7. Pengaturan: status penyimpanan lokal, bantuan, privasi, dan profil usaha.

## Fitur selesai

- Pencatatan pemasukan dan pengeluaran dengan validasi nominal positif.
- Kategori kas dan kategori produk lokal.
- CRUD pelanggan serta katalog produk lokal.
- Indikator stok minimum dan nilai persediaan.
- Dashboard dan laporan yang menghitung data dari transaksi serta produk tersimpan.
- Search, login, register, hero berilustrasi, catat cerdas, OCR foto catatan, legalitas, profil, dan preview web tetap tersedia.
- Metode pembayaran hanya tercatat secara manual pada transaksi; tidak ada checkout, link, QRIS, maupun verifikasi pembayaran.

## Data lokal

`BusinessProfile`, account, `Customer`, `Product`, `ProductCategory`, `StockMovement`, `CashCategory`, pemasukan/pengeluaran, metadata pembaruan lokal, dan status legalitas disimpan sebagai JSON melalui `SharedPreferences`.

## Aturan bisnis

- Nominal transaksi wajib lebih besar dari nol.
- Pencatatan pemasukan dan pengeluaran langsung memperbarui dashboard serta laporan.
- Stok minimum ditampilkan sebagai peringatan.
- Data keuangan disimpan di perangkat; tidak ada sinkronisasi server atau pemrosesan pembayaran.

## Halaman dipertahankan

Login, register, hero/search beranda, keuangan, pelanggan, produk/stok, laporan, legalitas, profil, asisten LARAS, serta preview web lokal.

## File utama yang diubah

- `lib/laras_operations_page.dart`
- `lib/main.dart`
- `lib/inventory_page.dart`
- `lib/mock_data.dart`

## Batasan jujur

Belum ada backend, sinkronisasi lintas perangkat, notifikasi push, lampiran transaksi cloud, atau integrasi bank/gateway. Data hanya tersimpan secara lokal pada perangkat/browser.
