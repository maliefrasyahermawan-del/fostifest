# LARAS UMKM — Proyek Flutter

Folder ini berisi kode aplikasi Flutter LARAS UMKM. Untuk ringkasan produk, fitur, tangkapan layar, dan struktur repositori, lihat [README utama](../README.md).

## Menjalankan

```powershell
flutter pub get
flutter run
```

Untuk web:

```powershell
flutter run -d chrome
```

Prasyarat: Flutter stable dengan Dart SDK sesuai `pubspec.yaml`. Build Android memerlukan Android SDK.

## Pemeriksaan kualitas

```powershell
flutter analyze lib test
flutter test
```

Golden screenshot proposal:

```powershell
flutter test test/proposal_capture_test.dart
```

Perbarui golden hanya untuk perubahan tampilan yang disengaja:

```powershell
flutter test test/proposal_capture_test.dart --update-goldens
```

## Build

```powershell
flutter build web --release -O1 --no-wasm-dry-run
flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols/arm64
```

Hasil build berada di `build/` dan tidak dilacak Git. APK tidak disertakan di repositori.

## Struktur singkat

```text
lib/        kode aplikasi, tema, komponen, dan fitur
assets/     gambar dan font
test/       pengujian dan screenshot proposal
web/        konfigurasi Flutter Web
android/    konfigurasi Android
```

## Data

Aplikasi memakai `SharedPreferences` untuk data lokal. Build default tidak membutuhkan server. Kait backend opsional di `lib/laras_api.dart` hanya aktif jika build dikonfigurasi dengan `LARAS_BACKEND=true` dan `LARAS_API_URL`.

## Dokumen terkait

- [README utama](../README.md)
- [Panduan kontribusi](../CONTRIBUTING.md)
- [Panduan desain](../DESIGN.md)
- [Konteks produk](KONTEKS-LARAS.md)
- [Laporan implementasi](LARAS_IMPLEMENTATION_REPORT.md)
