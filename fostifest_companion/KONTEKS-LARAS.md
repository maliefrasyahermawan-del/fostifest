# KONTEKS APLIKASI LARAS UMKM

Dokumen ini adalah konteks teknis dan produk lengkap untuk aplikasi **LARAS UMKM**
(karya **FOSTIFEST 2026 — Software Development Competition**). Tujuannya agar siapa pun
(developer, juri, atau AI coding assistant) bisa memahami tujuan, fitur, arsitektur, alur
data, dan konfigurasi aplikasi tanpa harus membaca seluruh source code lebih dulu.

- Nama aplikasi: **LARAS UMKM** (nama paket/repo: `fostifest_companion`, dulu "FOSTIFEST Finance")
- Jenis: aplikasi mobile keuangan/pembukuan UMKM berbasis **Flutter**
- Versi `pubspec.yaml`: `1.0.0+1` (catatan: halaman Tentang masih menulis "Versi 1.5.0")
- Basis: hasil rebranding dari aplikasi referensi Logicodix/BUMIRA
- Platform utama: **Android** (APK ARM64), dengan **web preview** untuk demo di laptop
- Data: 100% lokal per perangkat, **tanpa backend/API**, memakai `SharedPreferences`

---

## 1. Tujuan Produk

### 1.1 Masalah
UMKM kecil (pedagang batik, fashion, kuliner rumahan) sering mencatat penjualan dan biaya
secara terpisah (buku tulis, chat WhatsApp, ingatan). Akibatnya:
- Tidak tahu omzet, laba, dan produk terlaris secara cepat.
- Sulit memisahkan uang usaha dan uang pribadi.
- Tidak siap menghitung estimasi pajak UMKM (PPh final 0,5%).
- Status legalitas usaha (NIB, P-IRT/merek, halal) tidak terdokumentasi.

### 1.2 Solusi
Satu aplikasi ringan yang menggabungkan:
- Pencatatan transaksi (manual, tempel chat, OCR foto struk).
- Kasir/POS sederhana (keranjang, barcode, diskon, poin, kasbon, QRIS).
- Produk & stok.
- Laporan laba-rugi + estimasi PPh final + ekspor PDF.
- Kalender transaksi.
- Checklist legalitas.
- Profil usaha dan asisten chat "Laras".

### 1.2.1 Definisi MVP
MVP LARAS UMKM difokuskan pada empat pilar nilai:

1. **Manajemen keuangan** — pembukuan pemasukan, pengeluaran, modal, dan kasir
   yang rapi dalam satu tempat.
2. **Analisa & monitoring performa** — memantau **omzet**, **margin/laba**,
   tren penjualan, produk terlaris, dan stok menipis sebagai dasar keputusan.
3. **Pertumbuhan usaha (upscale) & marketing** — memberi arahan langkah
   pengembangan usaha dan promosi berdasarkan data yang tercatat.
4. **Administrasi & legalitas** — menyiapkan catatan administrasi dan status
   dokumen legalitas usaha (NIB, P-IRT/merek, halal) agar usaha tertata.

> Status implementasi jujur: pilar 1 dan 2 sudah berjalan penuh; pilar 4 sudah
> berbentuk checklist status dokumen; pilar 3 saat ini masih terbatas pada
> insight di Beranda dan asisten "Laras", dan menjadi fokus roadmap.

| Pilar MVP | Tujuan | Fitur pendukung saat ini | Status |
|---|---|---|---|
| Manajemen keuangan | Catat semua uang masuk/keluar & modal | Catat transaksi, kasir, pengeluaran, produk/stok, kalender | Berjalan |
| Analisa & monitoring | Pantau omzet, laba, margin, tren, produk terlaris | Metrik Beranda, tren omzet, produk terlaris, laporan laba-rugi, estimasi PPh | Berjalan |
| Upscale & marketing | Tumbuhkan penjualan & arah promosi | Asisten Laras (ringkasan & saran), pencarian fitur, insight omzet | Sebagian / roadmap |
| Administrasi & legalitas | Siapkan administrasi dan legalitas usaha | Checklist NIB/P-IRT/Halal, profil usaha, laporan PDF | Berjalan (dasar) |

**Margin keuntungan** dihitung dari `omzet - beban operasional - modal produk
terjual`; modal diambil dari harga modal produk yang tersimpan pada penjualan
kasir. Perhitungan ini adalah estimasi, bukan laporan yang diaudit.

### 1.3 Target pengguna
Pelaku UMKM perorangan/rumah tangga di Indonesia, terutama yang menjalankan usaha
dengan ponsel Android dan belum memakai software pembukuan.

