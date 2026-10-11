import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';
import '../../domain/entities/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcements;
});
