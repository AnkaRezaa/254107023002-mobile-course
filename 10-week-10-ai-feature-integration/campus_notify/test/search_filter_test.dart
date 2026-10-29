import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/usecases/search_announcements.dart';

void main() {
  final sampleAnnouncements = [
    Announcement(
      id: 1,
      title: 'Jadwal KRS Semester Genap',
      body: 'Pengisian KRS dibuka mulai 1 Februari.',
      updatedAt: DateTime(2026, 1, 15),
    ),
    Announcement(
      id: 2,
      title: 'Beasiswa Prestasi Akademik 2026',
      body: 'Pendaftaran beasiswa dapat diakses di portal.',
      updatedAt: DateTime(2026, 1, 20),
    ),
    Announcement(
      id: 3,
      title: 'Pengumuman Libur Nasional',
      body: 'Kegiatan perkuliahan diliburkan pada hari Senin.',
      updatedAt: DateTime(2026, 2, 1),
    ),
  ];

  const searchUseCase = SearchAnnouncements();

  group('SearchAnnouncements Use Case Tests', () {
    test('filter abaikan huruf besar/kecil (case-insensitive)', () {
      final result = searchUseCase(items: sampleAnnouncements, query: 'krs');
      expect(result, hasLength(1));
      expect(result.first.title, 'Jadwal KRS Semester Genap');
    });

    test('filter menangani spasi berlebih dengan trim()', () {
      final result = searchUseCase(
        items: sampleAnnouncements,
        query: '   beasiswa   ',
      );
      expect(result, hasLength(1));
      expect(result.first.title, contains('Beasiswa'));
    });

    test('pencarian menemukan pengumuman berdasarkan isi konten (body)', () {
      final result = searchUseCase(
        items: sampleAnnouncements,
        query: 'perkuliahan',
      );
      expect(result, hasLength(1));
      expect(result.first.id, 3);
      expect(result.first.body, contains('perkuliahan'));
    });

    test('query kosong mengembalikan seluruh data pengumuman', () {
      final result = searchUseCase(items: sampleAnnouncements, query: '');
      expect(result, hasLength(3));
    });

    test('query tak cocok kembalikan kosong', () {
      final result = searchUseCase(
        items: sampleAnnouncements,
        query: 'zzz-tak-ada',
      );
      expect(result, isEmpty);
    });
  });
}