### 1.4 Keterkaitan SDG / subtema
Subtema **"Ekonomi Inklusif, UMKM dan Pengentasan Kemiskinan"** —
SDG 1 (No Poverty) dan SDG 8 (Decent Work and Economic Growth).
Alur kompetisi: **Problem → Solution → Build → Validate → Impact**.

### 1.5 Dampak yang diharapkan
- Pembukuan rapi dalam < 1 menit per transaksi.
- Keputusan usaha berbasis data (omzet, laba, margin, produk terlaris, stok menipis).
- Arah pertumbuhan yang jelas: langkah upscale dan prioritas marketing.
- Kesiapan administrasi pajak dan legalitas usaha.
- Mendorong inklusi digital UMKM tanpa biaya langganan/cloud.

### 1.6 Deliverables Produk (Target & Status)

Deliverables adalah hasil yang dijanjikan aplikasi kepada UMKM. Status memakai
label **Sudah**, **Sebagian** (sudah ada dasar, belum penuh), dan **Rencana**
(belum ada di kode, masuk roadmap).

| # | Deliverable | Wujud di produk | Status |
|---|---|---|---|
| D1 | **Kelola penjualan semaksimal mungkin walau pengetahuan minim** | Alur berlapis: input manual, tempel chat, OCR struk; kasir dengan keranjang, barcode, diskon, poin; form berpanduan, satuan preset, pencarian fitur, akun demo | Sudah |
| D2 | **UMKM tahu "jual segini untung atau rugi"**, cara set harga, tahu margin, estimasi & potongan pajak | Harga jual + harga modal per produk, estimasi laba/margin, laporan laba-rugi, estimasi PPh final 0,5% | Sebagian (rekomendasi harga & break-even: rencana) |
| D3 | **Laporan keuangan lengkap, beberapa versi sesuai keinginan UMKM** | Laporan Pengeluaran dan Laba Rugi per bulan, ekspor/bagikan PDF | Sebagian (template/kustom laporan: rencana) |
| D4 | **Keuangan tracker per hari, 3 hari, 7 hari, 1 bulan; paham arus kas (cashflow) masuk & keluar** | Kalender harian; tren omzet periode 7/21/30/90 hari; rekap omzet & beban bulanan | Sebagian (rentang 3 hari eksplisit & tampilan cashflow: rencana) |
| D5 | **Budgeting method untuk vendor dan supplier** | Belum ada modul anggaran vendor; pengeluaran bisa dicatat per kategori | Rencana |
| D6 | **Kalkulasi kenaikan harga bahan baku/supply** + rekomendasi naikkan harga atau efisiensi + tracking kenaikan | Harga modal produk tercatat, tetapi belum ada histori harga bahan baku maupun analisis kenaikan | Rencana |
| D7 | **Catat vendor/supplier bahan baku & daftar mereka, label sebagai cost** | Bisa diakali lewat Pengeluaran (nama vendor + detail kategori); modul vendor + label cost khusus belum ada | Sebagian (manual) / Rencana (modul) |
| D8 | **Listing biaya advertisement/iklan** (spanduk, cetak gambar, menu, dll) **dan biaya produksi** | Tercatat lewat menu Pengeluaran dengan detail kategori (mis. Marketing/Produksi); kategori terstruktur & laporan per kategori belum ada | Sebagian (dasar) |

**Catatan kesenjangan implementasi (jujur):**
- D1–D4 sudah punya fondasi kuat di kode saat ini.
- D5, D6, dan modul vendor pada D7 adalah fitur baru yang perlu dibangun
  (model data, UI, dan analitik), bukan sekadar penamaan ulang.
- D8 saat ini hanya bisa dicatat sebagai pengeluaran biasa; kategori
  marketing/produksi masih berupa teks, belum taksonomi terstruktur.
- Rekomendasi kenaikan harga (D6) idealnya memakai data: harga modal historis
  per bahan baku, kontribusi biaya per produk, dan ambang margin minimum.
  Ini membutuhkan skema penyimpanan baru (mis. `laras_suppliers_v1`,
  `laras_material_prices_v1`, `laras_budgets_v1`, `laras_expense_categories_v1`).

---

## 2. Fitur Lengkap

### 2.1 Autentikasi & onboarding (lokal)
- **Splash screen** 1,4 detik dengan branding LARAS UMKM.
- **Login** memakai email/nomor WhatsApp + kata sandi.
- **Registrasi** (nama lengkap, identifier, kata sandi min. 6 karakter, konfirmasi).
- **Masuk sebagai tamu** dan **Masuk ke akun demo** (bypass, tanpa validasi akun).
- Akun disimpan lokal; login hanya mencocokkan data yang tersimpan di perangkat.
- Logout mengembalikan ke layar login.
- Foto profil usaha, mode gelap, dan data akun dipersist di `SharedPreferences`.

