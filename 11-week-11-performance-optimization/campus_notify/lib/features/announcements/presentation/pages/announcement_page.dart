import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredState = ref.watch(filteredAnnouncementsProvider);
    final query = ref.watch(announcementSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman Kampus')),
      body: Column(
        children: [
          const AnnouncementSearchBar(),
          Expanded(
            child: filteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(announcementsProvider),
              ),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return AnnouncementEmptyView(query: query);
                }
                return AnnouncementsList(announcements);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementSearchBar extends ConsumerStatefulWidget {
  const AnnouncementSearchBar({super.key});

  @override
  ConsumerState<AnnouncementSearchBar> createState() =>
      _AnnouncementSearchBarState();
}

class _AnnouncementSearchBarState extends ConsumerState<AnnouncementSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(announcementSearchQueryProvider);
    if (_controller.text != query) {
      _controller.text = query;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(announcementSearchQueryProvider.notifier).updateQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Cari judul pengumuman...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(announcementSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class AnnouncementEmptyView extends StatelessWidget {
  const AnnouncementEmptyView({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearching = query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Pengumuman tidak ditemukan'
                  : 'Belum ada pengumuman.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Tidak ada pengumuman yang cocok dengan "$query". Coba kata kunci lain.'
                  : 'Saat ini belum ada pengumuman yang diterbitkan kampus.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
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
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
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
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.body),
          ),
        );
      },
    );
  }
}
