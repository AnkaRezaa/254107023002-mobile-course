# 11-week-11-performance-optimization

Modul pembelajaran Minggu ke-11 ini berfokus pada **Performance Optimization** pada aplikasi mobile Flutter. Modul ini membahas cara mengidentifikasi bottleneck performa menggunakan Flutter DevTools (CPU & Memory Profiling), mengurangi widget rebuild yang tidak perlu, menerapkan lazy loading & pagination, optimasi gambar, serta strategi caching jaringan.

* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Program Studi**: D-IV Teknik Informatika
* **Jurusan**: Teknologi Informasi — Politeknik Negeri Malang

---

## 1. Konsep Optimasi Performa Flutter

### Mengapa Optimasi Performa Penting?
Aplikasi mobile modern harus responsif, hemat daya baterai, dan berjalan lancar (*smooth*) pada berbagai spesifikasi perangkat (termasuk *low-end devices*). Performa yang buruk dapat menyebabkan:
1. **Frame Drop (Jank)**: UI tersendat dan tidak mencapai target 60 FPS (16,67 ms/frame) atau 120 FPS (8,33 ms/frame).
2. **Konsumsi Memori Tinggi**: Potensi *memory leak* dan penumpukan alokasi memori yang menyebabkan aplikasi dihentikan paksa (*Out of Memory* / OOM kill) oleh OS.
3. **Baterai Cepat Habis**: CPU dan GPU bekerja berlebihan akibat komputasi atau re-rendering berulang yang tidak efisien.
4. **Penurunan Pengalaman Pengguna (UX)**: Rating rendah dan tingkat uninstall tinggi.

### Pipeline Rendering Flutter & Frame Budget
```text
UI Thread (Dart)               Raster Thread (GPU)
+--------------------+         +--------------------+
|  Build Widget      |         |                    |
|  Layout            | ------> |  Composite         |
|  Paint             |         |  Rasterize         |
+--------------------+         +--------------------+
         |                                |
         v                                v
    Frame Budget: 16,67 ms (60 FPS) / 8,33 ms (120 FPS)
```
* **UI Thread**: Menjalankan kode Dart, membangun widget tree (*build*), menghitung ukuran & posisi (*layout*), serta mencatat perintah visual (*paint*). Harus selesai dalam < 16,67 ms.
* **Raster Thread**: Mengubah instruksi visual menjadi piksel pada GPU (*rasterize* & *composite*). Menjadi bottleneck jika aset gambar berukuran raksasa atau efek visual berlebihan.
* **Jank**: Terjadi ketika salah satu thread memakan waktu melebihi anggaran frame, menyebabkan frame di-*drop*.

### Kategori Optimasi Utama
| Kategori | Fokus Masalah | Tools Analisis | Solusi Utama |
|---|---|---|---|
| **CPU / Build** | Widget rebuild berlebih, layout berulang | DevTools Performance, Flame Chart | `const` constructor, ekstrak widget, Riverpod `select`, `RepaintBoundary` |
| **Memori** | Memory leak, penumpukan objek gambar besar | DevTools Memory, Heap Snapshot | Image resize (`memCacheWidth/Height`), buang listener/controller di `dispose()` |
| **Jaringan** | Permintaan berulang, payload besar, tanpa cache | DevTools Network, Dio Inspector | Stale-While-Revalidate, Local Cache, Dio Retry Interceptor |
| **Gambar** | Resolusi melebihi ukuran layar, download ulang | DevTools Memory, Network Profiler | `cached_network_image`, format WebP/AVIF, CDN resizing |

---

## 3. Flutter DevTools: Profiling CPU dan Memori

Profiling performa akurat wajib dilakukan menggunakan mode **Profile** (`flutter run --profile`), bukan Debug (memiliki overhead debugging) maupun Release (data simbolik di-strip):

```bash
# Menjalankan profiling aplikasi
flutter run --profile
# Buka DevTools di browser: http://127.0.0.1:9100
```

