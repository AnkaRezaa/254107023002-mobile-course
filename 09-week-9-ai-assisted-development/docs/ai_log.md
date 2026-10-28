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
