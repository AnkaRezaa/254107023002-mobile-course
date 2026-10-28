# 09-week-9-ai-assisted-development

Pada modul pembelajaran Minggu ke-9 ini, fokus utama adalah **AI-Assisted Development / Vibe Coding** yang berdisiplin tinggi (*No Vibe Coding Without Verification*). Materi mencakup perancangan prompt menggunakan formula 5-slot, penyusunan konteks kode yang presisi, pengujian dan verifikasi statis kode hasil AI (`flutter analyze`, `dart format`), teknik *debug dengan test merah* (TDD) untuk membuktikan halusinasi dan bug AI, isolasi logika bisnis ke use case domain murni (*Clean Architecture*), pelaksanaan *AI Prompt Challenge* melalui review sejawat AI senior, serta evaluasi kritis (menerima temuan valid dan menolak usulan yang merusak arsitektur).

---

## Konsep AI-Assisted Development dan Disiplin Vibe Coding

Dalam rekayasa perangkat lunak modern, AI generatif (seperti GitHub Copilot, Gemini Code Assist, atau Cursor) berfungsi sebagai asisten produktivitas, bukan pengganti nalar arsitektur pengembang (*driver vs. passenger*). Fenomena *"Vibe Coding"*—yaitu menerima kode dari AI secara membabi buta hanya karena "tampak berfungsi"—sangat rentan menimbulkan bug regresi, kebocoran dependensi, serta kerentanan arsitektural.

| Konsep | Penjelasan Praktis |
|---|---|
| **Prompt 5-Slot** | Rumus instruksi terstruktur: *Role/Peran*, *Task/Tugas Utama*, *Context/Konteks & Batasan*, *Constraints/Arsitektur*, dan *Expected Output/Format Keluaran*. |
| **Context Engineering** | Teknik melampirkan konteks potongan kode yang relevan (misalnya entity dan interface) agar AI tidak berasumsi atau berhalusinasi membuat struktur baru. |
| **Debug dengan Test Merah** | Alur verifikasi bug AI: buat test yang gagal terlebih dahulu untuk membuktikan kecacatan logika AI, baru lakukan perbaikan minimal hingga test lulus (*TDD*). |
| **Sterilitas Arsitektur** | Domain layer wajib 100% *Pure Dart* (steril dari Flutter SDK, Riverpod, SQLite, dan Dio). Filter/search wajib berada di domain use case, bukan di UI widget. |
| **Review Kritis AI Challenge** | Menguji saran AI dari kacamata Senior Developer: memverifikasi temuan dengan bukti konkret (grep/test), serta berani menolak rekomendasi AI yang melanggar prinsip arsitektur. |

---

## Praktikum 1 — Prompt dan Context Engineering

1. **Perancangan Prompt 5-Slot**:
   Prompt dirancang menggunakan 5 slot instruksi yang eksplisit untuk mencegah AI menghasilkan kode liar atau melanggar arsitektur:
   - **Peran**: Flutter Senior Developer.
   - **Tugas**: Tambahkan fitur pencarian (*search*) pada halaman daftar pengumuman kampus.
   - **Konteks**: Modul `campus_notify` dengan Clean Architecture (`presentation -> domain <- data`), Riverpod 3.x, entity `Announcement`.
   - **Batasan**: Jangan panggil SQLite/Dio dari widget, pisahkan logic ke use case domain murni, sertakan empty state view.
   - **Output yang Diharapkan**: Kode use case, state provider, widget search bar, empty view, dan 1 widget test.

2. **Dokumentasi Log AI**:
   Seluruh prompt mentah dan potongan konteks kode dicatat secara transparan pada [`docs/ai_log.md`](docs/ai_log.md).

3. **Dokumentasi Screenshot Prompt**:
   ![Prompt Praktikum 1](screenshots/praktikum%201%20prompt.jpg)

---

## Praktikum 2 — Generate dan Verifikasi Search

