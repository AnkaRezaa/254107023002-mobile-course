import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';
import '../../domain/usecases/search_announcements.dart';
import '../../domain/entities/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

final searchAnnouncementsProvider = Provider<SearchAnnouncements>((ref) {
  return const SearchAnnouncements();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcements;
});

class AnnouncementSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final announcementSearchQueryProvider =
    NotifierProvider<AnnouncementSearchQueryNotifier, String>(
      AnnouncementSearchQueryNotifier.new,
    );

final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((
  ref,
) {
  final announcementsAsync = ref.watch(announcementsProvider);
  final query = ref.watch(announcementSearchQueryProvider);
  final searchUseCase = ref.watch(searchAnnouncementsProvider);

  return announcementsAsync.whenData((list) {
    return searchUseCase(items: list, query: query);
  });
});
