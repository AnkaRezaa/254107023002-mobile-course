import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/add_announcement.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  final List<Announcement> items = [];

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchAnnouncements() async {
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement({
    required String title,
    String body = '',
  }) async {
    final newAnnouncement = Announcement(
      id: items.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    items.add(newAnnouncement);
    return (announcement: newAnnouncement, failure: null);
  }
}

void main() {
  late FakeAnnouncementRepository repository;
  late AddAnnouncement useCase;

  setUp(() {
    repository = FakeAnnouncementRepository();
    useCase = AddAnnouncement(repository);
  });

  test('mengembalikan LocalFailure saat judul pengumuman kosong', () async {
    final result = await useCase(title: '   ');
    expect(result.failure, isA<LocalFailure>());
    expect(result.failure?.message, 'Judul pengumuman tidak boleh kosong');
    expect(result.announcement, isNull);
    expect(repository.items, isEmpty);
  });

  test('berhasil menambahkan pengumuman baru saat judul valid', () async {
    final result = await useCase(
      title: 'Kuliah Tamu Mobile AI',
      body: 'Ruang Multimedia Lt. 3',
    );
    expect(result.failure, isNull);
    expect(result.announcement?.title, 'Kuliah Tamu Mobile AI');
    expect(repository.items.length, 1);
  });
}