### 2.2 Beranda (Home)
- Header dengan avatar/foto usaha dan brand.
- **Pencarian fitur** pintar berbasis kata kunci (judul, subtitle, sinonim) yang
  langsung membuka fitur terkait.
- Kartu hero ringkasan + tombol catat transaksi.
- **Metrik**: omzet bulan ini, estimasi laba, jumlah transaksi.
- **Tren omzet**: filter periode 1 minggu / 3 minggu / 1 bulan / 3 bulan,
  grafik 4 bucket.
- **Produk terlaris**: 5 teratas berdasarkan nominal transaksi pada periode.
- Shortcut legalitas usaha.

### 2.3 Catat transaksi (Catat Cerdas)
Tiga mode input:
1. **Manual** — tanggal, nama produk, jumlah, satuan (pcs/set/meter/kg), nominal,
   nama pelanggan, status pembayaran.
2. **Chat** — menempel teks chat penjualan (konfirmasi manual nama & nominal).
3. **Struk** — pilih foto kamera/galeri, lalu **OCR** (ML Kit, Android saja).
   OCR mengisi nama produk (baris pertama) dan nominal terbesar yang terdeteksi,
   serta menyediakan dialog teks mentah.
- Sumber transaksi disimpan sebagai label: `Manual`, `Tempel chat`, `Scan struk`.
- Validasi: nama wajib, nominal > 0.
- Setelah simpan, transaksi masuk ke pembukuan dan berpindah ke tab Catatan.

### 2.4 Catatan keuangan (Ledger)
Tiga sub-tab:
- **Transaksi** — daftar transaksi per bulan, pemilih bulan, tombol tambah.
- **Kalender** — grid bulanan, tanggal bertransaksi diberi titik, ringkasan
  pemasukan/pengeluaran/saldo per tanggal terpilih.
- **Laporan** — dua mode:
  - **Pengeluaran** (rincian beban + total).
  - **Laba Rugi** (pendapatan, beban operasional, modal produk terjual,
    laba bersih, **estimasi PPh final 0,5%** dari omzet).
- **Ekspor PDF** laporan laba-rugi (paket `pdf` + `printing`) berisi rincian
  transaksi, ringkasan, dan estimasi pajak.

### 2.5 Kasir / POS & Piutang (`cashier_page.dart`)
- Katalog produk dengan pencarian (nama, SKU, kategori).
- **Scan barcode** (`mobile_scanner`) + fallback input manual.
- Keranjang dengan tambah/kurang, validasi stok.
- **Diskon**: nominal manual + diskon tersimpan (nominal atau persen).
- **Pajak** manual (persen).
- **Poin pelanggan**: tukar poin (100 rupiah/poin) dan perolehan poin.
- **Metode bayar**: Tunai, QRIS, Transfer, Kasbon.
  - Tunai: hitung kembalian dan validasi uang diterima.
  - QRIS: menampilkan gambar QRIS toko bila tersedia.
  - Kasbon: wajib nama pelanggan, bisa dilunasi dari tab riwayat.
- **Tahan / buka keranjang** (held carts) untuk transaksi tertunda.
- **Riwayat penjualan** + buka **struk PDF** (bagikan/cetak).
- **Recovery checkout atomik**: seluruh transaksi disimpan sebagai backup
  `laras_checkout_pending` sebelum ditulis, agar tidak ada data hilang jika
  proses terputus. Halaman lain memblokir input selama recovery belum selesai.

### 2.6 Produk & stok (`inventory_page.dart`)
- CRUD produk: nama, barcode/SKU (opsional, unik), kategori, harga jual,
  harga modal, stok, batas stok menipis.
- Scan barcode saat mengisi SKU.
- Indikator "Stok menipis" bila `stock <= min`.
- Validasi nilai angka >= 0 dan SKU tidak duplikat.

### 2.7 Pelanggan, pengeluaran, diskon (`business_tools_page.dart`)
- **Pelanggan**: nama, nomor telepon, poin loyalitas.
- **Pengeluaran**: nama, kategori/catatan, jumlah, tanggal; total pengeluaran.
- **Diskon**: nama, jenis Nominal/Persen, nilai (persen <= 100).
- Semua data dipakai modul kasir dan laporan.

### 2.8 Legalitas usaha
- Checklist status dokumen: **NIB**, **P-IRT / Merek**, **Sertifikasi Halal**.
- Status disimpan lokal; ditandai jelas sebagai catatan pribadi, bukan verifikasi resmi.

### 2.9 Profil usaha
- Lihat/edit identitas: nama, deskripsi, lokasi, kategori, foto usaha.
- Menu pengaturan: QRIS toko, pelanggan/pengeluaran/diskon, kasir & piutang,
  produk & stok, panduan, privasi, **mode gelap**, Tentang, Keluar.
