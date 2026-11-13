import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  // In-memory cache untuk strategi Stale-While-Revalidate (SWR)
  List<Announcement>? _cachedAnnouncements;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

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
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements({bool forceRefresh = false}) async {
    // Optimasi SWR: Sajikan langsung dari cache jika masih segar dan tidak force refresh
    final isCacheValid = _cachedAnnouncements != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration;

    if (!forceRefresh && isCacheValid) {
      return (announcements: _cachedAnnouncements!, failure: null);
    }

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final items = _mockData.map((m) => m.toEntity()).toList();
      _cachedAnnouncements = items;
      _lastFetchTime = DateTime.now();
      return (announcements: items, failure: null);
    } catch (e) {
      // Fallback SWR: Jika network gagal tapi cache lama ada, kembalikan data cache
      if (_cachedAnnouncements != null) {
        return (announcements: _cachedAnnouncements!, failure: null);
      }
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
      _cachedAnnouncements = null; // Invalidate cache agar fresh
      return (announcement: newModel.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal menyimpan pengumuman: $e'),
      );
    }
  }
}
