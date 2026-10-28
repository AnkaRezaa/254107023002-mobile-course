# AI Prompt Challenge: Senior Dev Code Review & Verification

Dokumen ini mencatat proses **AI Prompt Challenge** pada fitur pencarian pengumuman (*Announcements Search*) di proyek `campus_notify`. Evaluasi dilakukan menggunakan kacamata arsitektur Clean Architecture (*feature-first: presentation -> domain <- data*), state management Riverpod, serta verifikasi pengujian otomatis.

---

## 1. Prompt Mentah (Raw Prompt)

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

---

## 2. Output Review AI (Senior Dev Findings)

Berikut adalah 3 temuan yang dihasilkan oleh AI:

### Temuan 1
- **Area**: `lib/features/announcements/domain/usecases/search_announcements.dart`
- **Temuan**: Filter pencarian hanya memeriksa properti `title` pengumuman (`item.title.toLowerCase().contains(...)`), padahal entitas `Announcement` memiliki isi pengumuman (`body`). Pengguna yang mencari materi atau kata kunci spesifik yang terdapat di badan pengumuman akan mendapatkan hasil kosong (*false negative*).
- **Level**: **Saran / Usability**
- **Alasan AI**: Pengalaman pengguna (*user experience*) terdegradasi. Pada aplikasi informasi kampus, mahasiswa sering kali mengingat inti pengumuman (misalnya nama dosen, ruang kelas, atau tanggal) yang ditulis di bagian `body`, bukan hanya di judul.

### Temuan 2
- **Area**: Arsitektur & State Management (`announcement_providers.dart` & `announcement_page.dart`)
- **Temuan AI**: Hapus provider turunan `filteredAnnouncementsProvider`. AI menyarankan untuk memanggil `SearchAnnouncements` use case langsung di dalam method `build()` milik `AnnouncementsPage` menggunakan `ref.watch(searchAnnouncementsProvider).call(items: ..., query: ...)`.
- **Level**: **Blocker / Architecture** (menurut AI)
- **Alasan AI**: Mengurangi *boilerplate code* Riverpod dan mengeliminasi satu lapisan provider turunan agar pohon dependensi lebih ramping.

### Temuan 3
- **Area**: Widget Presentasi (`AnnouncementSearchBar` di `announcement_page.dart`)
- **Temuan**: `TextEditingController` dibuat secara lokal di dalam `StatefulConsumerWidget`, namun tidak ada mekanisme sinkronisasi dua arah jika state `announcementSearchQueryProvider` di-reset dari luar widget (misalnya jika ada tombol *reset filter* di AppBar).
- **Level**: **Saran / State Synchronization**
- **Alasan AI**: Jika state query dikosongkan oleh aksi global/eksternal, text field pada layar berpotensi tetap menampilkan teks lama sehingga terjadi desinkronisasi antara UI input dan state data yang ditampilkan.

---

## 3. Tabel Usulan vs. Keputusan

| No | Temuan AI | Level Usulan AI | Keputusan Pengembang | Alasan Teknis & Bukti |
|:---|:---|:---|:---|:---|
| 1 | Pencarian hanya mencocokkan `title`, belum mencakup isi `body`. | Saran | **TERIMA (Accepted)** | **Bukti Grep/Code:** Kode awal hanya mengecek `item.title.toLowerCase().contains(trimmedQuery)`. Diperbaiki dengan operator `||` ke `item.body.toLowerCase().contains(trimmedQuery)` dan diverifikasi dengan unit test baru. |
| 2 | Menghapus `filteredAnnouncementsProvider` dan mengeksekusi Use Case langsung di method `build()` Widget. | Blocker (Klaim AI) | **TOLAK KERAS (Rejected)** | **Alasan Arsitektur:** Melanggar prinsip *Clean Architecture* (*Separation of Concerns*). UI tidak boleh mengeksekusi *business logic* di dalam method `build()`. Selain itu, kalkulasi filter akan dieksekusi berulang kali pada setiap *frame rebuild*, merusak mekanisme *caching/memoization* dari Riverpod. |
| 3 | Potensi desinkronisasi `TextEditingController` jika state diubah dari luar. | Saran | **TERIMA + REFACTOR (Accepted with Refactor)** | **Alasan Teknis:** Untuk komponen saat ini, controller dikelola lokal dengan tombol *clear* bawaan. Namun arsitektur disiapkan agar `ref.listen` dapat dipasang jika interaksi global dibutuhkan tanpa memicu *infinite loop text update*. |

---

## 4. Bukti Verifikasi dan Implementasi

### A. Bukti Temuan 1 (Diterima): Unit Test Pembukti & Perbaikan
Ditambahkan test case pada `test/search_filter_test.dart`:
```dart
test('pencarian menemukan pengumuman berdasarkan isi konten (body)', () {
  final result = searchUseCase(
    items: sampleAnnouncements,
    query: 'perkuliahan',
  );
  expect(result, hasLength(1));
  expect(result.first.id, 3);
  expect(result.first.body, contains('perkuliahan'));
});
```

Kode use case diperbaiki pada `search_announcements.dart`:
```dart
return items.where((item) {
  final matchesTitle = item.title.toLowerCase().contains(trimmedQuery);
  final matchesBody = item.body.toLowerCase().contains(trimmedQuery);
  return matchesTitle || matchesBody;
}).toList();
```

### B. Bukti Temuan 2 (Ditolak): Analisis Pelanggaran Arsitektur
Jika usulan AI diikuti:
1. **Dependency Inversion Violation**: Layer *Presentation* (Widget) menjadi bergantung langsung pada eksekusi domain tanpa melalui State Notifier yang terisolasi.
2. **Performance Degradation**: Di Flutter, method `build()` dapat dipanggil puluhan kali per detik (misalnya saat scrolling, transisi keyboard, atau animasi). Memanggil kalkulasi komparasi string list di dalam `build()` tanpa memoization Riverpod adalah *bad practice*.
3. **Pemisahan 4 Layer Tetap Dipertahankan**:
   - `Widget`: UI & event capture saja.
   - `Notifier`: State reaktif & penghubung.
   - `Use Case`: Aturan pencarian murni (*Pure Dart*).
   - `Repository`: Sumber data (SQLite/Dio).

---

## 5. Bukti Hasil Eksekusi `flutter analyze` & `flutter test`

### Output `flutter analyze`:
```text
Analyzing campus_notify...
No issues found! (ran in 5.1s)
```

### Output `dart format --set-exit-if-changed lib test`:
```text
Formatted 33 files (0 changed) in 0.20 seconds.
```

### Output `flutter test`:
```text
00:02 +9: All tests passed!
```
*(9 unit & widget tests berjalan sukses 100%, membuktikan kebenaran pencarian judul dan isi konten).*
