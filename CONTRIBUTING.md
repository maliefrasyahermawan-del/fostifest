# Panduan Kontribusi

Terima kasih telah membantu LARAS UMKM. Panduan ini dibuat agar perubahan mudah ditinjau dan tidak merusak data pengguna.

## 1. Menyiapkan lingkungan

1. Pasang Flutter stable. Versi Dart yang didukung tercantum di `fostifest_companion/pubspec.yaml`.
2. Untuk build Android, pasang Android SDK. Untuk web, gunakan browser berbasis Chromium.
3. Ambil dependensi:

```powershell
cd fostifest_companion
flutter pub get
```

## 2. Membuat branch

Jangan bekerja langsung di `main`. Buat branch dari `main` dengan format berikut:

| Awalan | Kegunaan | Contoh |
|---|---|---|
| `feat/` | Fitur baru | `feat/simpan-supplier` |
| `fix/` | Perbaikan bug | `fix/margin-negatif` |
| `docs/` | Dokumentasi | `docs/readme-juri` |
| `review/` | Branch khusus review | `review/laras-ui-refresh` |
| `chore/` | Perawatan/konfigurasi | `chore/gitignore` |

Gunakan huruf kecil dan tanda hubung. Satu branch sebaiknya fokus pada satu tujuan.

## 3. Sebelum commit

Jalankan dari folder `fostifest_companion`:

```powershell
dart format lib test
flutter analyze lib test
flutter test
```

Jika mengubah tampilan, jalankan juga golden test dan periksa hasilnya:

```powershell
flutter test test/proposal_capture_test.dart
```

Perbarui golden hanya jika perubahan tampilan memang disengaja:

```powershell
flutter test test/proposal_capture_test.dart --update-goldens
```

Jika mengubah kode Flutter, pastikan build web tetap berhasil:

```powershell
flutter build web --release -O1 --no-wasm-dry-run
```

## 4. Yang tidak boleh di-commit

- `.dart_tool/`, `build/`, dan `coverage/`
- `test/failures/` atau hasil golden yang gagal
- File IDE lokal (`.idea/`, `.vscode/`, `*.iml`)
- Log, file sementara, dan arsip
- APK, AAB, ZIP, atau artefak build lain
- Password, token, kredensial, `.env`, dan data pribadi

Periksa sebelum commit:

```powershell
git status --short
git diff --cached --check
```

## 5. Membuat pull request

1. Push branch ke remote.
2. Buka pull request ke `main` dan isi template yang tersedia.
3. Sertakan ringkasan, alasan perubahan, dan langkah pengujian.
4. Untuk perubahan UI, sertakan screenshot sebelum/sesudah.
5. Pastikan mode terang dan gelap diperiksa, termasuk layar 360–414 px.
6. Jelaskan jika ada perubahan format data atau migrasi penyimpanan.

Jangan menggabungkan pull request tanpa review dari pengelola.

## 6. Pedoman UI

- Gunakan Bahasa Indonesia yang sederhana dan konsisten.
- Hindari istilah pemasaran berlebihan atau klaim yang tidak dapat dibuktikan.
- Ikuti token, komponen, dan aturan di [`DESIGN.md`](DESIGN.md).
- Jangan menambahkan warna, font, atau komponen baru tanpa alasan yang jelas.
- Pastikan teks tetap terbaca pada mode gelap dan ukuran teks besar.
- Sediakan label atau tooltip untuk ikon yang tidak memiliki teks.

## 7. Data dan kompatibilitas

- Jangan mengubah kunci `SharedPreferences` yang sudah dipakai tanpa migrasi.
- Jangan menghapus data pengguna secara diam-diam.
- Jika menambah field baru, pastikan data lama tetap dapat dibaca.
- Uji alur simpan, buka ulang, dan hapus pada fitur yang menyimpan data.

## 8. Pertanyaan

Untuk pertanyaan teknis, gunakan diskusi tim atau issue internal. Untuk masalah keamanan, ikuti [`SECURITY.md`](SECURITY.md).
