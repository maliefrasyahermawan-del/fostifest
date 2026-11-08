# Analisis statis KasirGo+ 1.9.7

## Cakupan dan bukti

APK `KasirGo+.apk`, package `com.yl.kasirgoplus`, versionCode 87, berukuran 26.698.672 byte. SHA-256: `db50fb57f0be95beeb4781b83c8223eee5397e1f5448fece127fa6bb7d4fea6f`. Target Android 36, minimum Android 24. REA `inspect-artifact` menginventarisasi arsip; bundel `assets/index.android.bundle` adalah Hermes bytecode v96. REA tidak memproses bytecode tersebut sebagai JavaScript, sehingga digunakan hermes-dec untuk disassembly. Hasil lengkap tersimpan di `tmp/kasirgo-analysis/disassembly.txt`. Analisis tidak menjalankan aplikasi dan tidak memverifikasi perilaku server.

### Komposisi paket APK

Inventaris arsip berisi 1.019 entri, sekitar 33,54 MB total ukuran tak terkompresi. Empat DEX menyumbang 18,42 MB, Hermes bundle 6,47 MB, 34 font TrueType 6,14 MB, dan tiga model barcode TensorFlow Lite 0,88 MB. Dalam arsip terkompresi, font mengambil sekitar 3,06 MB; Hermes bundle juga sekitar 3,06 MB. Angka ini menjelaskan peluang nyata penghematan APK bila font ikon yang tak dipakai dihilangkan. Sebanyak 19 file font ikon dari beberapa keluarga vector-icons tampak dibundel. Uji dampak penghapusan model barcode sebelum memangkasnya. ABI split berpotensi kecil manfaatnya untuk APK sampel ini karena tidak tampak folder `lib/` maupun file native `.so`; manfaat ARM64 perlu diukur pada APK Fostifest yang sebenarnya, tidak diasumsikan dari nama arsitektur.

Temuan berbasis teks dan instruksi statis menunjukkan kemampuan yang disertakan, bukan jaminan bahwa fitur dapat diakses setiap akun atau berfungsi dalam semua kondisi. Pesan perubahan versi lama dapat bertentangan dengan perilaku versi terbaru.

## Konsep produk

KasirGo+ memadukan penjualan di kasir, inventaris, pelanggan, laporan, pengaturan toko, dan akses beberapa pengguna. Teks dalam APK juga menunjukkan paket Free dan Pro, sinkronisasi cloud, serta dukungan transaksi offline. Konsep utamanya menghubungkan item transaksi ke pengurangan atau pemulihan stok dan laporan penjualan.

## Struktur dan fitur

1. **Kasir dan transaksi.** Label Kasir muncul pada disassembly baris 388232, Laporan pada 388275, dan Pengaturan pada 388291. Teks lain menunjukkan pencarian produk, barcode/SKU, varian produk, keranjang, transaksi, diskon item dan global, edit/hapus transaksi, dan tanggal transaksi yang dapat diatur mundur. Ini mengindikasikan alur pilih produk, atur jumlah dan diskon, lalu selesaikan pembayaran; urutan dan kondisi setiap layar belum terverifikasi.
2. **Produk dan stok.** Terdapat teks tambah/edit/hapus produk, varian, barcode, harga modal, stok tak terbatas, penyesuaian stok, riwayat mutasi, dan stok menipis. Instruksi yang memuat label Stok Menipis ada pada baris 715396. Teks validasi menunjukkan barcode/SKU tidak boleh digunakan produk lain, dan keranjang dapat disesuaikan ketika stok tidak cukup. Pesan konfirmasi penghapusan transaksi menyebut stok dikembalikan; teks edit transaksi menyebut pengurangan item memulihkan stok setelah penyimpanan.
3. **Pelanggan dan kasbon.** Terdapat pencarian pelanggan berdasarkan nama atau nomor HP, pengelolaan pelanggan, metode kasbon, dan penandaan pelunasan. Teks validasi menyebut kasbon memerlukan pilihan pelanggan atau nama. Belum dapat dipastikan seluruh siklus utang atau aturan pembayarannya hanya dari teks.
4. **Pembayaran dan struk.** Teks aplikasi menjelaskan pengunggahan gambar QRIS toko yang ditampilkan saat checkout QRIS. Terdapat template struk HTML berisi identitas usaha, nomor transaksi, kasir, pelanggan, item, diskon, total, dan pembayaran. Teks bantuan menyebut printer thermal Bluetooth 58 atau 80 mm serta pengaturan header dan footer. Izin Bluetooth dan kamera tercantum pada manifest.
5. **Laporan dan pengeluaran.** Terdapat ringkasan omzet, jumlah dan rata-rata transaksi, produk terlaris, modal dan keuntungan, filter tanggal dan staf, dan ekspor PDF/XLSX. Label Pengeluaran dimuat pada baris 955557. Teks menyatakan data modal dan keuntungan dibatasi untuk owner/admin. Teks mengenai visibilitas transaksi berbeda antar catatan perubahan, sehingga aturan aktif perlu ditelusuri lebih lanjut.
6. **Akun dan izin.** Teks menunjukkan peran owner, admin, dan kasir, serta pembatasan pengelolaan produk, diskon, pelanggan, kasir, dan edit/hapus transaksi. Sinkronisasi antarperangkat disebut tersedia jika diaktifkan. Izin efektif dan penegakan di server belum diverifikasi.
7. **Offline dan penyimpanan.** Banner menyatakan transaksi tetap dapat dilakukan tanpa internet dan sinkronisasi dilanjutkan setelah koneksi kembali jika diaktifkan. Teks lain menyatakan foto produk lokal, sedangkan transaksi, stok dan pengaturan disinkronkan ke cloud saat online. Mekanisme antrean, penyelesaian konflik, enkripsi, dan jaminan penyimpanan belum terbukti.
8. **Paket Free/Pro.** Teks menyebut pembatasan jumlah produk, transaksi harian dan pengguna serta opsi upgrade Pro. Angka dalam paket saling bertentangan, termasuk 30 dan 50 transaksi per hari; jangan menganggap salah satunya sebagai ketentuan aktif tanpa menelusuri kondisi kode atau menguji versi ini.

## UI dan UX yang dapat disimpulkan

Instruksi dan teks mengindikasikan label navigasi Kasir, Laporan, dan Pengaturan; pencarian produk dan pelanggan; filter periode/staf; dialog konfirmasi; pengaturan printer; status koneksi; banner offline; pesan validasi; dan keadaan kosong seperti belum ada produk. Desain ini mengarah pada alur operasional kasir dengan umpan balik untuk kesalahan dan status perangkat. Keberadaan label tidak cukup untuk merekonstruksi posisi, ukuran, warna, hierarki visual, urutan layar, aksesibilitas, atau tampilan sesungguhnya. Template struk yang tertanam secara eksplisit menggunakan latar putih dan teks hitam, tetapi itu tidak membuktikan palet UI utama.

