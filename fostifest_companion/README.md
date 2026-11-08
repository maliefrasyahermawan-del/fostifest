# FOSTIFEST Finance

Aplikasi keuangan Flutter untuk UMKM yang diadaptasi dari Logicodix/BUMIRA dan direbranding dengan identitas hijau-putih FOSTIFEST. Aplikasi ini merupakan produk lomba, bukan aplikasi pengelolaan proses perlombaan.

## Fitur MVP

- Dashboard omzet, estimasi laba, tren, dan produk terlaris.
- Pembukuan transaksi melalui input manual, chat, atau OCR foto catatan.
- Pelanggan, produk, stok minimum, kategori, dan laporan laba-rugi.
- Tidak memproses pembayaran digital, QRIS, atau payment gateway.
- Kalender transaksi dan laporan laba-rugi yang dapat dibagikan sebagai PDF.
- Daftar legalitas UMKM untuk mencatat status dokumen usaha.
- Profil usaha lokal serta asisten keuangan Fosti.
- **Manage Cerdas**: layar ikon fitur manajemen usaha (Keuangan, Pelanggan, Produk & Stok, Supplier, Harga & Margin, Laporan, Catat Transaksi, Legalitas, Asisten Laras).
- **Harga & Margin**: margin tiap produk, penjelasan penyebab margin, dan pengaturan harga jual dengan target margin.
- **Supplier**: daftar pemasok bahan baku, kontak, harga bahan, riwayat harga, penanda harga termurah, dan pencatatan pembelian bahan ke Keuangan.
- **Resep & modal otomatis**: modal produk dihitung dari harga bahan supplier, upah, dan overhead. Kenaikan harga bahan memperbarui modal produk dan menampilkan dampaknya ke margin.
- Sidebar fitur dan data demo usaha batik (Batik Sekar) yang terisi saat masuk dengan akun demo atau tamu.

## Menjalankan aplikasi

```powershell
flutter pub get
flutter run
```

## Build APK Android

```powershell
flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols/arm64
```

APK ARM64 teroptimasi juga tersedia sebagai `FOSTIFEST-2026-arm64-release.apk`.

## Preview web lokal

Klik `Buka Preview LARAS.cmd` di folder induk (lihat `CARA PREVIEW LARAS.md`). Preview tersedia di `http://127.0.0.1:43827/`.

## Dokumentasi

- `KONTEKS-LARAS.md`: konteks produk dan teknis lengkap.
- `LARAS_IMPLEMENTATION_REPORT.md`: laporan implementasi.
