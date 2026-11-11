# Laporan Identifikasi Masalah Performa (Performance Findings)

* **Proyek**: Campus Notify (`campus_notify`)
* **Minggu Pembelajaran**: Week 11 — Performance Optimization
* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Perangkat Pengujian**: Android Fisik (`arm64 (64 bit) android` — Xiaomi 2201117TY)
* **Rendering Engine**: Impeller
* **Mode Profiling**: Profile Mode (`flutter run -d 2201117TY --profile`)

---

## 1. Ringkasan Eksekutif Baseline

Berdasarkan hasil pengujian baseline profiling pada Flutter DevTools (rekaman tab **Performance** tersimpan di `screenshots/before-profile.png`), teridentifikasi beberapa *bottleneck* performa yang menyebabkan terjadinya **Jank (slow frame)**:

```text
Target Frame Budget: 16,67 ms (60 FPS)
Lonjakan Frame Jank Terdeteksi: > 27 ms – 32 ms (melebihi batas anggaran frame hingga 92%)
Thread Terdampak: UI Thread (Dart build/layout) & Raster Thread (GPU compositing)
```

---

## 2. Rincian Temuan Masalah

### Temuan 1: Widget Rebuild Berlebih dan Ketiadaan Repaint Boundary (CPU & GPU)
* **Gejala Profiling**:
  * Muncul bar merah pekat (*Jank slow frame*) berdurasi > 27 ms pada frame awal (frame 242) saat inisialisasi dan interaksi daftar widget.
  * Frame Time UI Thread (Dart) dan Raster Thread (GPU) sama-sama melonjak tinggi.
* **Akar Masalah Teknis**:
  1. **Monolithic Build**: Pada `home_page.dart`, seluruh layar dibangun di dalam satu fungsi `build()` besar tanpa ekstraksi widget menjadi kelas mandiri (`StatelessWidget`).
  2. **Unscoped Riverpod Watch**: Pemanggilan `ref.watch(fcmTokenProvider)` di level teratas `HomePage` menyebabkan seluruh struktur pohon widget di-rebuild ulang setiap kali token FCM berubah atau diperbarui.
  3. **Ketiadaan RepaintBoundary**: Item daftar pada `announcement_page.dart` dan pesan pada `chat_screen.dart` belum dibungkus dengan `RepaintBoundary`. Akibatnya, setiap kali terjadi scroll atau pembaruan teks, GPU engine melakukan pengecatan ulang (*repaint*) ke seluruh kanvas layar.
  4. **Anonymous Closures**: Callback tombol seperti logout didefinisikan dengan fungsi anonim di dalam `build()`, menciptakan alokasi objek closure baru pada setiap render.

---

### Temuan 2: Potensi Beban Memori & Raster Thread pada Penanganan Gambar
* **Gejala Profiling**:
  * Peningkatan konsumsi memori dan tekanan pada Raster Thread saat pengguna melampirkan foto dokumen/KTM untuk fitur OCR di `chat_screen.dart`.
* **Akar Masalah Teknis**:
  1. **Ketiadaan Pembatasan Resolusi Memori**: Widget penampil gambar merender foto dengan ukuran dimensi piksel penuh dari kamera/file tanpa membatasi ukuran decoding memori (`cacheWidth` / `cacheHeight` atau `memCacheWidth` / `memCacheHeight`).
  2. **Ketiadaan Caching Gambar Terstruktur**: Jika gambar jaringan dimuat, aplikasi belum memanfaatkan caching terkelola (disk cache & memory cache terkompresi), berisiko mendownload ulang aset dan memicu alokasi heap berlebih.

---

### Temuan 3: Permintaan Jaringan Berulang Tanpa Strategi Caching (Network & I/O)
* **Gejala Profiling**:
  * Setiap kali pengguna membuka halaman pengumuman atau melakukan navigasi bolak-balik, aplikasi selalu melakukan request HTTP jaringan baru ke backend/mock API.
  * Terdapat jeda visual (*loading spinner*) yang menurunkan responsivitas antarmuka pengguna.
* **Akar Masalah Teknis**:
  1. **Ketiadaan Caching Repository**: `AnnouncementsRepository` belum menerapkan pola **Stale-While-Revalidate (SWR)**, sehingga data lokal tidak langsung disajikan saat jaringan lambat atau saat data belum berubah.
  2. **Ketiadaan Interceptor Retry Otomatis**: Klien HTTP belum dilengkapi retry interceptor yang tahan terhadap *transient network error*, menyebabkan kegagalan langsung saat koneksi seluler tidak stabil.

---

### Temuan 4: Daftar Pengumuman Tanpa Mekanisme Pagination (Infinite Scroll)
* **Gejala Profiling**:
  * Seluruh dataset pengumuman dimuat sekaligus ke dalam memori.
  * Saat data bertambah banyak, waktu layout awal akan membengkak dan membebani UI Thread.
* **Akar Masalah Teknis**:
  * Belum ada pemisahan data per halaman (*pagination*) dan deteksi posisi scroll (`ScrollController`) untuk memuat data secara bertahap saat pengguna mendekati akhir daftar (*lazy loading*).

---

## 3. Rencana Tindakan Optimasi (Langkah 3)

Berdasarkan temuan di atas, tindakan optimasi yang akan diterapkan meliputi:
1. **Optimasi Rebuild**: Ekstraksi widget mandiri, penambahan `const constructor`, isolasi state dengan Riverpod `select`, dan pembungkusan layer menggunakan `RepaintBoundary`.
2. **Optimasi List & Gambar**: Penerapan pagination *infinite scroll* dengan `ScrollController` serta pembatasan memori gambar dengan `memCacheWidth/Height`.
3. **Optimasi Jaringan**: Penerapan pola caching *Stale-While-Revalidate* pada repository pengumuman dan interceptor jaringan.