## Penelusuran bytecode lebih dalam

Temuan berikut berasal dari pemanggilan fungsi dan konstanta/query yang muncul berdekatan dalam disassembly, jadi tingkat keyakinannya lebih tinggi daripada sekadar kata kunci lepas:

- **Database lokal dan isolasi tenant.** Ada query SQLite untuk daftar produk dengan join kategori dan filter `tenant_id`, penghapusan lunak `deleted_at IS NULL`, urutan prioritas/tanggal/nama, serta query pelanggan serupa. Ini menunjukkan penyimpanan lokal berindeks tenant dan penghapusan lunak pada setidaknya entitas produk, kategori, pelanggan, dan transaksi.
- **PowerSync, bukan sekadar sinkronisasi generik.** Kode memanggil `powersync_init()`, membaca versi dan status sinkronisasi, memeriksa antrean `ps_crud`, membaca `ps_kv`, serta memakai endpoint `/v1/powersync/upload`. Token akses dapat diperbarui melalui `/v1/auth/refresh`. Ada pesan yang secara eksplisit menangani konflik perubahan dan permintaan untuk memeriksa serta menyimpan ulang. Jadi aplikasi memiliki basis data lokal dan jalur unggah perubahan; strategi resolusi konflik rinci belum dapat dipastikan.
- **Validasi data.** Query mencegah nama kategori duplikat di tenant yang sama dan barcode produk duplikat, kecuali record yang sedang diedit. Daftar produk hanya mengambil record aktif dan menggabungkan nama kategori. Ini memperkuat gambaran CRUD inventaris dengan pemeriksaan keunikan di lapisan aplikasi.
- **Batas stok.** Fungsi membaca stok produk sebelum perubahan, menolak pengurangan melebihi stok, dan menolak penyesuaian untuk produk berstok tak terbatas. Ada pesan gagal menghapus transaksi lama saat proses edit; artinya penyuntingan transaksi memiliki beberapa langkah dan berpotensi gagal sebagian. Kode memuat pesan bahwa transaksi lama yang hilang di server membatalkan penyimpanan perubahan, dan edit transaksi lama dari tujuh hari memerlukan koneksi internet.
- **Kasbon.** Ada helper `isKasbonPaymentMethod`; alur pelunasan memeriksa bahwa transaksi memang kasbon dan metode pengganti bukan kasbon. Ini mendukung proses konversi utang menjadi pembayaran aktual, bukan sekadar label pembayaran biasa. Teks menandai transaksi kasbon lunas dan membatasi pilihan pelanggan/nama.
- **Pelaporan.** Terdapat endpoint khusus `/v1/reports/transactions`, `/v1/reports/transactions/count`, serta `/v1/reports/expenses`, di samping query lokal transaksi menurut rentang waktu. Ini menunjukkan laporan dapat mengambil data lokal dan layanan server, sehingga perbandingan jumlah atau periode bisa bergantung pada status sync.
- **Pengaturan backend.** Kode memuat `/v1/business-settings`, unggah/hapus gambar QRIS, serta `/v1/printer-settings`. Objek awal pengaturan struk mempunyai 12 opsi (termasuk 58 mm, pajak nonaktif, metode pembayaran aktif, watermark aktif, nomor urut dan nomor meja aktif). QRIS menyimpan kode, gambar, nama merchant, dan flag aktif.
- **Otorisasi aplikasi.** Matriks permission mencakup kelola kasir, produk, kategori, diskon, pelanggan, edit/hapus transaksi, laporan, riwayat transaksi, pengeluaran, dan QRIS. Contoh satu profil memiliki akses edit transaksi tetapi tidak menghapus transaksi, mengelola pelanggan, atau QRIS; profil yang lebih luas mendapat semua izin yang tercantum. Ini pembuktian konfigurasi UI/app, bukan bukti bahwa backend menerapkan pemeriksaan yang sama.
- **Antarmuka dan pola interaksi.** Navigasi root menyusun layar utama dan menu pengelolaan terpisah; modal digunakan untuk sejumlah interaksi. Navigasi React Native Screens/Native Stack dan komponen modal menunjukkan aplikasi mobile dengan perpindahan layar serta dialog, tetapi tidak memberi koordinat atau komposisi visual layar.

### Peta alur yang didukung bukti

`Pilih produk -> validasi stok dan harga -> buat transaksi / pilih metode bayar -> simpan lokal -> antrekan PowerSync -> unggah ke /v1/powersync/upload -> data dipakai laporan`

Alur edit transaksi memiliki cabang: transaksi lama mungkin memerlukan internet; perubahan stok divalidasi; item yang dihapus atau dikurangi dapat memulihkan stok; kegagalan penghapusan transaksi sumber dapat membatalkan perubahan. Diagram ini adalah rekonstruksi logika dari query, helper, dan pesan bytecode, bukan observasi sesi runtime.

### Risiko dan pertanyaan penting yang masih terbuka

1. Apakah operasi simpan transaksi, detail item, dan mutasi stok dibungkus dalam satu transaksi database atomik? Pesan kegagalan beberapa tahap menandakan ini perlu ditelusuri.
2. Bagaimana PowerSync menyelesaikan konflik: server menang, perangkat menang, merge bidang, atau intervensi pengguna? Baru pesan konflik dan antrean yang ditemukan.
3. Apakah `tenant_id` dan pemeriksaan izin diberlakukan ulang oleh API untuk semua operasi sensitif? Client-side permission saja tidak cukup membuktikannya.
4. Query laporan mana yang memilih sumber lokal atau server, bagaimana paginasi/rentang tanggal bekerja, dan apakah pengeluaran ikut menghitung laba bersih?
5. Subtotal, diskon transaksi, poin, dan pajak telah direkonstruksi sebagian dari helper. Yang masih perlu dipetakan adalah eligibilitas promosi, field nilai saat commit, stok lintas perangkat, serta dukungan kasbon parsial.
6. Komponen UI, warna, ukuran teks, urutan onboarding, navigasi aktual, aksesibilitas, dan keadaan loading/error belum dipetakan dari screenshot atau runtime.

## Bukti lanjutan: sinkronisasi, transaksi, dan laporan

### Sinkronisasi dan integritas data

Disassembly memuat `BEGIN`, `COMMIT`, dan `ROLLBACK` di lapisan storage (contoh sekitar baris 546103–546177 dan 611170). Ini membuktikan aplikasi atau pustaka storage memiliki dukungan transaksi database. Namun belum cukup untuk memastikan operasi checkout tertentu benar-benar membungkus penulisan transaksi, baris item, dan stok dalam satu transaksi atomik. Itu tetap perlu penelusuran fungsi pemanggil.