1. **Implementasi Awal Hasil Generate AI**:
   AI meng-generate komponen antarmuka pencarian pada `AnnouncementsPage`:
   - `AnnouncementSearchBar`: Widget input pencarian teks interaktif dengan ikon pencarian dan tombol pembersih (*clear button*).
   - `AnnouncementEmptyView`: Widget visual ketika pencarian tidak menemukan hasil (menggunakan ikon `Icons.search_off_rounded` dan pesan kontekstual).
   - Provider awal pencarian untuk memfilter daftar pengumuman di layar.

2. **Verifikasi Awal**:
   - Memastikan ketiadaan error impor lintas-layer.
   - Memverifikasi 3 skenario pencarian manual: query kosong (semua muncul), query cocok (hanya item sesuai yang muncul), dan query tidak cocok (tampil empty state).
   - Dokumentasi screenshot hasil prompt dan pengujian awal:
     ![Hasil Prompt Pengumuman](screenshots/hasil%20prompt%20(pengumuman).jpg)
     ![Flutter Test dan Flutter Analyze Praktikum 2](screenshots/flutter%20test%20dan%20flutter%20analyze%20praktikum%202.jpg)

---

## Praktikum 3 — Debug dan Refactor

1. **Reproduksi Masalah & Test Merah (TDD)**:
   - **Masalah Ditemukan**: Filter awal AI menggunakan `items.where((item) => item.title.contains(query))`. Method `.contains()` bawaan Dart bersifat *case-sensitive* dan peka terhadap spasi (*whitespace*).
   - **Test Merah**: Dibuat unit test pembukti bug pada `test/search_filter_test.dart` dengan query huruf kecil `'krs'` terhadap judul `'Jadwal KRS Semester Genap'`. Pengujian ini gagal (MERAH).

2. **Isolasi ke Use Case Murni**:
   Logika pencarian dipisahkan sepenuhnya dari widget ke dalam Domain Use Case `SearchAnnouncements` di `lib/features/announcements/domain/usecases/search_announcements.dart`.

3. **Perbaikan Minimal & Test Hijau**:
   Logika dinormalisasi menggunakan `.trim().toLowerCase()`:
   ```dart
   final trimmedQuery = query.trim().toLowerCase();
   if (trimmedQuery.isEmpty) return items;
   return items.where((item) => item.title.toLowerCase().contains(trimmedQuery)).toList();
   ```
   Seluruh test berubah menjadi HIJAU (100% Passed).

   ![Flutter Test dan Analyze Praktikum 3](screenshots/praktikum%203%20flutter%20test%20dan%20analyze.jpg)

4. **Pemisahan 4 Layer Bersih**:
   - `Widget (UI Saja)`: `AnnouncementsPage`, `AnnouncementSearchBar`, `AnnouncementEmptyView`.
   - `Notifier (State Saja)`: `AnnouncementSearchQueryNotifier` & `filteredAnnouncementsProvider`.
   - `Use Case (Aturan Bisnis)`: `SearchAnnouncements`.
   - `Repository (Data)`: `AnnouncementRepository` & implementasinya.

---

## AI Prompt Challenge: Senior Dev Code Review

Evaluasi kritis dilakukan terhadap saran AI senior dev yang dicatat lengkap di [`docs/ai_challenge.md`](docs/ai_challenge.md):

| No | Temuan AI | Level | Keputusan | Alasan Teknis & Bukti |
|---|---|---|---|---|
| 1 | Pencarian hanya mencocokkan `title`, belum mencakup isi `body`. | Saran | **TERIMA (Accepted)** | Terbukti benar via inspeksi kode. Mahasiswa sering mengingat inti pengumuman di bagian isi. Diperbaiki dengan operator `||` ke `item.body` dan dibuktikan dengan unit test. |
| 2 | Menghapus `filteredAnnouncementsProvider` dan memanggil use case langsung di dalam `build()` Widget. | Blocker | **TOLAK KERAS (Rejected)** | Melanggar prinsip *Clean Architecture* dan *Separation of Concerns*. Pemrosesan string di dalam `build()` merusak mekanisme caching Riverpod dan membebani rendering UI Flutter. |
| 3 | Potensi desinkronisasi `TextEditingController` jika query diubah dari luar widget. | Saran | **TERIMA + REFACTOR** | Diselaraskan agar controller tetap sinkron terhadap state management jika terjadi reset query global. |

