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
