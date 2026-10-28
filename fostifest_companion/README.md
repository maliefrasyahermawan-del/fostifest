# FOSTIFEST Finance

Aplikasi keuangan Flutter untuk UMKM yang diadaptasi dari Logicodix/BUMIRA dan direbranding dengan identitas hijau-putih FOSTIFEST. Aplikasi ini merupakan produk lomba, bukan aplikasi pengelolaan proses perlombaan.

## Fitur MVP

- Dashboard omzet, laba bersih, skor kesiapan, tren, dan produk terlaris.
- Pembukuan transaksi melalui input manual, chat, atau OCR foto struk.
- Kalender transaksi dan laporan laba-rugi yang dapat dibagikan sebagai PDF.
- Analisis kelayakan usaha, simulasi KUR, dan daftar legalitas UMKM.
- Profil usaha lokal serta asisten keuangan Fosti.

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
