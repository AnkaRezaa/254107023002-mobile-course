import '../../domain/entities/announcement.dart';
import '../../../../core/failures.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})> fetchAnnouncements();
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement({
    required String title,
    String body = '',
  });
}