Antrian `ps_crud` diperiksa melalui query lokal dan diunggah ke `/v1/powersync/upload`. Endpoint tersebut bersama `powersync_offline_sync_status()` dan pesan konflik membuktikan adanya alur offline-first plus pelaporan konflik. Pesan konflik meminta pengguna memeriksa dan menyimpan ulang, jadi setidaknya satu kelas konflik tidak disembunyikan atau otomatis dianggap sukses. Belum ditemukan bukti resolusi merge otomatis per kolom.

### Model data transaksi

Objek yang disiapkan untuk upload memuat bidang `total`, `tax`, `discount`, dan `payment_method` (sekitar baris 704705–704714), beserta `stock_movements`. Ini menunjukkan transaksi dan pergerakan stok diperlakukan sebagai data berbeda yang dikaitkan dalam payload sinkronisasi. Metode pembayaran dan nilai pajak/diskon masuk ke data transaksi, bukan hanya elemen tampilan. Helper aritmetika checkout telah menunjukkan subtotal, diskon baris/transaksi, poin, dan pajak; pemetaan seluruh nilai itu ke payload final tetap perlu dipastikan.

### Riwayat dan batas edit

Query transaksi memakai `tenant_id`, menyaring `deleted_at IS NULL`, dan membatasi timestamp. Ada query jumlah transaksi harian yang mengabaikan transaksi backdate (`coalesce(is_backdated, 0) = 0`), serta pesan batas gratis harian. Teks edit menunjukkan transaksi berumur lebih dari tujuh hari memerlukan internet. Dengan demikian aplikasi membedakan tanggal transaksi mundur dari hitungan transaksi harian gratis, dan memiliki pembatasan edit berdasarkan umur data.

### Laporan dan pengeluaran

Endpoint `/v1/reports/transactions`, `/v1/reports/transactions/count`, `/v1/reports/expenses` tersedia. Ada query lokal transaksi dalam rentang timestamp, query transaksi terhapus, dan query expense berdasarkan tenant. Ini menunjukkan pemisahan data penjualan dan pengeluaran serta dukungan rekap menurut rentang waktu. Belum terbukti apakah angka laporan saat offline identik dengan server setelah ada transaksi tertunda.

### Retensi dan penghapusan

Query umum menggunakan `deleted_at IS NULL`; ada pula query yang mengambil transaksi dengan `deleted_at IS NOT NULL`. Pola ini konsisten dengan soft delete dan kemungkinan kebutuhan pemulihan/sinkronisasi tombstone. Aplikasi menampilkan pesan bahwa transaksi yang sudah hilang di server membuat perubahan edit tidak disimpan. Efeknya, edit bukan sekadar menimpa layar lokal: server dianggap sumber keberadaan transaksi untuk kasus tertentu.

## Pemetaan cakupan setelah pembacaan tambahan

Perkiraan pada tahap pembacaan awal: identifikasi subsistem sekitar 70%, mekanisme lokal/sinkronisasi 45%, aturan checkout/stok 35%, dan UI/UX visual 10%. Bagian-bagian berikut memperluas pemeriksaan. Estimasi terbaru dirangkum pada bagian status eksplorasi yang diperbarui; persentase adalah keluasan kajian, bukan skor validasi atau proporsi kode yang terbaca.

## Pembacaan tambahan: cakupan API dan data

Penelusuran lebih luas menemukan endpoint berikut tertanam dalam klien: autentikasi login/daftar/reset kata sandi, profil `/v1/me`, pengguna `/v1/users`, transaksi `/v1/transactions/`, laporan transaksi/jumlah/pengeluaran/pergerakan stok, kuitansi `/v1/receipts`, unggah/hapus gambar produk, pengaturan bisnis, QRIS, pengaturan printer, event, subscriber, serta upload PowerSync. Ini menegaskan arsitektur klien-server dengan fungsi lokal untuk daftar/kontrol dan API khusus untuk operasi server. Nama endpoint tidak mengungkap aturan validasi server atau payload lengkap.

Data transaksi yang dibentuk klien memiliki bidang `tax`, `discount`, `payment_method`, `is_backdated`, dan `stock_movements`, selain `total`. Terdapat tipe diskon (`discount_type`) dan objek diskon dengan `type` serta `value`. Ini membuktikan model mendukung pajak, diskon bertipe, metode pembayaran, backdate, dan ledger mutasi stok. Helper aritmetika checkout yang ditelusuri mengungkap urutan potongan baris, promosi nominal/persentase, poin dan pajak. Eligibilitas promosi dan pemetaan setiap nilai hitung ke payload final masih terbuka.

Query laporan stok khusus tersedia melalui `/v1/reports/stock-movements?`; query laporan transaksi, jumlah transaksi, dan pengeluaran terpisah. Daftar produk aktif dibaca berdasarkan tenant, prioritas, waktu pembuatan, dan nama. Ada hitungan lokal produk aktif dan pencarian barcode unik per tenant. Ini mendukung gambaran katalog yang memiliki prioritas tampilan dan aturan SKU unik.

### Pemisahan fakta dan inferensi

**Fakta kuat dari bytecode:** aplikasi mengandung jalur PowerSync, API auth/users/transactions/reports/products/settings, query tenant untuk katalog dan pelanggan, field transaksi tersebut di atas, permission capability, serta data pengaturan printer/QRIS. **Inferensi yang masuk akal:** penjualan offline disimpan lokal dan dikirim lewat antrean, laporan tertentu mengambil data server, dan stok dilacak sebagai mutasi. **Belum terbukti:** atomicity checkout, hasil rekonsiliasi konflik, keamanan otorisasi sisi server, kebenaran formula laba pada data aktual, dan layar visual. Karena itu rincian tersebut bukan audit keamanan atau jaminan operasional.

## Model data yang teridentifikasi langsung

Query dan statement tulis menunjukkan entitas lokal berikut:

| Entitas | Bidang yang tampak dalam statement | Implikasi |
|---|---|---|
| products | tenant, nama, harga jual, harga grosir, kategori, stok/minimum, unit, multiplier, gambar, barcode, varian, harga modal/cost, prioritas, audit fields | Mendukung inventaris multi-unit/varian dan pelacakan biaya |
| categories | tenant, nama, visibilitas, ikon, prioritas, audit fields | Kategori bisa disusun dan disembunyikan |
| transactions | items, total, tax, discount, payment method, customer, uang diterima/kembalian, kasir, timestamp/backdate, edit flag, notes, sequence/table | Satu record transaksi menyimpan data struk dan status pembayaran utama |
| stock_movements | product, jenis mutasi, delta, stok sebelum/sesudah, catatan, reference_id, audit fields | Riwayat stok dirancang sebagai ledger, bukan hanya angka stok terakhir |
| customers | kontak/alamat, tipe, total belanja, total pengeluaran, pembelian terakhir, poin loyalitas, catatan | Ada ringkasan pembelian dan loyalty pada model pelanggan |
| expenses | nominal, kategori, deskripsi, tanggal, tipe, audit fields | Pengeluaran dipisah dari transaksi penjualan |
| discounts | tipe, nilai, aktif/nonaktif, tenant, audit fields | Aturan diskon dapat disimpan dan diaktif/nonaktifkan |

