import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final List<AnnouncementModel> _mockData = [
    AnnouncementModel(
      id: 101,
      title: 'Pengumuman Akademik #101',
      body: 'Jadwal KRS dan perkuliahan semester baru.',
      updatedAt: DateTime.now(),
      dirty: false,
    ),
    AnnouncementModel(
      id: 3,
      title: 'Pengumuman Rektorat #3',
      body: 'Sosialisasi beasiswa dan kegiatan akademik kampus.',
      updatedAt: DateTime.now(),
      dirty: false,
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchAnnouncements() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final items = _mockData.map((m) => m.toEntity()).toList();
      return (announcements: items, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal membaca pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> addAnnouncement({
    required String title,
    String body = '',
  }) async {
    try {
      final now = DateTime.now();
      final newModel = AnnouncementModel(
        id: _mockData.length + 1,
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      _mockData.add(newModel);
      return (announcement: newModel.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal menyimpan pengumuman: $e'),
      );
    }
  }
}
