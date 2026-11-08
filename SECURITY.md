# Kebijakan Keamanan

## Melaporkan masalah keamanan

Jangan melaporkan kerentanan melalui issue publik. Issue publik dapat memperbesar risiko sebelum masalah diperbaiki.

Gunakan jalur privat berikut:

- Hubungi ketua tim atau pengelola repositori melalui kanal internal tim.
- Jika repositori sudah memiliki fitur **Security advisory**, gunakan fitur tersebut.
- Sertakan langkah reproduksi, dampak, dan versi yang terdampak.

Kontak resmi belum tersedia di repositori ini. Pengelola perlu mengisi alamat atau kanal resmi sebelum repositori dipublikasikan secara luas:

> `TODO(pengelola): isi kontak keamanan resmi di sini.`

Jangan mengarang alamat email atau kanal komunikasi.

## Data yang tidak boleh di-commit

- Password, token akses, API key, dan kredensial lain.
- Berkas `.env` atau konfigurasi rahasia.
- Data pribadi pengguna, pelanggan, atau mitra.
- Sertifikat, keystore, dan private key.
- Tangkapan layar yang memuat data sensitif.

Jika kredensial tidak sengaja ter-commit, anggap kredensial tersebut bocor. Cabut atau ganti kredensial, lalu bersihkan riwayat repositori sesuai prosedur tim.

## Ruang lingkup

Aplikasi ini menyimpan data secara lokal dan tidak menyertakan backend produksi. Namun, laporan tetap diterima untuk masalah seperti:

- Kebocoran data lokal yang tidak semestinya.
- Penyimpanan kata sandi yang tidak aman.
- Validasi input yang dapat merusak data.
- Ketergantungan pihak ketiga dengan kerentanan yang diketahui.

## Batasan

Proyek ini dikembangkan untuk kompetisi dan belum melalui audit keamanan independen. Jangan gunakan aplikasi untuk data usaha yang sangat sensitif tanpa pengamanan tambahan.