- `AboutFostifestPage` berisi penjelasan produk dan disclaimer.

### 2.10 QRIS toko (`qris_settings_page.dart`)
- Pilih gambar QRIS dari galeri (Android), simpan path lokal, tampilkan di kasir.
- Hapus QRIS.
- Di web fitur unggah dinonaktifkan.

### 2.11 Asisten "Laras" (`FostiPage`)
- Chat sederhana berbasis aturan (bukan LLM/backend): menjawab ringkasan omzet
  dan jumlah transaksi, dengan chip pertanyaan cepat.
- FAB "Laras" tersedia di hampir semua tab.

---

## 3. Arsitektur Sistem

### 3.1 Ringkasan arsitektur
Aplikasi adalah **monolit Flutter client-side**:

```
┌──────────────────────────────────────────────┐
│                 Flutter UI                    │
│  MaterialApp (theme light/dark, phone frame)  │
│  Navigator + MaterialPageRoute + bottom nav   │
│  StatefulWidget + setState (state lokal)      │
└───────────────────────┬──────────────────────┘
                        │ baca/tulis langsung
┌───────────────────────▼──────────────────────┐
│           SharedPreferences (lokal)           │
│  JSON string per domain + flag sederhana      │
└───────────────────────┬──────────────────────┘
                        │ fitur platform
┌───────────────────────▼──────────────────────┐
│  Plugin native: image_picker, ML Kit OCR,     │
│  mobile_scanner, path_provider, pdf/printing  │
└──────────────────────────────────────────────┘
```

Karakteristik:
- **Tanpa backend**, tanpa database relasional, tanpa sinkronisasi cloud.
- **Tanpa state management pihak ketiga** (Provider/Bloc/Riverpod): memakai
  `StatefulWidget` + `setState`, `ValueNotifier` tidak dipakai.
- **Tanpa routing package**: `Navigator.push(MaterialPageRoute(...))` dan
  `GlobalKey<NavigatorState>` untuk navigasi dari root.
- **Tanpa repository/DI layer**: setiap halaman membaca/menulis
  `SharedPreferences` secara langsung lalu `jsonDecode/jsonEncode`.
- **Monolit**: sebagian besar UI dan logika ada di `main.dart`; modul besar
  dipisah menjadi file per fitur.

### 3.2 Struktur folder
```
fostifest_companion/
├── lib/
│   ├── main.dart                 # entry, root app, auth, home, ledger, add, legalitas, profil
│   ├── cashier_page.dart         # kasir/POS, piutang, struk PDF, recovery checkout
│   ├── inventory_page.dart       # CRUD produk & stok
│   ├── business_tools_page.dart  # pelanggan, pengeluaran, diskon
│   ├── qris_settings_page.dart   # gambar QRIS toko
│   └── barcode_scanner_page.dart # scanner barcode + input manual
├── test/
│   ├── app_test.dart             # widget/flow test utama
│   ├── cashier_flow_test.dart    # alur kasir
│   ├── barcode_scan_test.dart    # scanner
│   └── proposal_capture_test.dart# capture screenshot untuk proposal
├── web/                          # index.html, manifest, ikon (preview web)
├── android/                      # konfigurasi Android (label, izin kamera, Gradle)
├── assets/images/                # aset gambar (avatar toko)
├── preview_laras.ps1             # build + jalankan preview web
├── preview_server.ps1            # HTTP server lokal 127.0.0.1:43827
├── pubspec.yaml
└── KONTEKS-LARAS.md              # dokumen ini
```

### 3.3 Pembagian tanggung jawab per file

| File | Tanggung jawab utama | Widget/kelas penting |
|---|---|---|
| `main.dart` | Root app, tema, auth, navigasi utama, beranda, catatan/laporan, catat transaksi, legalitas, profil, asisten | `FostifestApp`, `FostifestAppState`, `FostifestSplashScreen`, `FostifestLoginScreen`, `FostifestRegistrationScreen`, `HomePage`, `LedgerPage`, `AddTransactionPage`, `LegalitasPage`, `ProfilePage`, `FostiPage` |
| `cashier_page.dart` | POS, keranjang, diskon/pajak/poin, kasbon, QRIS, struk, recovery | `CashierPage`, `_CashierPageState` |
| `inventory_page.dart` | Produk & stok | `InventoryPage` |
| `business_tools_page.dart` | Pelanggan/pengeluaran/diskon | `BusinessToolsPage` |
| `qris_settings_page.dart` | Penyimpanan gambar QRIS | `QrisSettingsPage` |
| `barcode_scanner_page.dart` | Kamera barcode | `BarcodeScannerPage` |