![Hasil Test AI Challenge 9 Passed](screenshots/ai%20challenge%20flutter%20test%209%20passed.jpg)

---

## Refactoring Challenge

1. **Pengecilan Kode AI (> 80 baris menjadi fungsi kecil teruji)**:
   - Kode AI awal yang menumpuk di file page dipangkas menjadi beberapa komponen modular berukuran kecil (< 40 baris per fungsi `build()`).
   - Logika bisnis difaktorkan ke `SearchAnnouncements` use case (hanya 18 baris, *pure Dart*):
     ```dart
     class SearchAnnouncements {
       const SearchAnnouncements();

       List<Announcement> call({
         required List<Announcement> items,
         required String query,
       }) {
         final trimmedQuery = query.trim().toLowerCase();
         if (trimmedQuery.isEmpty) return items;
         return items.where((item) {
           final matchesTitle = item.title.toLowerCase().contains(trimmedQuery);
           final matchesBody = item.body.toLowerCase().contains(trimmedQuery);
           return matchesTitle || matchesBody;
         }).toList();
       }
     }
     ```
2. **Isolasi Logika Filter ke Domain Murni**:
   - `SearchAnnouncements` ditaruh di `features/announcements/domain/usecases/search_announcements.dart`.
   - Bebas dari ketergantungan framework Flutter, Riverpod, SQLite, maupun Dio.
3. **Pembersihan Impor Lintas-Layer**:
   - Widget presentasi hanya membaca data melalui Riverpod Provider.
   - Domain layer tidak memiliki satupun impor ke `presentation/`, `data/`, atau library luar.

---

## Testing

1. **Uji Mesin Otomatis**:
   - `flutter analyze` : **No issues found!** (Analisis statis bersih dari lint warning dan unused imports).
   - `dart format --set-exit-if-changed lib test` : **Formatted 33 files (0 changed)**.
   - `flutter test` : **All tests passed! (9 tests hijau)**.

   ![Verifikasi Mesin Praktikum 3](screenshots/praktikum%203%20flutter%20test%20dan%20analyze.jpg)
   ![Pengujian Flutter Test Refactoring](screenshots/pratktikum%20refactoring%20challenge%20flutter%20test.jpg)

2. **Daftar Unit & Widget Test**:
   - `test/search_filter_test.dart`:
     - Filter mengabaikan huruf besar/kecil (*case-insensitive*).
     - Filter menangani spasi berlebih dengan `trim()`.
     - Filter menemukan pengumuman berdasarkan isi konten (`body`).
     - Query kosong mengembalikan seluruh data.
     - Query tak cocok mengembalikan list kosong.
   - `test/announcement_empty_widget_test.dart`:
     - Menampilkan icon `search_off_rounded` dan teks query tidak ditemukan saat data kosong karena filter.
     - Menampilkan icon `inbox_outlined` dan teks default saat belum ada pengumuman sama sekali.

3. **Uji Manual 3 Skenario Pencarian**:
   - **Query Kosong (`""`)**: Menampilkan seluruh katalog pengumuman secara utuh saat teks kosong atau tidak ada filter aktif.
     
     ![Refactor Kueri Kosong](screenshots/refactor%20kueri%20kosong.jpg)

   - **Query Cocok (`"KRS"`)**: Menampilkan pengumuman yang sesuai dengan kata kunci pencarian.
     
     ![Refactoring Kueri Cocok](screenshots/refactoring%20kueri%20cocok.jpg)

   - **Query Tidak Cocok (`"xyz123"`)**: Menampilkan widget `AnnouncementEmptyView` dengan icon dan pesan informatif bahwa pengumuman tidak ditemukan.
     
     ![Refactor Kueri Salah](screenshots/refactor%20kueri%20salah.jpg)

---

## Error Umum dan Solusinya