### Data pelanggan dan privasi

Record pelanggan mencakup nama, nomor telepon, alamat/kontak, tipe pelanggan, catatan, riwayat ringkasan belanja, dan poin loyalti. Data tersebut digunakan dalam transaksi serta fitur kasbon dan dapat melewati sinkronisasi cloud. Analisis bundle tidak menemukan cukup bukti untuk menyatakan bagaimana data sensitif dienkripsi saat tersimpan atau saat dikirim, berapa lama tombstone soft-delete disimpan, atau apakah pengguna bisa mengekspor/menghapus data secara permanen. Untuk implementasi turunan, akses minimum per peran, logging tanpa nomor HP lengkap, dan kebijakan retensi harus diputuskan secara eksplisit.

Statement insert memakai `created_by`, `updated_by`, `updated_seq`, dan `deleted_at`; update menaikkan `updated_seq`. Ini mendukung sinkronisasi perubahan bertahap dan audit pengguna. Soft delete terlihat pada produk/kategori/transaksi/pelanggan/diskon, meskipun belum semua tabel dicek.

## Alur stok yang lebih terperinci

Penyesuaian stok manual memakai pola baca stok saat ini, lalu memperbarui nilai `stock` dan menambahkan record `stock_movements` yang menyimpan stok sebelum/sesudah, perubahan kuantitas, alasan, dan pelaku. Ada pemeriksaan stok yang menolak pengurangan bila stok tak cukup, dan produk dengan stok tak terbatas tidak bisa disesuaikan lewat jalur tersebut. Penghapusan transaksi memakai pesan konfirmasi tentang pengembalian stok; edit transaksi mengembalikan stok item yang dilepas lalu memvalidasi perubahan. Belum ada bukti kuat bahwa semua langkah ledger dan nilai stok dieksekusi atomik dalam satu transaksi.

## Model pembayaran yang terlihat

Pembayaran memuat uang diterima dan kembalian di samping metode pembayaran. Ada konfigurasi struk untuk menampilkan metode pembayaran, pajak, nomor urut dan nomor meja. QRIS merupakan jenis metode tersendiri dengan gambar dan nama merchant. Kasbon memakai jalur berbeda: pelunasan harus mengganti metode `kasbon` dengan metode non-kasbon. Itu mendukung pencatatan piutang sampai pelunasan, tetapi belum membuktikan pembayaran parsial, cicilan, atau umur piutang.

## UX operasional yang dapat diprediksi dari model

Kasir kemungkinan perlu memasukkan item dengan cepat melalui pencarian/barcode, menyesuaikan kuantitas, memilih pelanggan bila kasbon, memilih metode bayar, memasukkan jumlah tunai bila relevan, lalu menampilkan/mencetak struk. Menu administrasi terpisah menangani produk, kategori, pelanggan, diskon, pengeluaran, pengguna, QRIS, dan printer. Ini rekonstruksi kebutuhan layar berdasarkan data/fungsi; urutan nyata, jumlah tap, dan tata letak masih harus ditinjau dari aset UI atau runtime.

## Batas analisis dan tindak lanjut

Disassembly Hermes berisi 32.116 fungsi termasuk pustaka pihak ketiga; nama dan string tidak selalu membuktikan keterjangkauan fungsi atau implementasi yang sedang aktif. Rekonstruksi yang lebih lengkap memerlukan penelusuran fungsi per fitur, konteks kontrol alur, aset, dan idealnya observasi runtime. Tidak ada klaim bahwa seluruh fitur atau UI sudah terpetakan. APK ini memerlukan split APK untuk dipasang; pemeriksaan runtime tidak dilakukan sesuai permintaan.

## Penelusuran mendalam tambahan: checkout dan interaksi kasir

### Layar kasir dan state yang teridentifikasi

Hook `useCheckout` memegang state untuk cart, total, pajak, pilihan metode pembayaran, uang tunai diterima dan kembalian, pelanggan, diskon aktif/terpilih, pemakaian poin, alur checkout/sukses, printer, transaksi tertahan (hold), daftar draft, serta modal konflik draft. Ada aksi yang terpisah untuk mengubah kuantitas, mengosongkan cart, memilih/menerapkan diskon item, memulai checkout, membersihkan state setelah checkout sukses, serta mengelola hold/draft. Ini memberi bukti alur kasir memiliki lebih banyak cabang dibanding form bayar sederhana.

Komponen kasir mempunyai modal checkout, pelanggan, diskon, sukses, printer, hold, draft, dan konflik draft. Pada pemilihan produk terdapat modal varian dan modal kuantitas. Nama hook serta modal terlihat pada fungsi aplikasi dalam disassembly, bukan hanya pustaka UI. Pola interaksi yang dapat dipastikan: kasir mengumpulkan keranjang, bisa menambah detail pelanggan/diskon, menyelesaikan pembayaran, lalu menangani struk dan kemungkinan printer. Urutan tap serta kepadatan layout visual tidak dapat diverifikasi statis.

### Perhitungan dan batas interpretasi

State checkout memisahkan `grossSubtotal`, jumlah diskon per-item, diskon transaksi, `taxAmount`, `taxRate`, `finalTotal`, nilai poin yang ditukar, total jumlah item, jumlah tunai diterima, dan `change`. Jadi aplikasi memang memodelkan komponen subtotal, diskon, pajak, loyalti, dan kembalian secara eksplisit. Pada generator receipt, detail item dibentuk dari produk, kuantitas, unit, harga, subtotal, catatan, varian, serta instruksi print-to-kitchen. Nilai uang pada struk merujuk hasil kalkulasi checkout.

Penting: jangan menyamakan `grossSubtotal - diskon + pajak` dengan formula aktual. Helper yang ditelusuri menunjukkan pajak berjalan setelah pengurangan poin, sementara diskon baris dan promosi dihitung lebih awal. Pembulatan terjadi pada harga unit konversi, selisih diskon transaksi, dan pajak. Pemetaan semua angka ke storage tetap perlu dihubungkan ke fungsi commit.

### Diskon, loyalti, dan kelayakan kasbon