### 3.4 Navigasi & shell aplikasi
- Root `MaterialApp` punya `navigatorKey` global.
- Setelah login, shell memakai `Scaffold` dengan:
  - `bottomNavigationBar`: `FostifestBottomBar` — 5 item:
    **Beranda (0)**, **Catatan (1)**, **Catat Cerdas (2, tombol tengah naik)**,
    **Legalitas (3)**, **Profil (4)**.
  - `floatingActionButton.extended`: "Laras".
- Halaman fitur lain dibuka dengan `Navigator.push` (Kasir, Produk, Tools, QRIS,
  Edit Profil, Tentang).
- Setiap kembali dari halaman fitur, root memanggil `_loadProfile()` untuk
  memuat ulang data dari storage.
- Tab `Catat Cerdas` (index 2) menyembunyikan FAB dan memakai `AppBar` sendiri.

### 3.5 Tema & UI
- Material 3 (`useMaterial3: true`), palet hijau-putih.
- Konstanta warna utama (nama variabel dipertahankan dari tema lama):
  - `_brandYellow = #0B5D3B` (hijau utama)
  - `_softYellow = #8FE388`, `_gold = #35A565`
  - `_cream = #EAF7EE`, `_warmWhite = #FFFFFF`, `_divider = #DDE9E2`
  - `_ink = #123126`, `_muted = #5F766C`, `_error = #157347`, `_deepGold = #063A27`
- **Light & dark theme** disediakan; `themeMode` dikontrol `dark_mode`.
- Font family: `Roboto`.

### 3.6 Web preview / "bingkai ponsel"
Di `MaterialApp.builder`, jika `kIsWeb`:
- Desktop: aplikasi dirender dalam frame `SizedBox` maksimal **414 x 852**
  di tengah layar berlatar `#E9F1EC`, radius sudut 24.
- Mobile web (< 500 px): layar penuh.
- `MediaQuery` di-override agar ukuran sesuai frame.
- `preview_laras.ps1` membangun `flutter build web --release -O1` lalu menyajikan
  `build/web` lewat `preview_server.ps1` (HttpListener) di
  **http://127.0.0.1:43827/** dengan `Cache-Control: no-cache` + ETag.
- Preview **tidak auto-reload**: jalankan ulang `Buka Preview LARAS.cmd` setelah
  kode berubah, lalu refresh browser.

---

## 4. Alur Data & Model Penyimpanan

### 4.1 Prinsip
- Semua data berupa **JSON string** di `SharedPreferences`.
- Angka uang memakai `int` rupiah (tanpa desimal).
- Tanggal disimpan sebagai **ISO-8601 string**.
- ID entitas memakai `DateTime.now().microsecondsSinceEpoch.toString()`.
- Tidak ada migrasi skema formal (versi disimpan pada nama key `_v1`).

### 4.2 Daftar key `SharedPreferences`

| Key | Tipe | Isi |
|---|---|---|
| `business_name` | String | Nama usaha |
| `business_description` | String | Deskripsi usaha |
| `business_location` | String | Lokasi usaha |
| `business_category` | String | Kategori usaha |
| `business_photo` | String | Path foto usaha (Android) |
| `account_full_name` | String | Nama pemilik akun |
| `account_identifier` | String | Email/no. WA (lowercase) |
| `account_password` | String | Kata sandi (plaintext, lokal) |
| `dark_mode` | bool | Mode gelap |
| `legal_nib` | bool | NIB lengkap |
| `legal_brand` | bool | P-IRT / merek lengkap |
| `legal_halal` | bool | Sertifikasi halal |
| `laras_transactions_v1` | JSON list | Pembukuan transaksi |
| `laras_products_v1` | JSON list | Produk & stok |
| `laras_sales_v1` | JSON list | Penjualan kasir |
| `laras_customers_v1` | JSON list | Pelanggan + poin |
| `laras_expenses_v1` | JSON list | Pengeluaran |
| `laras_discounts_v1` | JSON list | Diskon tersimpan |
| `laras_held_carts_v1` | JSON list | Keranjang ditahan |
| `laras_qris_path` | String | Path gambar QRIS |
| `laras_checkout_pending` | JSON object | Backup checkout untuk recovery |

### 4.3 Skema objek

**TransactionItem** (`laras_transactions_v1`):
```json
{
  "name": "Batik motif Sekar",
  "amount": 480000,
  "date": "2026-11-07T10:15:00.000",
  "source": "Manual | Tempel chat | Scan struk | Kasir <iso-date>"
}
```

**Produk** (`laras_products_v1`):
```json
{
  "name": "Batik Sekar",
  "sku": "BKS-001",
  "category": "Batik",
  "price": 250000,
  "cost": 150000,
  "stock": 10,
  "min": 2
}
```

