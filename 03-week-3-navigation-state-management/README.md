# 02 Week 2 - Declarative UI & Responsive Design
pada pertemuan kali ini saya akan mempelajari tentang konsep navigasi,route dan perbedaan navigator1 dengan gorouter, kemudian menerapkan navigasi multi page dengan GoRouter, termasuk passing argument dan deeplink sederhana, selain itu disini akan dijelaskan cara kerja Riverpod (Provider, ConsumerWidget, Notifier), dan  AsyncValue untuk menangani state loading, error, dan success pada UI

# Konsep navigasi dan GoRouter

## Navigation dasar di Flutter
Navigasi adalah mekanisme berpindah antar layar. Di Flutter, setiap layar adalah route yang ditumpuk pada Navigator (stack). Cara lama (Navigator 1.0) menggunakan Navigator.push dan Navigator.pop:

| Konsep | Penjelasan |
|---|---|
| `GoRoute` | Definisi path dan widget tujuan, misalnya `/` atau `/detail/:id`. |
| `context.go()` | Pindah route dengan mengganti stack, cocok untuk redirect login. |
| `context.push()` | Menumpuk route baru di atas stack, cocok untuk halaman detail. |
| Path parameter | Nilai dinamis pada path, diakses melalui `state.pathParameters`. |
| `extra` | Mengirim objek antar-route; gunakan dengan hati-hati karena tidak tersimpan saat proses restart web. |
| `redirect` | Guard navigasi terpusat, misalnya untuk memeriksa status login. |

### Praktikum 1 — Aplikasi multi-page dengan GoRouter

Jalankan dan amati. Buka item, lalu tekan tombol back sistem. Perhatikan bahwa path berubah mengikuti layar aktif, path yang sama juga dapat diakses langsung tanpa melewati Home. Inilah keunggulan router deklaratif dibanding Navigator 1.0.

#### Hasil pengamatan

![Halaman Home menampilkan daftar item](screenshots/Gorouter1.png)

Gambar 1. Halaman Home menampilkan daftar item. Saat `Item 1` dipilih, aplikasi menavigasi dari path `/` ke path `/detail/1` menggunakan parameter `id`.

![Halaman Detail 1](screenshots/Gorouter2.png)

Gambar 2. Halaman Detail menampilkan item yang dipilih dengan ID `1`. Tombol back sistem mengembalikan pengguna ke halaman Home dan path kembali ke `/`. Halaman ini juga dapat dibuka langsung melalui `/detail/1`, tanpa harus melewati Home, karena route telah didefinisikan oleh GoRouter.


## State management dengan Riverpod

### Mengapa perlu state management?

`setState` cukup untuk state lokal, tetapi state yang dibagikan antarhalaman dapat menyebabkan *prop drilling* dan kode yang rumit. State management memisahkan state dari widget agar:

- UI dibangun konsisten dari state yang sama;
- logika mudah diuji tanpa membangun UI;
- state tetap tersedia meskipun widget tidak sedang tampil.

Pada materi ini digunakan Riverpod karena compile-safe, tidak bergantung pada `BuildContext`, dan mudah diuji.


Konsep inti Riverpod

| Konsep | Penjelasan |
|---|---|
| `ProviderScope` | Wadah global yang menyimpan semua provider, membungkus root aplikasi. |
| `Provider` | Nilai read-only/immutable (misal konfigurasi, service). |
| `Notifier` + `NotifierProvider` | State yang bisa berubah melalui method; UI memanggil method, bukan mengubah state langsung. |
| `ConsumerWidget` | Widget yang bisa membaca provider lewat `ref`. |
| `ref.watch` vs `ref.read` | `watch`: build ulang saat state berubah (di dalam `build`). `read`: sekali baca (di callback/event). |

### Praktikum 2 — Aplikasi ToDo dengan Riverpod

Hasil


## AsyncValue: loading, error, success
Banyak state berasal dari proses asinkron (membaca database, memanggil API). UI harus menampilkan tiga kemungkinan: loading (proses berjalan), error (gagal), dan success (data siap). Mengelola tiga flag boolean secara manual rawan kesalahan (isLoading dan hasError bisa tidak konsisten).

### AsyncValue
Riverpod menyediakan AsyncValue<T> yang memodelkan ketiga kondisi tersebut dalam satu tipe

### Praktikum 3 — Uji ketiga state


1. Salin kode di atas ke project ToDo Anda (atau project terpisah) dan jalankan. Amati tampilan loading selama 2 detik pertama.
2. Ubah build() sementara untuk melempar error: throw Exception('Gagal terhubung ke server');. Jalankan dan amati UI error beserta tombol Coba lagi.
3. Tekan tombol Coba lagi, ref.invalidate membuat provider dijalankan ulang. Pulihkan kode, pastikan state success tampil.
4. Refleksikan: mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?

Hasil     
1. 
2. 
3. 
4. 





## AI Challenge
### AI Prompt Challenge


Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.


Hasil 



### AI Verification Checklist
1 Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?
2 Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?
3 Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?
4 Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?
5 Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau 6 6 6 Consumer bertingkat yang tidak perlu)? Perbaiki ke pola Notifier/ConsumerWidget.
7 Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?


## Refactoring dan testing

### Refactoring Challenge

1. Pisahkan widget bar ToDo menjadi TodoTile tersendiri agar build lebih pendek dan mudah diuji.
2. Ekstrak logika filter (misal tampilkan hanya yang belum selesai) menjadi Provider turunan yang membaca todoListProvider.
3. Integrasikan aplikasi ToDo dengan GoRouter: / untuk daftar dan /stats untuk halaman statistik, tambahkan NavigationBar untuk berpindah.

### Testing
- flutter analyze
- flutter test


# Tugas, refleksi, dan referensi

Mini project / Industry Challenge
Bangun aplikasi ToDo dengan navigasi dan Riverpod sebagai tugas minggu ini:

1. Minimal 2 halaman dengan GoRouter: daftar tugas, halaman detail/statistik.
2. State dikelola Riverpod (Notifier), UI menggunakan ConsumerWidget.
3. Tambahkan fitur simulasi asinkron dengan AsyncValue: state loading, error, dan success tampil dengan benar.
4. Sertakan minimal 1 unit/widget test yang lulus.
5. Kerjakan bagian AI Challenge dan dokumentasikan prompt, hasil AI, perbaikan, serta alasan keputusan teknis Anda.
6. Push ke repository portfolio pada folder 03-week-3-navigation-state-management/ dengan struktur lib/, test/, README.md, dan screenshots/. README menjelaskan tujuan, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.

## Refleksi

1. Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?
jawab :

2. Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?
jawab : 

3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?
jawab :

4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
jawab :