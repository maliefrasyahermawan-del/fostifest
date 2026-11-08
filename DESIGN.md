# Panduan Desain LARAS UMKM

Dokumen ini merangkum token dan aturan tampilan yang dipakai aplikasi. Sumber utama ada di `fostifest_companion/lib/laras_design.dart`, `laras_components.dart`, `laras_fintech_widgets.dart`, dan `laras_forms.dart`.

## Prinsip

- Utamakan keterbacaan di layar ponsel.
- Gunakan bahasa Indonesia yang sederhana dan langsung.
- Tampilkan informasi penting lebih dulu: nominal, status, dan tindakan berikutnya.
- Hindari dekorasi yang tidak membantu pemahaman.
- Pastikan tampilan tetap nyaman pada mode terang, mode gelap, dan ukuran teks besar.

## Warna

| Token | Nilai | Penggunaan |
|---|---|---|
| Hijau utama | `#087B58` | Tombol utama, aksen, fokus |
| Hijau merek | `#15946C` | Aksen sekunder |
| Tinta | `#22313A` | Teks utama mode terang |
| Mint | `#E5F4EE` | Latar lembut mode terang |
| Latar terang | `#F6F7F9` | Latar halaman mode terang |
| Permukaan gelap | `#1B2B34` | Kartu mode gelap |
| Latar gelap | `#101C23` | Latar halaman mode gelap |
| Teks gelap | `#F2F6F8` | Teks utama mode gelap |
| Aksen gelap | `#6ADCB0` | Aksen mode gelap |

Warna status, garis, dan latar kartu diturunkan dari token di `LarasDesign`. Jangan menulis nilai warna baru langsung di halaman tanpa alasan.

## Tipografi

- Font tema: **Poppins**.
- Plus Jakarta Sans tersedia di `assets/fonts/` untuk kebutuhan khusus, tetapi bukan font tema utama.
- Judul halaman: 24–26 px, bobot 600, tinggi baris rapat.
- Teks isi: 14–16 px, tinggi baris 1.5–1.6.
- Teks bantuan: 12–13 px dengan kontras yang tetap memadai.

## Bentuk dan jarak

- Radius tombol dan input: 14 px.
- Radius kartu data: 18 px.
- Radius kartu utama: 20–24 px.
- Dialog: 28 px.
- Padding halaman: 20 px kiri-kanan.
- Jarak antar kelompok: 24–28 px.
- Tombol utama memiliki tinggi minimum 54 px agar mudah disentuh.

## Komponen

- `LarasPageIntro` — judul, deskripsi, dan label kecil halaman.
- `LarasDataCard` — ringkasan data dengan ikon dan aksi.
- `LarasRecordCard` — baris catatan transaksi atau riwayat.
- `LarasSegmentedTabs` — pemilih tab ringkas.
- `LarasShortcutGrid` dan `LarasQuickAction` — navigasi fitur di Manage Cerdas.
- `LarasForms` — gaya formulir, validasi, dan tombol simpan.

Gunakan komponen yang sudah ada sebelum membuat variasi baru.

## Mode gelap

- Gunakan `LarasDesign.text(context)`, `secondary(context)`, `soft(context)`, dan `line(context)` agar warna mengikuti tema.
- Jangan memakai warna latar terang secara langsung pada teks atau kartu.
- Periksa kontras tombol, label, dan pesan kesalahan pada mode gelap.

## Tampilan adaptif

- Sasaran utama: lebar 360–414 px.
- Layar lebar boleh memakai dua kolom melalui `LarasAdaptivePair`.
- Hindari lebar tetap yang menyebabkan overflow.
- Gunakan `SingleChildScrollView`, `ListView`, atau `Flexible` untuk konten panjang.
- Formulir harus tetap dapat disimpan saat keyboard terbuka.

## Gerak dan aksesibilitas

- Animasi masuk memakai `LarasEntrance` dengan durasi pendek.
- Hormati preferensi sistem untuk mengurangi animasi.
- Sediakan label atau tooltip untuk ikon tanpa teks.
- Pastikan target sentuh cukup besar dan urutan fokus masuk akal.

## Penulisan antarmuka

- Gunakan kalimat pendek dan kata kerja yang jelas.
- Hindari klaim “terbaik”, “100% aman”, atau “sepenuhnya otomatis”.
- Jelaskan estimasi sebagai estimasi, bukan kepastian.
- Gunakan istilah yang konsisten: “pemasukan”, “pengeluaran”, “modal”, “margin”, “simulasi harga”, “legalitas”.
