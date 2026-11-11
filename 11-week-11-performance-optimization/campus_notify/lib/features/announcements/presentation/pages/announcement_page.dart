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

class AnnouncementsList extends StatefulWidget {
  const AnnouncementsList(this.announcements, {super.key});
  final List<Announcement> announcements;

  @override
  State<AnnouncementsList> createState() => _AnnouncementsListState();
}

class _AnnouncementsListState extends State<AnnouncementsList> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _visibleCount =
        widget.announcements.length > 10 ? 10 : widget.announcements.length;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant AnnouncementsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcements.length != widget.announcements.length) {
      _visibleCount =
          widget.announcements.length > 10 ? 10 : widget.announcements.length;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _visibleCount < widget.announcements.length) {
      setState(() {
        _isLoadingMore = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _visibleCount =
                (_visibleCount + 5).clamp(0, widget.announcements.length);
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.announcements.take(_visibleCount).toList();

    return ListView.builder(
      controller: _scrollController,
      itemCount: displayItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return RepaintBoundary(
          child: AnnouncementTile(announcement: displayItems[index]),
        );
      },
    );
  }
}

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.deepPurple),
        title: Text(
          announcement.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(announcement.body),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(announcement.title),
              content: Text(announcement.body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