Checkout menyimpan daftar diskon terpilih dan diskon aktif, menyediakan `toggleDiscount` dan callback penerapan diskon item. Model pelanggan memiliki `loyalty_points`; state checkout menghitung poin tersedia, nilai poin, poin yang diminta, poin efektif, dan jumlah diskon poin. Artinya alur checkout menghubungkan CRM sederhana dengan potongan pembayaran. Detail rasio konversi poin dan batas penukaran belum dipastikan.

Untuk metode kasbon, checkout memvalidasi pelanggan: terdapat pesan eksplisit yang meminta memilih pelanggan atau memasukkan nama pelanggan sebelum mencatat kasbon. Ini menunjukkan aplikasi tidak membolehkan utang tanpa identitas minimal. Sebagian jalur checkout mengisi metode bayar default `cash` bila pilihan kosong. Data uang diterima dan kembalian tersedia dalam state. Belum ada bukti bahwa seluruh metode non-tunai harus memasukkan nilai diterima atau bagaimana kembalian diformat.

### Draft, tahan transaksi, serta konflik

State dan modal yang berbeda untuk transaksi tertahan, daftar draft, dan konflik draft menunjukkan penyimpanan keranjang sementara merupakan fitur tersendiri dari checkout final. Mekanisme tersebut berguna saat kasir melayani beberapa pelanggan atau perlu menunda keranjang. Pesan sinkronisasi menyebut konflik draft dan memerlukan interaksi pengguna. Belum terlihat aturan kapan draft lokal kedaluwarsa, batas jumlah draft, format penyimpanan item, atau strategi merge ketika perangkat lain mengubah draft serupa.

### Stok, variasi, dan masukan produk

State produk memiliki jumlah stok minimum, indikator low-stock/out-of-stock, status stok tak terbatas, varian produk, dan pilihan unit. Jalur edit kuantitas cart adalah fungsi terpisah dan ada `setCartWithStockCheck`, sehingga pengecekan stok dilakukan saat cart berubah, sebelum penjualan disimpan. Scanner barcode serta pengaturan scanner teridentifikasi. Ini membentuk beberapa pintu input produk: daftar/pencarian, barcode, varian, dan kuantitas. Dukungan barcode scan tidak menjamin semua perangkat kamera atau barcode fisik kompatibel; itu memerlukan uji perangkat.

### Struk dan perangkat cetak

Selain printer Bluetooth, bytecode memuat wrapper printer USB dan jaringan. Pengaturan struk mendukung lebar 58 mm, copy pelanggan, pajak, metode bayar, nomor urut, nomor meja, watermark, teks footer, dan jumlah baris feed. Terdapat generator struk teks/plain text, validasi data struk, formatter kuantitas, generator HTML receipt, dan fungsi berbagi receipt melalui WhatsApp yang meminta nomor WhatsApp. Ada juga fungsi cetak struk dapur dengan identitas cart dan daftar item; data item membawa flag `printToKitchen`. Ini memberi dukungan ke struk pelanggan dan tiket dapur, dengan printer USB/BLE/network sebagai jalur perangkat.

Keterbatasan statis: tidak diketahui apakah printer jaringan membutuhkan protokol tertentu, apakah USB OTG didukung di seluruh perangkat, atau bagaimana recovery setelah printer mati di tengah cetak. Keberadaan driver dan tombol sambung belum membuktikan interoperabilitas.

Hook printer menyimpan state `isConnected`, `connectedDevice`, `availableDevices`, `isScanning`, `isConnecting`, dan `isPrinting`. Aksi publiknya mencakup mencari, menyambungkan, memutus, cek koneksi, cetak struk uji, struk transaksi, struk dapur, laporan penjualan, serta refresh status. Ada listener koneksi dan pemeriksaan kesehatan koneksi sebelum cetak; bila putus, pesan mengarahkan pengguna ke Pengaturan > Kelola Printer. Pencarian Bluetooth tanpa hasil memberi arahan agar printer dinyalakan dalam mode pairing, sedangkan kegagalan scan/connect/disconnect menampilkan pesan terpisah. Ini menunjukkan UX printer punya state mesin yang cukup eksplisit, tetapi bukan bukti bahwa aplikasi otomatis retry atau mencetak ulang tanpa duplikasi.

## Peta kemampuan operasional yang lebih rinci

| Tahap kerja | Bukti implementasi | Batas yang belum terjawab |
|---|---|---|
| Membuka sesi kasir | state checkout, produk live, modal varian/kuantitas | login awal, pemilihan toko, dan onboarding belum diamati |
| Memasukkan item | barcode scanner, pencarian produk, varian, unit, kuantitas | debounce pencarian, kegagalan scan, dan aksesibilitas belum diuji |
| Mengelola keranjang | update quantity, clear cart, setCartWithStockCheck, draft/hold | validasi persaingan stok multi-device belum diketahui |
| Menentukan harga | subtotal baris, diskon nominal/persentase, poin, pajak dan total | eligibilitas promo dan pemetaan setiap angka ke payload commit |
| Pembayaran | metode bayar, kas, uang diterima, kembalian, kasbon | partial payment, refund dan split tender belum dibuktikan |
| Penyelesaian | success modal, cleanup, nomor urut, catatan, pelanggan | idempotensi saat tombol ditekan ulang belum ditelusuri |
| Bukti transaksi | receipt formatter/HTML/teks, WhatsApp, printer | perilaku ketika cetak/share gagal belum diverifikasi |
| Operasi dapur | flag print-to-kitchen dan generator kitchen receipt | routing item/menu station belum terlihat |

## Risiko produk yang paling relevan untuk implementasi tiruan

1. **Keakuratan keuangan.** Sebagian rumus subtotal/potongan/pajak sudah direkonstruksi. Perlu uji angka pembanding dan pemetaan nilai ke storage sebelum hasilnya ditiru.
2. **Satu transaksi, satu konsekuensi stok.** Pastikan checkout atomik atau idempoten. Retry setelah jeda jaringan tidak boleh menghasilkan transaksi ganda atau stok ganda.
3. **Offline tidak berarti selalu konsisten.** Konflik upload, record terhapus di server, dan perbedaan data lokal/server dapat mengubah hasil laporan. Sinkronisasi perlu status yang mudah dipahami kasir.
4. **Izin lintas peran.** UI menyembunyikan/menonaktifkan fungsi menurut capability, tetapi server perlu mengulangi pemeriksaan authorization.
5. **Pencetakan adalah jalur eksternal.** Cetak sebaiknya tidak menentukan keberhasilan transaksi; bila cetak gagal, transaksi tetap bisa ditemukan dan dicetak ulang.
6. **Draft dan kasbon memerlukan keterlacakan.** Draft konflik butuh keputusan pengguna yang jelas; kasbon harus memiliki identitas pelanggan dan jalur pelunasan yang dapat diaudit.