**Penjualan** (`laras_sales_v1`):
```json
{
  "date": "2026-11-07T10:15:00.000",
  "items": [
    { "name": "Batik Sekar", "price": 250000, "cost": 150000, "quantity": 2 }
  ],
  "customer": "Ibu Sari",
  "customerId": "1730...",
  "pointsUsed": 0,
  "pointsEarned": 5,
  "method": "Tunai | QRIS | Transfer | Kasbon",
  "subtotal": 500000,
  "discount": 50000,
  "pointsDiscount": 0,
  "tax": 45000,
  "total": 495000,
  "paid": true,
  "received": 500000,
  "paidAt": "2026-11-07T10:20:00.000"
}
```

**Pelanggan** (`laras_customers_v1`):
```json
{ "id": "1730...", "name": "Ibu Sari", "detail": "0812...", "points": 12, "createdAt": "..." }
```

**Pengeluaran** (`laras_expenses_v1`):
```json
{ "id": "1730...", "name": "Listrik", "detail": "Operasional", "amount": 150000, "createdAt": "..." }
```

**Diskon** (`laras_discounts_v1`):
```json
{ "id": "1730...", "name": "Promo Akhir Tahun", "detail": "", "amount": 10, "type": "Persen | Nominal", "createdAt": "..." }
```

**Checkout pending** (`laras_checkout_pending`):
```json
{
  "products": [ /* snapshot produk setelah stok dikurangi */ ],
  "sale": { /* objek penjualan */ },
  "customerUpdate": { "id": "1730...", "points": 17 }
}
```

### 4.4 Aturan bisnis penting

**Omzet & laba (bulanan)**
- Omzet bulan ini = jumlah `amount` transaksi pada bulan berjalan.
- Estimasi laba = `monthlyRevenue - monthlyExpense - monthlyCost`.
- `monthlyExpense` = pengeluaran bulan ini.
- `monthlyCost` = total `cost * quantity` dari item penjualan kasir bulan ini.

**Laporan laba-rugi**
- `income` = total transaksi bulan terpilih.
- `operatingExpense` = total pengeluaran bulan terpilih.
- `costOfGoods` = modal barang terjual dari penjualan kasir.
- `expense` = operatingExpense + costOfGoods.
- `tax` = `round(income * 0.005)` (estimasi PPh final 0,5%).

**Kasir**
- `gross` = Σ harga jual × qty.
- Diskon manual di-clamp `0..gross`.
- Diskon tersimpan: persen dihitung dari harga setelah diskon manual;
  nominal diterapkan lalu di-clamp.
- Tukar poin: maksimal `floor((gross - reduction) / 100)`, tiap poin = Rp100.
- `base` = `gross - reduction - usedPoints*100`.
- Pajak = `base * taxRate%`.
- Poin diperoleh (bukan kasbon) = `base ~/ 10000` (1 poin / Rp10.000).
- Kasbon tidak mendapat poin.
- Checkout memvalidasi ulang produk & stok dari storage sebelum menulis.

**Stok**
- Checkout mengurangi `stock` sesuai qty.
- Halaman inventaris menandai "Stok menipis" bila `stock <= min`.
- Barcode ganda ditolak (validasi SKU unik).

**Recovery checkout**
- Sebelum menulis, snapshot `{products, sale, customerUpdate}` disimpan ke
  `laras_checkout_pending`.
- `recover()` menulis ulang produk, menambahkan penjualan & transaksi ledger,
  memperbarui poin pelanggan, lalu menghapus key pending.
- Selama pending ada, Kasir/Inventaris/Tools menampilkan status terkunci
  "Buka menu kasir untuk menyelesaikan pemulihan transaksi."

---

## 5. Dependensi & Justifikasi Teknologi

| Paket | Versi | Fungsi | Alasan |
|---|---|---|---|
| `flutter` (SDK) | — | Framework UI | Satu basis kode, performa native, ekosistem matang |
| `shared_preferences` | ^2.3.2 | Penyimpanan key-value lokal | Ringan, tanpa backend, cocok untuk MVP offline-first |
| `image_picker` | ^1.1.2 | Ambil foto kamera/galeri | OCR struk & foto profil/QRIS |
| `google_mlkit_text_recognition` | ^0.15.0 | OCR teks Latin | Input transaksi dari foto struk |
| `mobile_scanner` | 7.5.0 | Scan barcode | Kasir cepat & pengisian SKU |
| `pdf` | ^3.11.1 | Generate PDF | Laporan laba-rugi & struk |
| `printing` | ^5.13.4 | Bagikan/cetak PDF | Integrasi print/share Android |
| `path_provider` | ^2.1.5 | Direktori dokumen aplikasi | Simpan foto usaha/QRIS |
| `flutter_lints` | ^5.0.0 | Lint (dev) | Standar kualitas kode |

