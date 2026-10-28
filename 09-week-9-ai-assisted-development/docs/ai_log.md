Praktikum 1 dan praktikum 2
Propmt :

tambahkan fitur search pada pengumuman.
arsitektur : presentation> domain < data
jangan panggil sql lite dari widget 
sertakan empty state + 1 widget test

konteks : 

implementasikan pada folder [campus_notify](directory;file:///c%3A/laragon/www/254107023002-mobile-course/254107023002-mobile-course/09-week-9-ai-assisted-development/campus_notify) 

implementasikan didalam section override dan kemudian bedakan classnya di announcement :

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman Kampus')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (announcements) => announcements.isEmpty
            ? const Center(child: Text('Belum ada catatan.'))
            : AnnouncementsList(announcements),
      ),
    );
  }
}


---

Output Awal AI:

1. Kode Implementasi Awal:
- Domain (`search_announcements.dart`):
  Fungsi filter judul: `items.where((item) => item.title.contains(query)).toList();`
- State Provider (`announcement_providers.dart`):
  `final announcementSearchQueryProvider = StateProvider<String>((ref) => '');`
- UI (`announcement_page.dart`):
  Memisahkan kelas `AnnouncementSearchBar` (input pencarian) dan `AnnouncementEmptyView` (tampilan icon `search_off` saat hasil tidak ditemukan).

2. Tiga (3) Test Case Awal:
- Kasus 1 (Cocok): Query `'KRS'` mengembalikan 1 pengumuman yang sesuai.
- Kasus 2 (Kosong): Query `''` mengembalikan seluruh 3 daftar pengumuman.
- Kasus 3 (Tidak Cocok): Query `'Wisuda'` mengembalikan list kosong (memicu empty state).

3. Cara Uji Manual Singkat:
- Query kosong -> Semua pengumuman tampil utuh.
- Query cocok (`'krs'`) -> Hanya pengumuman yang cocok yang tampil.
- Query tidak cocok (`'xyz123'`) -> Menampilkan empty state dengan pesan pengumuman tidak ditemukan.

---

## Praktikum 3: Debug dan Refactor

### Prompt Mentah Praktikum 3:
```text
1. Debug dengan test merah
1. Reproduksi: langkah + input pemicu bug
2. Isolasi: pindah filter ke use case murni
3. Test merah: buat test gagal pembukti bug
4. Perbaiki kecil, jalankan test + analyze
5. Catat akar masalah di docs/ai-log.md
Jangan mengulang prompt fix dong tanpa bukti error atau test gagal.

2. Refactor ke layer yang benar
widget (UI saja)
  -> notifier (state saja)
  -> use case (aturan filter/search)
  -> repository (SQLite / Dio)
```

---

### 1. Debug dengan Test Merah

1. **Reproduksi Masalah**:
   - Kode awal AI menggunakan filter `items.where((item) => item.title.contains(query)).toList()`.
   - Input pemicu bug: Judul `"Jadwal KRS Semester Genap"` dicari dengan kata kunci huruf kecil `"krs"` atau ada spasi tambahan `"  krs  "`.
   - Gejala: Method `.contains()` bawaan Dart bersifat *case-sensitive*, sehingga mengembalikan list kosong (empty state palsu) padahal data tersedia di memori.
2. **Isolasi Logika**:
   - Memindahkan logika filter dari widget/notifier ke Use Case domain murni: `lib/features/announcements/domain/usecases/search_announcements.dart`.
3. **Test Merah (Gagal Pembukti Bug)**:
   - Dibuat unit test pada `test/search_filter_test.dart`:
     ```dart
     test('filter abaikan huruf besar/kecil (case-insensitive)', () {
       final result = searchUseCase(items: sampleAnnouncements, query: 'krs');
       expect(result, hasLength(1));
     });
     ```
   - Pada kode awal AI, pengujian ini berstatus **GAGAL / MERAH** karena `'Jadwal KRS Semester Genap'.contains('krs')` bernilai `false`.
4. **Perbaiki Kecil**:
   - Mengubah logika menjadi murni case-insensitive dan trimmed:
     ```dart
     final trimmedQuery = query.trim().toLowerCase();
     if (trimmedQuery.isEmpty) return items;
     return items.where((item) => item.title.toLowerCase().contains(trimmedQuery)).toList();
     ```
   - Hasil eksekusi `flutter test`, `dart format`, dan `flutter analyze`: **0 issue, 8 tests passed (HIJAU)**.
   - Bukti screenshot verifikasi: `../screenshots/praktikum 3 flutter test dan analyze.jpg`.
5. **Akar Masalah**:
   - AI mengabaikan normalisasi string (`toLowerCase()` dan `trim()`). String comparison di Dart memerlukan konversi eksplisit ke *lowercase*. Selain itu, AI sempat menggunakan `StateProvider` yang sudah usang di versi Riverpod terbaru sehingga perlu direfaktor ke `Notifier`.

---

### 2. Refactor ke Layer yang Benar (Clean Architecture)

Struktur kode direfaktor secara tegas ke dalam 4 layer arsitektur:
1. **Widget (UI Saja)**:
   - Lokasi: `announcement_page.dart` (`AnnouncementsPage`, `AnnouncementSearchBar`, `AnnouncementEmptyView`).
   - Tanggung jawab: Hanya menangani rendering komponen visual, TextField, dan animasi loading/empty. Tidak boleh ada logika filter bisnis dan tidak boleh mengakses database/Dio.
2. **Notifier (State Saja)**:
   - Lokasi: `announcement_providers.dart` (`AnnouncementSearchQueryNotifier`, `announcementSearchQueryProvider`, `filteredAnnouncementsProvider`).
   - Tanggung jawab: Mengelola mutasi state kata kunci (query) secara reaktif dan menghubungkan state dengan Use Case.
3. **Use Case (Aturan Filter / Search)**:
   - Lokasi: `lib/features/announcements/domain/usecases/search_announcements.dart` (`SearchAnnouncements`).
   - Tanggung jawab: Menyimpan aturan bisnis pencarian (normalisasi case-insensitive dan whitespace trimming). Murni kode Dart (Pure Dart), bebas dari ketergantungan Flutter SDK, Riverpod, SQLite, maupun Dio.
4. **Repository (Data Source: SQLite / Dio)**:
   - Lokasi: `announcement_repository.dart` & `announcement_repository_impl.dart`.
   - Tanggung jawab: Mengambil data mentah pengumuman dari local cache (SQLite) atau remote API (Dio). Widget tidak pernah memanggil database atau network secara langsung.