| No | Gejala Error | Penyebab | Solusi Praktis |
|:---|:---|:---|:---|
| 1 | `Method not found: 'StateProvider'` | AI menggunakan `StateProvider<String>` yang sudah deprecated/dihapus pada `flutter_riverpod: ^3.4.3`. | Ganti dengan class notifier modern `AnnouncementSearchQueryNotifier extends Notifier<String>` dan gunakan `NotifierProvider`. |
| 2 | `Member not found: 'black89'` | AI salah mengetik properti Material color palette Flutter. | Koreksi menjadi `Colors.black87` atau gunakan skema `Theme.of(context).colorScheme`. |
| 3 | `PathNotFoundException` pada `dart format .` | Perintah `.` memindai folder `build/app/intermediates/...` yang memiliki path Windows sangat panjang (> 260 char). | Jalankan `flutter clean` lalu batasi pemindaian hanya pada folder kode: `dart format --set-exit-if-changed lib test`. |
| 4 | Empty state palsu pada pencarian huruf kecil atau ber-spasi | Method bawaan Dart `.contains()` bersifat case-sensitive dan tidak membuang spasi awal/akhir. | Gunakan normalisasi `query.trim().toLowerCase()` dan bandingkan dengan `item.title.toLowerCase()`. |

---

## Checklist Verifikasi Mandiri

- [x] **Prompt 5 Slot + Konteks**: Tersimpan rapi di [`docs/ai_log.md`](docs/ai_log.md).
- [x] **Analisis Statis & Pengujian**: `flutter analyze` 0 issue, `flutter test` lulus 100% hijau.
- [x] **AI Challenge**: Minimal 1 temuan AI dibuktikan benar (body search) + 1 temuan ditolak beralasan teknis arsitektur.
- [x] **Pemisahan 4 Layer**: Widget $\rightarrow$ Notifier $\rightarrow$ Use Case $\rightarrow$ Repository.
- [x] **Penguasaan Materi**: Mampu menjelaskan seluruh alur dan keputusan teknis secara mandiri tanpa bantuan AI.


---

## Refleksi

1. **Satu halusinasi AI apa yang Anda temukan dan bagaimana membuktikannya?**

   **Jawab:**
   Halusinasi yang paling signifikan adalah ketika AI menggenerasi properti palet warna `Colors.black89` pada komponen visual antarmuka serta masih merekomendasikan sintaksis `StateProvider<String>` yang telah dihapus (*deprecated/removed*) pada pustaka `flutter_riverpod: ^3.4.3`.
   
   Pembuktian dilakukan secara empiris melalui dua langkah:
   - **Pemeriksaan Kompilasi & Dokumentasi SDK**: Melalui verifikasi kode sumber Flutter SDK (`Colors` class di `material/colors.dart`), terbukti bahwa konstanta `Colors.black89` tidak pernah terdefinisi (properti valid adalah `Colors.black87` atau `Colors.black54`).
   - **Verifikasi Analisis Statis (`flutter analyze`)**: Ketika kode dieksekusi, compiler Dart melemparkan kesalahan fatal:
     ```text
     error: The getter 'black89' isn't defined for the class 'Colors'. (undefined_getter)
     error: Undefined class 'StateProvider'. (undefined_class)
     ```
   Temuan ini membuktikan secara empiris bahwa model AI mengalami halusinasi identifikasi properti dan memiliki keterbatasan basis pengetahuan (*knowledge cutoff*) terhadap versi pustaka Riverpod terkini.