1. **Tab Performance**:
   * **Frame Chart**: Bar indikator per frame (Hijau < 16 ms, Kuning 16–32 ms, Merah > 32 ms).
   * **Flame Chart**: Menampilkan call stack fungsi per frame untuk menemukan pemanggilan fungsi yang lambat.
   * **Tracks**: UI Thread (Dart build/layout/paint) dan Raster Thread (GPU compositing).
2. **Tab Memory**:
   * **Heap Size & Used Memory**: Melacak memori Dart dan native memory.
   * **GC Events**: Garbage collection frequency.
   * **Heap Snapshot & Diffing**: Mengidentifikasi memory leak saat navigasi bolak-balik antar layar.

---

## 7. Praktikum: Optimasi Performa Aplikasi Nyata

### Langkah 1: Baseline Profiling (Sebelum Optimasi)

Pengujian performa baseline dilakukan pada perangkat riil Android (`arm64 (64 bit) android` - Xiaomi `2201117TY`) dengan rendering engine **Impeller** menggunakan perintah:

```powershell
flutter run -d 2201117TY --profile
```

Setelah aplikasi berjalan di HP, Flutter DevTools dibuka pada tab **Performance** untuk merekam aktivitas render dan frame budget:
* **Skenario Pengujian**: Membuka halaman Beranda, navigasi ke daftar pengumuman, melakukan scroll naik-turun cepat, membuka detail pengumuman, kembali ke beranda, dan pull-to-refresh.
* **Hasil Tangkapan Layar Profiling Baseline**:

![Baseline Profiling (Before)](screenshots/before-profile.png)

#### Analisis Metrik Baseline:
1. **Target Frame Budget**: Garis horizontal **60 FPS** (16,67 ms/frame).
2. **Indikasi Jank (Slow Frame)**:
   * Terdeteksi lonjakan frame merah pekat (*slow frame*) pada awal render yang mencapai **> 27 ms hingga 32 ms**, melampaui batas anggaran 16,67 ms (terjadi *frame drop* / *jank*).
   * Frame Time UI Thread (Dart) dan Raster Thread (GPU) menumpuk tinggi pada inisialisasi pohon widget.
3. **Temuan Masalah (Bottleneck)**:
   * Tidak adanya batas isolasi pengecatan grafis (`RepaintBoundary`) pada item daftar sehingga seluruh canvas dirender ulang saat berinteraksi.
   * Widget subtree di-rebuild secara berulang tanpa konstruktor `const` dan pemisahan state granular.

---

### Langkah 2: Identifikasi Masalah

Berdasarkan analisis hasil profiling pada perangkat Android fisik, teridentifikasi 4 masalah performa utama (didokumentasikan secara rinci di [docs/performance-findings.md](docs/performance-findings.md)):

| No | Kategori Masalah | Indikator DevTools | Dampak Performa | Rencana Solusi |
|---|---|---|---|---|
| 1 | **Widget Rebuild Berlebih & Tanpa RepaintBoundary** | Flame Chart / Frame Chart (Jank > 27 ms pada frame awal) | Beban berlebih pada UI Thread & GPU repainting seluruh canvas | Ekstraksi widget mandiri, `const`, Riverpod `select`, dan `RepaintBoundary` |
| 2 | **Penanganan Gambar Tanpa Batasan Memori** | Raster Thread & Memory Monitor | Potensi lonjakan heap memori native saat memuat foto kamera/dokumen | Pembatasan resolusi decoding memori (`cacheWidth/Height`) |
| 3 | **Request API Berulang Tanpa Cache** | Network Profiler / Latency Loading | Delay render data dan beban I/O jaringan berlebih | Pola *Stale-While-Revalidate* (SWR) pada Repository dan Retry Interceptor |
| 4 | **Ketiadaan List Pagination** | Layout duration saat scrolling dataset | Seluruh data dimuat sekaligus ke memori | Penerapan *infinite scroll* dengan `ScrollController` |

---

### Langkah 3: Terapkan Optimasi

Sesuai rencana, 4 teknik optimasi performa telah diimplementasikan pada kode aplikasi:

1. **Mengurangi Rebuild & Repaint (`home_page.dart` & `chat_screen.dart`)**:
   * **`const` Constructor**: Menambahkan konstruktor konstan pada elemen UI statis.
   * **Ekstraksi Widget**: Memecah halaman `HomePage` menjadi kartu kecil mandiri (`AuthStatusCard`, `FcmTokenCard`, `AnnouncementNavCard`, `AiAssistantNavCard`).
   * **`RepaintBoundary`**: Membungkus setiap `AnnouncementTile` dan `ChatMessageBubble` untuk mengisolasi layer render GPU saat scroll atau update pesan chat.
   * **Riverpod `select`**: Mengganti `ref.watch(provider)` menjadi selector `ref.watch(fcmTokenProvider.select((t) => t))` dan `ref.watch(chatNotifierProvider.select(...))` agar hanya widget bersangkutan yang di-rebuild saat nilai field-nya berubah.
   * **Tear-off Callback**: Menggunakan `_onLogout` menggantikan anonymous closure pada event listener.

2. **Lazy Loading & Pagination (`announcement_page.dart`)**:
   * Menggunakan `ScrollController` listener untuk mendeteksi posisi scroll saat pengguna mendekati 100px dari dasar daftar.
   * Memuat data bertahap (*batch loading*) dan menampilkan indikator loading (*footer spinner*) saat data berikutnya diambil.

3. **Optimasi Gambar & Memori (`chat_screen.dart`)**:
   * Menambahkan pembatasan ukuran memori decoding piksel (`cacheWidth: 300`, `cacheHeight: 300`) pada `Image.file` dan `Image.network` untuk pratinjau lampiran chat/dokumen OCR, mencegah konsumsi RAM berlebih dari foto kamera resolusi tinggi.

4. **Repository Caching - Stale-While-Revalidate (`announcement_repository_impl.dart`)**:
   * Menerapkan in-memory cache dengan TTL (Time-To-Live) 5 menit.
   * Data dari cache lokal langsung disajikan tanpa jeda I/O jaringan, dan cache di-invalidate otomatis saat ada penambahan data baru.

---

### Langkah 4: Verifikasi Profiling

Setelah seluruh teknik optimasi diimplementasikan, aplikasi diuji kembali pada perangkat fisik Android yang sama (`arm64 (64 bit) android` — Xiaomi `2201117TY`) dengan skenario interaksi yang identik.

#### Tangkapan Layar Profiling Sebelum vs Sesudah Optimasi:

| Sebelum Optimasi (Baseline) | Sesudah Optimasi (Verified After) |
|:---:|:---:|
| ![Sebelum Optimasi](screenshots/before-profile.png) | ![Sesudah Optimasi](screenshots/after-profile.png) |

#### Tabel Perbandingan Metrik Performa (Before vs After):

| Metrik / Parameter | Sebelum Optimasi (Baseline) | Sesudah Optimasi (After) | Analisis Dampak |
|---|---|---|---|
| **Rata-rata Frame Rate** | < 45 FPS (fluktuatif) | **Stabil 60 FPS (average)** | Peningkatan kehalusan visual sempurna |
| **Durasi Frame Time saat Scroll** | Melonjak hingga 27–32 ms (*Jank*) | **Rata-rata 2 ms – 5 ms** | Seluruh frame berada jauh di bawah ambang 16,67 ms |
| **Jank / Frame Drops** | Terjadi red-bar spike > 27 ms | **0 Jank Frames (Nol Frame Drop Merah)** | 100% bebas lag & tanpa stuttering |
| **Beban UI Thread (Dart)** | Tinggi akibat rebuild berulang | **Sangat rendah (1–3 ms)** | Hanya subtree terkait yang di-rebuild |
| **Beban Raster Thread (GPU)** | Tinggi (repainting seluruh canvas) | **Rendah (1–4 ms)** | `RepaintBoundary` mengisolasi render layer |
| **Konsumsi Memori Gambar** | Full decoding resolution | Terkompresi (`cacheWidth: 300`) | Mencegah lonjakan heap memory dari gambar besar |
| **Responsivitas Data** | Delay I/O jaringan berulang | Instan via *Stale-While-Revalidate* cache | Data lokal langsung tampil tanpa jeda |