## Status eksplorasi yang diperbarui

Analisis statis kini mengidentifikasi dengan keyakinan tinggi subsistem utama penjualan, stok, produk, pelanggan/loyalti, diskon, kasbon, hold/draft, pengeluaran, laporan, pengaturan, printer dan sinkronisasi. Cakupan fitur teridentifikasi diperkirakan 80%; mekanisme bisnis checkout 55%; data/penyimpanan dan sinkronisasi 50%; UI/UX struktur interaksi 45%, visual 10%. Angka ini menilai keluasan penelusuran, bukan persentase kode yang dibaca atau hasil QA. Area yang tetap perlu eksplorasi penting: urutan tepat semua jenis diskon terhadap pajak/poin, jalur refund/void, field lengkap dan versi schema item JSON, enforcement otorisasi backend, strategi edit/rollback/idempotensi, rekonsiliasi stok lintas perangkat, skema draft dan resolusi konflik, serta semua layar visual/accessibility. Tidak dilakukan instalasi maupun emulator atas arahan pengguna.

## Penelusuran lanjutan: urutan penyimpanan dan langganan

### Urutan simpan transaksi dan mutasi stok

Fungsi `writeTransaction` memanggil pembaruan ringkasan pelanggan (jumlah pembelian, total belanja, poin, waktu pembelian terakhir), kemudian melakukan loop item untuk membaca stok produk berdasarkan ID dan tenant, memperbarui stok, serta menulis movement bertipe `sale`; setelah itu statement insert transaksi menyimpan total/pajak/diskon/pembayaran dan snapshot pelanggan/kasir/waktu. Pemeriksaan kode yang ditelusuri tidak menunjukkan `BEGIN` / `COMMIT` di sekitar rangkaian fungsi ini. Dukungan transaction API pada storage tetap ada di bagian lain, tetapi tidak boleh dianggap sebagai bukti checkout menggunakan atomic transaction. Ini temuan risiko yang layak diuji: bila satu query setelah perubahan customer/stok gagal, perlu diketahui mekanisme kompensasi atau rollback yang memastikan saldo, stok, ledger, dan transaksi tetap konsisten.

Jalur edit memeriksa apakah transaksi lama yang dipilih termasuk transaksi yang telah dihapus/superseded, mencoba membuang sumber lama, dan dapat membatalkan proses ketika ID sumber remote tidak tersedia. Pesan kegagalan menunjukkan kehati-hatian pada edit, tetapi karena operasi hapus lama dan insert baru dapat terpisah, uji crash/interupsi saat edit diperlukan sebelum menyimpulkan data aman.

Penjualan menulis pergerakan stok dengan `quantity_change` negatif (`quantity` dinegasikan), serta `stock_before` dan `stock_after`; kode pembaca riwayat mengaitkan `reference_id` movement dengan transaksi untuk menampilkan nama kasir. Ada pemeriksaan stok kurang dan kategori peringatan low stock. Satu hal penting untuk replika Fostifest: menjadikan angka stok terkini dan tabel ledger selalu sinkron, termasuk saat edit/void dan saat sinkronisasi lintas perangkat.

### Batas gratis dan konflik bukti versi

Hook checkout mengekspos `dailyTransactionLimit = 30`; paywall juga memuat paket Free berupa `30 produk`, `30 transaksi/hari`, `1 kasir`. Namun changelog di bundle memuat kalimat peningkatan batas paket Free menjadi 50 transaksi per hari. Karena dua sumber teks/fungsi dalam bundle berbeda, angka kuota aktual belum bisa dipastikan hanya dari string. Bisa jadi catatan rilis dan kode berasal dari fase versi yang tidak sama, atau server mengubah kuota. Jadi angka yang dapat dicatat adalah: UI/hook checkout menyatakan 30, changelog menyatakan 50, implementasi server/quota aktual belum diketahui. Ini konflik produk yang perlu validasi terhadap versi live.

### Penghasilan, margin, dan kualitas data biaya

Model produk menyimpan `cost` dan `track_cost`, sementara laporan menandai produk tanpa cost dan menampilkan modal terjual serta total pengeluaran. Ada teks laporan yang menjelaskan penjualan dikurangi modal barang terjual dan pengeluaran. Ini menunjukkan konsep laba bersih/estimasi margin memasukkan harga pokok produk dan biaya operasional. Produk tanpa modal memunculkan peringatan, sehingga laba dapat kurang akurat apabila cost kosong atau tidak diperbarui. Nama nilai modal pada laporan merupakan petunjuk cara hitung, namun formula lengkap, perlakuan retur, diskon, pajak, dan perubahan cost historis belum terverifikasi.

### Detail metadata akses dan tenant

Fungsi operasi lokal memperoleh `tenant_id` / scope ID dan ID user/role dari state auth. Query produk, stok, transaksi, dan pelanggan yang ditemukan memfilter `tenant_id`; data audit menyimpan pembuat/pengubah dan `updated_seq`. Pada sisi transaksi, data ditulis lokal melalui PowerSync dan dapat ditandai `sync_recent_mobile`. Ini merupakan kontrol isolasi yang terlihat di klien. Isolasi tenant tetap harus diverifikasi di aturan PowerSync dan API karena query klien tidak menggantikan otorisasi server.

### Kualitas bukti

Temuan di bagian ini diambil dari fungsi aplikasi bernama `writeTransaction`, `processTransaction`, `useCheckout`, `CheckoutScreen`, `restoreTransactionStock`, query SQL, dan konstanta UI dalam Hermes disassembly. Ketika laporan sebelumnya menyebut “kemungkinan” atau “belum diketahui”, itu tetap sengaja dipertahankan: disassembly memberi urutan instruksi dan struktur data, tetapi tidak memberi pengamatan hasil transaksi nyata. Fitur pihak ketiga yang ikut terdisassemble dikecualikan dari hitungan cakupan aplikasi sejauh nama/konteksnya tampak library.

## Penelusuran laporan, staf, dan biaya

Controller laporan menghubungkan hak akses pengguna, kasir aktif, transaksi/laporan, pengeluaran, dan sinkronisasi cloud. Filter memiliki periode (termasuk `today`), tipe data (`all`), metode pembayaran, dan staf; label pilihan staf mencakup `Semua User`. Laporan menyediakan akses terpisah untuk melihat laporan dan riwayat transaksi, serta memeriksa `canViewReports`, `canViewTransactionHistory`, `canAddExpenses`, dan akses penyaringan staf. Ini berarti pembatasan report bukan sekadar tab tampilan: controller menerima kemampuan/role dan menggunakannya saat menyediakan aksi.

