# Changelog

Semua perubahan penting pada LARAS UMKM dicatat di berkas ini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/) secara sederhana.

## Unreleased

### Ditambahkan

- Halaman **Simulasi Harga** yang dapat dibuka dari Manage Cerdas, dengan perhitungan untung/rugi/impas, margin, proyeksi total, dan penyimpanan maksimal 10 skenario lokal.
- Halaman **Legalitas** baru berbasis profil usaha, skala, KBLI, risiko OSS, rekomendasi, detail dokumen, dan checklist lokal.
- Migrasi checklist legalitas lama ke format baru.
- Sistem desain dan komponen UI LARAS: token warna, tipografi, komponen formulir, kartu, dan widget pendukung.
- Font Poppins dan Plus Jakarta Sans beserta lisensi OFL.
- Dukungan mode gelap dan pengujian tata letak adaptif 360–414 px.
- Template pull request di `.github/pull_request_template.md`.

### Diubah

- Penyegaran tampilan beranda, Manage Cerdas, supplier, produk/stok, margin, transaksi, laporan, legalitas, dan profil.
- README utama disusun ulang sebagai halaman produk dan panduan repositori.
- README aplikasi diringkas agar tidak menduplikasi README utama.
- `.gitignore` diperluas untuk file IDE, log, environment, secret, dan artefak lokal.
- Golden screenshot proposal diperbarui dan dilengkapi.

### Diperbaiki

- Overflow pada layar sempit dan ukuran teks besar.
- Konsistensi kontras dan keterbacaan pada mode gelap.
- Validasi serta penyimpanan data simulasi harga.
- Pembacaan data legalitas lama agar halaman tetap dapat dibuka.

### Pengujian

- Tes adaptive design untuk 360, 375, 414, dan tablet.
- Tes form layout untuk transaksi, produk, dan supplier.
- Tes aturan legalitas.
- Tes simulasi harga, termasuk penyimpanan, pembukaan ulang, dan penghapusan skenario.
- Seluruh 78 tes lulus pada branch `review/laras-ui-refresh`.

### Dokumentasi

- Menambahkan `CONTRIBUTING.md`, `DESIGN.md`, `SECURITY.md`, dan `CHANGELOG.md`.
- Menambahkan catatan status lisensi dan batasan aplikasi.
