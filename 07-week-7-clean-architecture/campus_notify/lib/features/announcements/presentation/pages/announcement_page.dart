import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
      ),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
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

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsList extends StatelessWidget {
  const AnnouncementsList(this.announcements, {super.key});
  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final item = announcements[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.campaign, color: Colors.deepPurple),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.body),
          ),
        );
      },
    );
  }
}
