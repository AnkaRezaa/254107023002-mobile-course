# Evaluasi AI Verification Checklist & Keputusan Final Mahasiswa

Dokumen ini mencatat evaluasi kritis mahasiswa terhadap rekomendasi AI coding assistant, pemeriksaan lembar verifikasi arsitektur (*AI Verification Checklist*), serta penetapan keputusan teknis final sebelum implementasi kode.

---

## 1. AI Verification Checklist

Berikut adalah hasil pemeriksaan mendalam terhadap usulan awal yang diajukan oleh AI:

| Poin Verifikasi Checklist | Status | Catatan Temuan & Evaluasi Teknis |
|---|:---:|---|
| **1. Apakah interface repository tinggal di domain dan implementasi di data?** | **LULUS** | Kontrak abstraksi `AuthRepository` dan `AnnouncementRepository` diletakkan di `domain/repositories/`. Implementasi konkret `AuthRepositoryImpl` dan `AnnouncementRepositoryImpl` berada di `data/repositories/`. Tidak ada pencampuran dalam satu folder. |
| **2. Apakah domain bebas import Flutter / Dio / SQLite / Firebase?** | **LULUS** | Diverifikasi via pengujian grep: tidak ditemukan satupun import framework UI (`flutter`), network (`dio`), database (`sqflite`), maupun push service (`firebase`) di dalam layer domain. Domain 100% murni bahasa Dart. |
| **3. Apakah AI membuat use case untuk tiap CRUD satu-baris?** | **LULUS (Disesuaikan)** | Usulan AI yang menyarankan use case untuk operasi pass-through seperti `LogoutUseCase` atau `GetAnnouncementDetail` ditolak demi mencegah *over-engineering*. Use case hanya diterapkan pada operasi yang memiliki logika bisnis: `LoginUseCase` dan `GetAnnouncements`. |
| **4. Apakah entity bebas mapping (toMap/fromMap/toJson hanya di model)?** | **LULUS** | Entity `AuthSession` dan `Announcement` murni hanya memuat field immutable data bisnis. Seluruh operasi serialisasi (`toMap`), deserialisasi (`fromMap`), dan mapping `toEntity()` diisolasi di `AuthSessionModel` dan `AnnouncementModel`. |
| **5. Apakah wiring DI terpusat di provider dan widget tidak new Repository() sendiri?** | **LULUS** | Seluruh dependensi disuntikkan melalui Riverpod Provider (`authRepositoryProvider`, `announcementRepositoryProvider`). Widget UI hanya membaca state via `ref.watch()` dan mengeksekusi aksi via `ref.read()`. |
| **6. Keputusan final dan alasan teknis tercatat?** | **LULUS** | Tercatat pada tabel keputusan final di bawah ini dengan argumen arsitektural yang jelas. |

---

## 2. Tabel Komparasi: Usulan AI vs Keputusan Final Mahasiswa

| Aspek Arsitektur | Usulan Awal AI | Keputusan Final Mahasiswa | Alasan & Argumen Teknis |
|---|---|---|---|
| **Struktur Folder** | Feature-First (`lib/features/auth` dan `lib/features/announcements`) | **Diterima Penuh** | Memisahkan kode per fitur mempermudah pemeliharaan jangka panjang dan memungkinkan penambahan/penghapusan fitur tanpa merusak fitur lainnya. |
| **Penerapan Use Case** | Membuat use case terpisah untuk setiap aksi (Login, Logout, Refresh, Get Announcement, Add Announcement) | **Disederhanakan** | Dibatasi hanya pada `LoginUseCase` (karena ada validasi aturan bisnis format email dan panjang kata sandi) dan `GetAnnouncements`. Operasi sederhana seperti logout ditangani langsung oleh `AuthNotifier` memanggil repository. |
| **Penyimpanan Token** | `TokenStore` dipindah ke `features/auth/data/datasources/` | **Diterima Penuh** | Menyimpan kredensial token terenkripsi merupakan tanggung jawab data source lokal fitur autentikasi. |
| **Sanitasi Data di UI** | Pemotongan string token FCM dipindah ke fungsi helper | **Diterima Penuh** | Dibuatkan pure function `maskToken` di `core/format.dart` agar layer presentation tetap steril dari manipulasi data mentah. |
| **Penanganan Error di UI** | UI tidak lagi menangkap `DioException` melainkan `Failure` | **Diterima Penuh** | Menghilangkan keterikatan HTTP client dari widget login sehingga jika library jaringan diganti di masa depan, UI tidak terpengaruh. |
| **Dependency Injection** | Menggunakan Riverpod bawaan tanpa library pihak ketiga | **Diterima Penuh** | Menghemat ukuran build dan mencegah over-engineering yang tidak perlu dengan library DI tambahan seperti `get_it`. |

---

## 3. Justifikasi Keputusan Arsitektural

1. **Mengapa interface repository harus di domain, bukan di data?**  
   Prinsip *Dependency Inversion* menyatakan bahwa modul tingkat tinggi (domain) tidak boleh bergantung pada modul tingkat rendah (data). Kedua modul harus bergantung pada abstraksi. Dengan menaruh interface di domain, aturan bisnis menentukan kontrak yang dibutuhkan, dan data layer bertugas memenuhi kontrak tersebut. Hal ini membuat domain dapat diuji dengan Fake Repository tanpa database atau jaringan nyata.

2. **Kapan use case benar-benar dibutuhkan vs repository langsung?**  
   Use case dibutuhkan saat terdapat aturan validasi bisnis, penggabungan lebih dari satu repository (orkestrasi), atau transformasi data. Untuk operasi pembacaan data sederhana satu-baris tanpa transformasi, memanggil repository langsung dari notifier sudah cukup untuk menghindari kode redundan (*boilerplate*).