Prinsip: **offline-first, minim dependensi, tanpa layanan berbayar**, agar aplikasi
ringan dan bisa dipakai UMKM tanpa koneksi stabil.

---

## 6. Konfigurasi Platform

### 6.1 `pubspec.yaml`
- `name: fostifest_companion`
- `environment.sdk: '>=3.5.0 <4.0.0'`
- `version: 1.0.0+1`
- Asset: `assets/images/batik-store-avatar.jpg`

### 6.2 Android
- `applicationId` / `namespace`: `org.fostiums.fostifest_companion`
- `android:label`: **LARAS UMKM**
- Izin: `android.permission.CAMERA`
- Java/Kotlin target: **17**
- Release: `isMinifyEnabled = false`, `isShrinkResources = false`
  (agar dependency ML Kit tetap lengkap di runtime)
- **Catatan**: release masih memakai `signingConfigs.getByName("debug")`
  (belum signing key produksi).
- APK tersedia: `FOSTIFEST-2026-arm64-release.apk`.

### 6.3 Web
- `web/index.html` berjudul **LARAS UMKM Preview**, ada layar loading
  "Menyiapkan preview..." sampai event `flutter-first-frame`.
- `web/manifest.json` + ikon PWA.
- Build preview: `flutter build web --release -O1 --no-wasm-dry-run`.
- Server preview: `Net.HttpListener` di `http://127.0.0.1:43827/`,
  serve folder `build/web`, MIME type umum, ETag, `no-cache`.

### 6.4 Batasan platform (web vs Android)
| Fitur | Web preview | Android |
|---|---|---|
| Kamera/galeri, OCR struk | Dinonaktifkan (`kIsWeb`) | Tersedia |
| Ganti foto usaha | Dinonaktifkan | Tersedia |
| Unggah QRIS | Dinonaktifkan | Tersedia |
| Cetak/bagikan PDF | Bergantung browser | Tersedia via `printing` |
| Scan barcode | Kamera web terbatas | Tersedia |
| Penyimpanan | `localStorage` (terpisah dari APK) | `SharedPreferences` perangkat |

---

## 7. Cara Menjalankan & Build

### 7.1 Development
```powershell
cd fostifest_companion
flutter pub get
flutter run
```

### 7.2 Build APK ARM64 (release)
```powershell
flutter build apk --release --target-platform android-arm64 `
  --obfuscate --split-debug-info=build/symbols/arm64
```

### 7.3 Preview web lokal (yang dipakai untuk demo)
1. Klik dua kali `Buka Preview LARAS.cmd` di root proyek.
2. Skrip `preview_laras.ps1` cek apakah `lib/`, `web/`, atau `pubspec.yaml`
   lebih baru dari `build/web/index.html`.
3. Jika perlu, build web release (beberapa menit).
4. Jalankan `preview_server.ps1`, buka `http://127.0.0.1:43827/`.
5. Login lewat **"Masuk ke akun demo LARAS UMKM"** untuk demo cepat.
6. Setelah mengubah kode: jalankan ulang `.cmd`, lalu refresh browser.

### 7.4 Testing
```powershell
cd fostifest_companion
flutter test
flutter analyze
```
Test yang tersedia:
- `test/app_test.dart` — header beranda, pencarian fitur, tombol/tema,
  legalitas, catatan/laporan, registrasi & login, kalender, asisten, edit profil.
- `test/cashier_flow_test.dart` — alur kasir.
- `test/barcode_scan_test.dart` — scanner.
- `test/proposal_capture_test.dart` — capture tampilan untuk proposal.

---

## 8. Batasan, Risiko, dan Utang Teknis

1. **Tanpa backend**: tidak ada sinkronisasi antar perangkat, tidak ada backup
   cloud, data hilang jika aplikasi dihapus/data dibersihkan.
2. **Keamanan akun lemah**: kata sandi disimpan plaintext di `SharedPreferences`;
   login hanyalah pencocokan lokal, bukan autentikasi aman.
3. **`main.dart` monolitik** (~3.500+ baris): disarankan dipecah per fitur
   (home, auth, ledger, add transaction, profile, assistant).
4. **Tidak ada lapisan repository/state management**: logika storage tersebar
   dan diduplikasi di beberapa halaman; rawan inkonsistensi.
5. **Ketidaksesuaian versi**: `pubspec.yaml` `1.0.0+1` vs halaman Tentang `1.5.0`.
6. **Signing release masih debug key**; perlu keystore produksi sebelum rilis.
7. **Web vs Android tidak paritas**: fitur kamera/OCR/QRIS/cetak tidak tersedia
   atau berbeda di web.
