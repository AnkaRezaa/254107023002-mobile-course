import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('GetAnnouncements meneruskan daftar pengumuman dari repository', () async {
    final repo = FakeAnnouncementRepository(items: [
      Announcement(
        id: 1,
        title: 'Pengumuman Akademik',
        body: 'Jadwal KRS Semester Ganjil',
        updatedAt: DateTime(2026, 9, 27),
      ),
    ]);
    final result = await GetAnnouncements(repo).call();
    expect(result.failure, isNull);
    expect(result.announcements.length, 1);
    expect(result.announcements.first.title, 'Pengumuman Akademik');
  });

  test('GetAnnouncements meneruskan failure tanpa melempar exception', () async {
    final repo = FakeAnnouncementRepository(fail: true);
    final result = await GetAnnouncements(repo).call();
    expect(result.failure, isA<LocalFailure>());
    expect(result.announcements, isEmpty);
  });
}