Expense management mencakup form tambah/edit, tanggal, nominal, kategori, deskripsi, hapus, dan reset filter/form. Controller punya `addExpense`, `updateExpense`, `deleteExpense`, state loading, pencarian/filter, `isFilterActive`, `resetFilters`, label periode/filter/pembayaran/staf, serta tombol `syncNow` dengan status `isSyncing`. Jadi laporan menggabungkan pemantauan penjualan dan arus biaya dengan penyegaran sync manual. Bukti ini belum menjawab apakah expense dikategorikan wajib, apakah export CSV/PDF tersedia, atau bagaimana error API dilaporkan ke pengguna.

Model dashboard/report memiliki `totalExpenses`, `netProfit`, nilai modal seluruh item terjual, serta peringatan modal produk belum diisi. Penjelasan yang tertanam menyatakan laba = total penjualan dikurangi modal item terjual dan pengeluaran. Itu rumus konseptual yang dinyatakan UI; belum ada pengujian angka sehingga belum dapat menjamin basis penjualan setelah diskon, retur, atau pajak.

### Hak akses yang tampak pada profil staf

Kode memiliki satu capability profile terbatas dan satu profile penuh. Profile terbatas boleh mengelola produk/kategori/diskon, mengedit transaksi, melihat laporan/riwayat, dan menambah pengeluaran; ia tidak boleh mengelola kasir, pelanggan, menghapus transaksi, atau mengelola QRIS. Profile penuh mengaktifkan semua 11 kapabilitas yang terlihat. Tidak semua profil harus persis dua tipe ini, karena ada normalisasi capability dari object user; namun dua konfigurasi default itu tertanam eksplisit.

Untuk meniru di Fostifest, sebaiknya jadikan role sebagai daftar capability yang jelas, bukan mengandalkan label peran semata. Operasi edit/hapus transaksi dan manajemen QRIS harus dites per API, karena UI capability tidak menunjukkan enforcement server.

## Temuan UI visual dari style/komponen tertanam

Walau tanpa emulator, sebagian warna dan pola elemen tampil tertanam langsung di bundle. Dalam bagian aplikasi terdapat aksen biru tua `#3958A3`, beberapa aksen biru (`#3B82F6`, `#2563EB`, `#4F46E5`), hijau (`#16A34A`, `#22C55E`, `#10B981`, `#4ADE80`), merah untuk aksi berbahaya, amber/kuning untuk peringatan, serta abu-abu untuk teks sekunder dan placeholder. Ini mengindikasikan palet aksen tidak sepenuhnya seragam. Warna latar yang tertanam meliputi putih dan abu-abu terang. Angka kemunculan warna hanya hitungan string dalam cakupan bundle, bukan proporsi pixel atau dominasi layar.

Komponen eksplisit mencakup ProductCard, ProductListItem, ProductListItemPOS, ProductModal, CategoryModal, ScannerModal, DateTimePickerModal, skeleton katalog/laporan/riwayat stok, ReportCard, dan modal printer. Pola umum yang didukung kode: grid/daftar produk POS, daftar admin, form/modal CRUD, indikator status stok, skeleton saat memuat, placeholder ikon/teks, dan dialog konfirmasi. Skeleton memperlihatkan desain memikirkan keadaan loading. Tidak dapat dinilai apakah skeleton berakhir dengan empty state yang jelas, apakah teks kontras cukup, atau kontrol sentuh berukuran nyaman.

Tampilan POS kemungkinan memprioritaskan katalog dan cart, sedangkan administrasi mengelompokkan data produk/kategori/stok dan laporan. Ini kesimpulan struktur komponen; penilaian visual rinci seperti posisi cart, jumlah kolom grid, navigasi bottom tab, typographic scale, dan responsivitas belum dapat dilakukan tanpa screenshot atau layout runtime. Kode juga memuat `OfflineBanner`, sehingga status offline punya affordance visual khusus.

## Changelog internal dan dukungan peran: temuan tambahan

Bundle berisi catatan rilis berbahasa Indonesia yang menyebut transaksi backdate maksimal tujuh hari dan tanggal/jam tidak boleh melewati waktu saat ini. UI checkout mempunyai state izin `canBackdateTransactions` dan tanggal transaksi. Ini memperjelas bahwa backdate adalah kemampuan terbatas oleh entitlement/role, bukan tanggal bebas. Counter transaksi harian mengecualikan transaksi backdate, jadi pemilik tidak menghabiskan kuota transaksi hari ini dengan pencatatan historis.

Catatan rilis juga mencantumkan tahan/update draft, cetak pesanan dari keranjang, dan catatan per item yang masuk ke struk. Itu melengkapi temuan draft/hold sebelumnya. Kemampuan khusus peran: tab laporan disembunyikan bagi kasir/admin tanpa izin lihat laporan; izin `Kelola QRIS` menentukan apakah kasir/admin dapat mengubah QRIS. Ringkasan modal dan keuntungan (total modal, modal terjual, laba bersih, serta angka per item) disebut hanya dapat dilihat Owner. Ini memperjelas bahwa aturan laporan lebih granular daripada `canViewReports` saja: ada data profit sensitif dengan akses owner-only.

Menu `Kelola Kasbon` dikelompokkan di Pengaturan > Kelola > Kelola Piutang menurut changelog, menampilkan daftar kasbon belum lunas per pelanggan, total piutang, dan detail barang. Layar filter memiliki periode kasbon; ada tindakan pelunasan satu kasbon maupun seluruh kasbon pelanggan. Konteks tersebut mendukung pemantauan aging/utang per pelanggan, tetapi belum ditemukan klasifikasi umur piutang, pencatatan cicilan, atau laporan pembayaran parsial.

### Pembelian paket dan fitur berbayar

Layar `ProSubscription` dan pustaka pembelian dalam aplikasi tertanam. Logika paket memakai subscription options dan entitlements; ada `ProSubscription` route, alur purchase/restore dari layanan native, serta konstanta batas Free 30 produk, 30 transaksi/hari, dan 1 kasir. Catatan rilis yang menaikkan kuota menjadi 50 menimbulkan konflik versi internal yang sudah dicatat di atas. Tidak dapat dipastikan paket dan harga yang sedang live, karena offering produk dapat berasal dari konfigurasi toko aplikasi/server dan bukan hanya nilai statis bundle.

Fitur Pro yang tepat belum sepenuhnya dipetakan. Teks UI mengindikasikan batas katalog/transaksi/staf dan kemampuan manajemen, tetapi tidak cukup untuk menyusun daftar benefit premium lengkap atau harga. Sistem pembelian memberi kemungkinan paywall native; pembelian gagal/di-cancel dan restore purchase merupakan cabang yang perlu diuji pada perangkat nyata.

