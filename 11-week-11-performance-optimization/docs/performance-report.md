# Laporan Optimasi Performa Aplikasi (Performance Report)

* **Proyek**: Campus Notify (`campus_notify`)
* **Minggu Pembelajaran**: Week 11 — Performance Optimization
* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Program Studi**: D-IV Teknik Informatika
* **Jurusan**: Teknologi Informasi — Politeknik Negeri Malang
* **Perangkat Pengujian**: Android Fisik (`arm64 (64 bit) android` — Xiaomi 2201117TY)
* **Rendering Engine**: Impeller
* **Mode Profiling**: Profile Mode (`flutter run -d 2201117TY --profile`)

---

## 1. Baseline Metrics (Sebelum Optimasi)

Pengujian awal dilakukan pada kode unoptimized untuk mencatat performa dasar saat menjalankan skenario interaktif (membuka halaman, scroll cepat, navigasi antar layar, dan pull-to-refresh).

| Parameter Metrik | Nilai Pengukuran Baseline | Keterangan / Analisis |
|---|---|---|
| **Rata-rata Frame Time** | 22–32 ms (saat scroll & transisi) | Melebihi anggaran frame budget 16,67 ms (60 FPS) |
| **Jank / Slow Frame Count** | Terdeteksi bar merah pekat (> 27 ms) | Frame drop terlihat jelas pada visualisasi Frame Chart |
| **Beban UI Thread** | Fluktuatif tinggi (hingga 18 ms) | Seluruh pohon widget di-rebuild ulang secara monolitik |
| **Beban Raster Thread** | Tinggi (hingga 14 ms) | Tidak ada isolasi repaint canvas saat scrolling |
| **Konsumsi Memori (Dart Heap)** | Heap naik bertahap saat interaksi | Alokasi objek baru tanpa pembersihan listener |
| **Penanganan Gambar** | Decoding resolusi asli | Memakan heap memory native tanpa pembatasan dimensi piksel |
| **Strategi Jaringan** | Pola direct request tanpa cache | Terjadi latency I/O dan spinner berulang setiap navigasi |

---

## 2. Temuan dari Profiling (Before vs After)

### A. Tangkapan Layar Profiling DevTools (Frame Chart / Flame Chart):

| Sebelum Optimasi (Baseline) | Sesudah Optimasi (Verified After) |
|:---:|:---:|
| ![Sebelum Optimasi](../screenshot/before-profile.png) | ![Sesudah Optimasi](../screenshot/after-profile.png) |

### B. Tangkapan Layar Memory Profiling (Heap Snapshots & Diffing):

| Memory Snapshot 1 & 2 (Diff Snapshots) |
|:---:|
| ![Memory Profiling](../screenshot/memory-profile.png) |

### C. Temuan Kritis:
1. **Monolithic Build Tree**: `home_page.dart` merender seluruh kartu status, token debug, dan tombol navigasi dalam satu build method tanpa isolasi.
2. **Unscoped State Listeners**: Pemanggilan `ref.watch(fcmTokenProvider)` memicu re-render seluruh halaman beranda saat token perangkat diperbarui.
3. **Ketiadaan Repaint Boundary**: Setiap kali daftar pengumuman di-scroll atau pesan chat masuk, GPU terpaksa menggambar ulang seluruh kanvas layar.
4. **Alokasi Gambar Resolusi Penuh**: Lampiran foto dokumen OCR pada chat dimuat tanpa pembatasan memori decoding.

---

## 3. Optimasi yang Diterapkan & Alasan Pemilihan

Empat teknik optimasi performa komprehensif telah dipilih dan diterapkan:

### 1. Ekstraksi Widget, `const` Constructor, dan `RepaintBoundary`
* **File Diubah**: `lib/pages/home_page.dart`, `lib/features/announcements/presentation/pages/announcement_page.dart`, `lib/features/chat/chat_screen.dart`.
* **Alasan Pemilihan**:
  * Widget `const` tidak akan di-rebuild saat parent melakukan build ulang.
  * Ekstraksi widget membatasi skop re-rendering hanya pada subtree yang berubah data.
  * `RepaintBoundary` memisahkan layer render grafis (*render tree layer boundary*) sehingga GPU tidak mengecat ulang seluruh kanvas saat pengguna melakukan scroll.

### 2. Riverpod Scoped State Rebuild (`select`)
* **File Diubah**: `lib/pages/home_page.dart` (`FcmTokenCard`) dan `lib/features/chat/chat_screen.dart` (`ChatPrivacyQuotaBanner`).
* **Alasan Pemilihan**:
  * Menggunakan `ref.watch(provider.select((s) => s.targetField))` memastikan widget hanya rebuild jika nilai field spesifik tersebut benar-benar berubah, bukan setiap kali seluruh objek state mengalami mutasi.

### 3. Lazy Loading & Pagination (Infinite Scroll)
* **File Diubah**: `lib/features/announcements/presentation/pages/announcement_page.dart`.
* **Alasan Pemilihan**:
  * Memuat dataset dalam batch kecil (10 item pertama) dan memuat 5 item tambahan saat pengguna mendekati 100px dari dasar daftar menggunakan listener `ScrollController`.
  * Menghindari alokasi memori berlebih dan mempersingkat durasi initial layout pada UI thread.

### 4. Image Memory Cache Resizing & Stale-While-Revalidate (SWR) Repository Cache
* **File Diubah**: `lib/features/chat/chat_screen.dart` dan `lib/features/announcements/data/repositories/announcement_repository_impl.dart`.
* **Alasan Pemilihan**:
  * Menambahkan `cacheWidth: 300` dan `cacheHeight: 300` pada penampil gambar membatasi ukuran decoding piksel di memori native, mencegah *Out-of-Memory* (OOM).
  * Pola caching SWR dengan in-memory cache berdurasi 5 menit menyajikan data lokal secara instan tanpa menunggu latency I/O jaringan.

---

## 4. Hasil Verifikasi (Metrics After)

Pengujian ulang dengan skenario yang sama persis menghasilkan perbaikan metrik yang signifikan:

| Parameter Pengujian | Sebelum Optimasi | Sesudah Optimasi | Peningkatan / Hasil |
|---|---|---|---|
| **Rata-rata Frame Time** | 22–32 ms | **2 ms – 5 ms** | **Penurunan durasi hingga ~80%** |
| **Stabilitas Frame Rate** | < 45 FPS (fluktuatif) | **Stabil 60 FPS (average)** | Sangat mulus (*smooth*) tanpa lag |
| **Jank Count saat Scrolling** | Sering terjadi frame drop merah | **0 Jank Frame (Nol Frame Drop Merah)** | 100% bebas lag & stuttering |
| **Beban UI Thread** | Tinggi (> 18 ms) | **Sangat Rendah (1–3 ms)** | Dart execution sangat efisien |
| **Beban Raster Thread** | Tinggi (> 14 ms) | **Rendah (1–4 ms)** | GPU repainting terisolasi sempurna |
| **Kestabilan Dart Heap** | Rentan spike | **16.4 MB (Reachable: 13.8 MB)** | 0% Retained Size Leak di DevTools |
| **Test Suite Status** | - | **22/22 Tests Passed** | 100% fungsionalitas dan logika valid |

---

## 5. Kesimpulan

Penerapan kombinasi teknik optimasi arsitektural (ekstraksi widget, `RepaintBoundary`, Riverpod `select`), penanganan memori gambar (`cacheWidth/Height`), pagination dinamis, serta caching repository SWR terbukti secara empiris melenyapkan frame jank dan menstabilkan frame rate aplikasi pada target 60 FPS pada perangkat fisik Android nyata.