2. **Prompt mana yang paling membantu dan apa yang Anda ubah?**

   **Jawab:**
   Prompt yang paling membantu adalah **Prompt 5-Slot** pada Praktikum 1 yang membatasi arsitektur:
   ```text
   tambahkan fitur search pada pengumuman.
   arsitektur : presentation> domain < data
   jangan panggil sql lite dari widget 
   sertakan empty state + 1 widget test
   konteks: implementasikan pada folder campus_notify...
   ```
   **Perubahan yang Dilakukan**:
   Meskipun prompt awal berhasil membatasi penempatan file, luaran AI masih menghasilkan implementasi pencarian naif menggunakan `.contains(query)` di dalam provider UI yang bersifat *case-sensitive*. Saya mengubah dan mempertajam prompt pada Praktikum 3 dengan menyertakan instruksi pembuktian bug menggunakan metodologi pengujian merah (*test-driven debugging*):
   ```text
   1. Debug dengan test merah:
      1. Reproduksi: langkah + input pemicu bug
      2. Isolasi: pindah filter ke use case murni
      3. Test merah: buat test gagal pembukti bug
      4. Perbaiki kecil, jalankan test + analyze
      5. Catat akar masalah di docs/ai-log.md
   ```
   Perubahan instruksi ini secara efektif mengalihkan proses dari sekadar meminta kode langsung menjadi proses perbaikan sistematis berbasis bukti kegagalan tes.

3. **Satu refactor apa yang Anda lakukan pada kode AI?**

   **Jawab:**
   Refaktorisasi paling fundamental yang dilakukan adalah **mengisolasi logika filter pencarian dari lapisan Presentation ke dalam lapisan Domain murni** melalui use case [`SearchAnnouncements`](campus_notify/lib/features/announcements/domain/usecases/search_announcements.dart).
   - **Sebelum Refactoring**: Logika komparasi string diletakkan secara langsung di dalam provider/widget presentasi dengan metode `items.where((item) => item.title.contains(query))`. Pendekatan ini melanggar *Separation of Concerns*, gagal menangani huruf kapital atau spasi berlebih, dan tidak dapat diuji secara independen dari framework.
   - **Sesudah Refactoring**: Logika dipindahkan ke kelas use case murni Dart (*pure Dart* tanpa dependensi Flutter/Riverpod/SQLite), dinormalisasi menggunakan `query.trim().toLowerCase()`, serta diperluas untuk mencocokkan judul (`title`) maupun isi pengumuman (`body`). Komponen UI [`AnnouncementsPage`](campus_notify/lib/features/announcements/presentation/pages/announcement_page.dart) kini murni berfungsi sebagai penampil visual yang mengonsumsi use case melalui Riverpod.

4. **Keputusan terima/tolak mana yang paling sulit?**

   **Jawab:**
   Keputusan paling krusial terjadi pada **Temuan 2 di sesi AI Prompt Challenge**, di mana AI mengusulkan untuk menghapus `filteredAnnouncementsProvider` dan memanggil use case `SearchAnnouncements` langsung di dalam method `build()` milik `AnnouncementsPage` dengan alasan "mengurangi *boilerplate* kode dan menyederhanakan pohon dependensi".

   Keputusan penolakan ini membutuhkan ketegasan arsitektural:
   - **Alasan Penolakan Keras**: Kendati usulan AI tampak praktis karena mengeliminasi satu lapisan provider, secara arsitektur Flutter tindakan tersebut merupakan *anti-pattern* yang merusak performa. Method `build()` dapat dipanggil puluhan kali per detik (misalnya saat proses render frame atau interaksi scroll). Menjalankan kalkulasi penyaringan list di dalam `build()` tanpa mekanisme *memoization/caching* bawaan Riverpod memicu pemborosan siklus komputasi (*unnecessary re-computation*).
   - Penolakan terhadap rekomendasi AI senior dev ini menegaskan bahwa kemudahan penulisan kode sesaat (*less boilerplate*) tidak boleh mengorbankan integritas arsitektur dan efisiensi eksekusi aplikasi.

---

## Referensi

1. **Dokumentasi Resmi Flutter**: [Testing Flutter Apps](https://docs.flutter.dev/testing)
2. **Dokumentasi Resmi Riverpod**: [Riverpod 3.0 Migration & Notifiers](https://riverpod.dev/docs/concepts/providers)
3. **Martin Fowler**: [Clean Architecture & Test-Driven Development (TDD)](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
4. **Modul Perkuliahan Pemrograman Mobile Minggu 9**: *AI-Assisted Development / Vibe Coding*, Jurusan Teknologi Informasi, Politeknik Negeri Malang.