### Aritmetika cart dan loyalti yang dapat direkonstruksi

Penelusuran fungsi `calculateSubtotal` membuktikan harga item dikalikan kuantitas; untuk unit dengan multiplier lebih dari 1, nilai subtotal dihitung dari harga × kuantitas ÷ multiplier dan dibulatkan dengan `Math.round`. Unit tanpa multiplier lebih dari 1 memakai harga × kuantitas. Konversi kuantitas ke unit dasar mengalikan dengan multiplier dan membulatkan; konversi tampilan membagi kuantitas dasar dengan multiplier bila multiplier > 1, sedangkan unit multiplier 1 atau kurang memakai truncation. `discountTotal` item dijumlahkan, lalu subtotal item dijaga agar tidak negatif (`max(0, subtotal - discountTotal)`). Cart total merupakan penjumlahan subtotal item; jumlah item cart mengakumulasi kuantitas.

Poin loyalti dihitung dengan rumus yang tertanam: `floor((amount / max(1, loyaltyBaseAmount)) * loyaltyPointsPerBase)`. Config default bisnis adalah IDR, basis `Rp10.000` untuk satu poin, dan nilai satu poin `Rp100`; tersedia parameter konfigurasi terpisah untuk customer tipe VIP dan wholesale. Karena `customerType` memilih basis/perolehan poin yang berbeda, dua tipe tersebut dapat mendapat rasio reward khusus. Penukaran poin dibatasi jumlah poin tersedia dan nilai pembelian sebelum pajak; diskon poin berupa poin efektif × nilai poin, dasar pajak menjadi `max(0, total sebelum poin - diskon poin)`, pajak dihitung `round(dasar pajak × taxRate / 100)`, lalu total akhir adalah dasar pajak + pajak. Formula helper dan nilai default terlihat di bundle; batas minimal transaksi, perubahan konfigurasi tenant, dan perilaku aktual server masih perlu diverifikasi.

### Algoritme diskon checkout (hasil penelusuran lanjutan)

Fungsi helper untuk diskon transaksi memisahkan pilihan bertipe `amount` dan `percentage`. Diskon nominal menjumlahkan `max(0, value)` per pilihan dan membatasi total potongan nominal agar tidak melewati subtotal kotor. Sisa basis setelah potongan nominal menjadi masukan diskon persentase. Persentase diproses berurutan: tiap nilai dijepit ke rentang 0–100%, lalu sisa dikalikan `(1 - persentase/100)`. Jadi dua diskon 10% dan 20% menghasilkan pengurangan gabungan 28% atas basis yang sama, bukan 30%; urutannya tidak mengubah hasil jika hanya operasi persentase, tetapi potongan nominal mengubah basis persentasenya. Selisih akhir dibulatkan dengan `Math.round` dan total diskon dijepit ke 0..subtotal kotor.

Rangkaian nilai yang tampak adalah: subtotal item setelah diskon baris → pengurangan diskon transaksi nominal dan persentase → batas diskon poin menurut poin tersedia dan nilai transaksi → basis pajak setelah poin → pembulatan pajak → jumlah akhir. Diskon produk/baris sudah tertanam dalam subtotal item sehingga tidak boleh dikurangkan dua kali. Penggunaan `Math.round` di harga satuan unit konversi, selisih diskon promosi dan pajak dapat menciptakan selisih pembulatan satu rupiah pada keranjang multi-item; replika harus konsisten memilih pembulatan di tingkat baris atau tingkat transaksi. Detail validitas diskon (tanggal berlaku, minimum pembelian, tumpukan antar-diskon dan batas server) masih belum terbukti.

Temuan ini memperjelas urutan matematika lebih jauh daripada pembacaan awal. Namun total yang disimpan tetap memerlukan penelusuran jalur commit sampai statement transaksi agar seluruh field (gross, discount, tax, net, change, point redemption) dapat dipetakan tanpa asumsi.

## Struktur item transaksi dan stok saat edit/hapus

Statement penjualan memanggil `JSON.stringify(items)` sebelum menyimpan kolom `transactions.items`. Pada jejak SQL yang diperiksa tidak ditemukan insert tabel detail terpisah bernama transaction_items. Bukti ini mendukung penyimpanan daftar barang sebagai snapshot JSON dalam satu kolom transaksi, sementara pergerakan stok tetap di tabel ledger sendiri. Kolom transaksi yang tampak berisi `customer_name` dan `customer_phone`, tetapi tidak menunjukkan `customer_id`; helper terpisah memperbarui ringkasan pelanggan lewat ID. Karena itu keterkaitan permanen transaksi ke record pelanggan belum dapat dipastikan dari insert ini saja. Konsekuensi desain yang mungkin: struk/history dapat mempertahankan snapshot nama/harga/item saat transaksi dibuat, tetapi analitik SQL per item memerlukan parsing JSON atau materialisasi khusus. Belum terbukti apakah ada view/schema server yang menormalisasi item.

Snapshot `items` di proses tulis meliputi data cart yang kemudian diserialisasi. Receipt mapping menyusun name, quantity, unit, price, subtotal, notes, selectedVariants, dan printToKitchen; ini membuat item kaya konteks. Nama kategori, harga modal, varian yang dipilih, dan nilai diskon bisa ikut di snapshot jika ada pada object cart, tetapi kontrak field final seluruh item belum terpetakan.

Helper restore stok membaca `stock` terkini untuk produk aktif dalam tenant, memvalidasi nilainya numerik/finite, menambah kuantitas yang dikembalikan, memperbarui stok, lalu menambah movement bertipe `restore` dengan `reference_id`. Bila produk hilang/soft-deleted atau item transaksi invalid, terdapat pesan yang menyatakan pemulihan stok dilewati. Jadi penghapusan transaksi tidak otomatis mengembalikan stok untuk item yang sudah tidak dapat ditemukan. Ini perlu diperhitungkan ketika meniru retensi catalog atau kebijakan hapus produk: histori transaksi tetap perlu dapat dipahami walau produk master sudah tidak aktif.

### Pengaruh desain pada analitik dan audit

- JSON snapshot mempermudah histori struk tetap menampilkan detail yang dibeli pada saat itu.
- Query ringkasan penjualan per item mungkin perlu JSON extraction; biaya query dan kompatibilitas PowerSync SQLite/remote DB perlu ditinjau.
- Ledger gerak stok menyimpan kuantitas sebelum/sesudah dan referensi transaksi, sehingga rekonsiliasi dapat dilakukan jika snapshot transaksi masih dapat dibaca.
- Bila item JSON korup atau field lama tidak memiliki bentuk terbaru, laporan per item perlu fallback. Tidak ditemukan matriks migrasi format JSON pada pembacaan ini.
