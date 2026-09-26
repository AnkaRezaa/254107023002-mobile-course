import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local/post.dart';
import 'network_provider.dart';

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(PostsNotifier.new);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final forceOffline = ref.watch(forceOfflineProvider);
    final repo = ref.watch(postRepositoryProvider);

    // Tampilkan cache lokal terlebih dahulu
    final cached = await repo.readCachedPosts();

    // Trigger update background
    _fetchFreshData(forceOffline);

    return cached;
  }

  Future<void> _fetchFreshData(bool forceOffline) async {
    if (forceOffline) return;
    try {
      final repo = ref.read(postRepositoryProvider);
      await repo.refreshPostsInBackground(forceOffline: forceOffline);
      // Update state jika data berhasil diambil dari API
      final updated = await repo.readCachedPosts();
      state = AsyncValue.data(updated);
    } catch (_) {
      // Jaringan error/offline: Tetap gunakan data cache yang ada
    }
  }

  Future<void> refreshManually() async {
    state = const AsyncLoading();
    final forceOffline = ref.read(forceOfflineProvider);
    final repo = ref.read(postRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.refreshPostsInBackground(forceOffline: forceOffline);
      return repo.readCachedPosts();
    });
  }
}