8. **OCR terbatas** pada script Latin dan kualitas foto; hasil harus dikoreksi manual.
9. **Mata uang integer rupiah**, tanpa dukungan desimal/mata uang lain.
10. **Transaksi ledger tidak bisa diedit/hapus** dari UI (hanya tambah).
11. **Tidak ada migrasi skema**; perubahan struktur JSON perlu penanganan manual.
12. **Belum ada pengujian integrasi storage/recVOery** selain widget test.

---

## 9. Rencana Pengembangan (Potensi)

- Pisahkan `main.dart` menjadi modul (`features/`, `models/`, `repositories/`).
- Tambah layer repository + state management (mis. Riverpod) dan migrasi skema.
- Enkripsi kredensial / autentikasi nyata; opsi login biometrik.
- Backup/restore lokal (file JSON) dan sinkronisasi cloud opsional.
- Edit/hapus transaksi, filter tanggal lanjutan, ekspor CSV/Excel.
- OCR struk lebih pintar (parsing item multi-baris) dan mode kamera langsung.
- Multi-outlet, multi-pengguna, dan peran kasir/admin.
- Notifikasi stok menipis dan piutang jatuh tempo.
- Laporan grafik lebih kaya dan perbandingan antar periode.
- **Modul vendor/supplier** (`laras_suppliers_v1`) dengan label biaya (cost)
  dan riwayat pembelian (D7).
- **Analitik kenaikan harga bahan baku** (`laras_material_prices_v1`):
  catat harga per supplier, lacak persentase kenaikan dari periode sebelumnya,
  estimasi dampak ke harga pokok dan margin, plus rekomendasi efisiensi
  atau penyesuaian harga jual (D6).
- **Budgeting & cashflow**: anggaran per vendor/supplier, proyeksi uang masuk
  vs keluar, dan tampilan cashflow harian/3 hari/7 hari/1 bulan (D4, D5).
- **Kategori biaya terstruktur**: Marketing/iklan (spanduk, cetak, menu),
  Produksi, Operasional, Bahan baku; laporan per kategori (D8).
- **Template laporan keuangan** yang bisa dipilih/dikustomisasi UMKM (D3).
- **Kalkulator harga jual & break-even** berbasis modal, margin target, dan pajak (D2).
- Aksesibilitas (font scaling, kontras) dan lokalisasi.
- Signing produksi + pipeline CI (analyze, test, build) sebelum rilis Play Store.

---

## 10. Peta Cepat File → Fitur

| Kebutuhan | Buka |
|---|---|
| Entry point, tema, auth, navigasi | `lib/main.dart` (`FostifestApp`) |
| Beranda & pencarian fitur | `lib/main.dart` (`HomePage`, `_FeatureSearch`) |
| Catatan, kalender, laporan, PDF | `lib/main.dart` (`LedgerPage`) |
| Catat transaksi + OCR | `lib/main.dart` (`AddTransactionPage`) |
| Legalitas | `lib/main.dart` (`LegalitasPage`) |
| Profil & pengaturan | `lib/main.dart` (`ProfilePage`, `EditBusinessProfilePage`, `AboutFostifestPage`) |
| Asisten Laras | `lib/main.dart` (`FostiPage`) |
| Kasir/POS, kasbon, struk, recovery | `lib/cashier_page.dart` |
| Produk & stok | `lib/inventory_page.dart` |
| Pelanggan/pengeluaran/diskon | `lib/business_tools_page.dart` |
| QRIS toko | `lib/qris_settings_page.dart` |
| Scanner barcode | `lib/barcode_scanner_page.dart` |
| Format Rupiah & tanggal | `lib/main.dart` (`formatRupiah`, `formatCompactRupiah`, `formatDate`, `formatMonthYear`) |
| Preview web | `preview_laras.ps1`, `preview_server.ps1`, `web/` |
| Konfigurasi | `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` |

---

## 11. Ringkasan Satu Paragraf

LARAS UMKM adalah MVP aplikasi Flutter offline-first untuk **manajemen keuangan UMKM**
yang sekaligus menjadi alat **analisa dan monitoring omzet, laba, dan margin
keuntungan**, pemberi arah **upscale bisnis dan marketing**, serta penyiap
**administrasi dan legalitas usaha**. Secara fitur ia mencatat transaksi
(manual/chat/OCR), menjalankan kasir dengan barcode, diskon, poin, kasbon, dan QRIS,
mengelola produk/stok/pelanggan/pengeluaran, menyusun laporan laba-rugi dengan
estimasi PPh final 0,5% dan ekspor PDF, memantau tren omzet serta produk terlaris,
dan mencatat status dokumen legalitas. Arsitekturnya adalah monolit client-side
berbasis `StatefulWidget` + `setState`, navigasi `Navigator`, dan penyimpanan
`SharedPreferences` berformat JSON, tanpa backend maupun state management eksternal,
dengan demo web preview berbingkai ponsel di `http://127.0.0.1:43827/`.
