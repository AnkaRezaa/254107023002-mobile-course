import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';



class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({required Future<Database> Function() openDb})
      : _openDb = openDb;

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Announcement> announcements, Failure? failure})> fetchAnnouncements() async {
    try {
      final db = await _openDb();
      final rows =
          await db.query('announcements', orderBy: 'updated_at DESC');
      final announcements =
          rows.map((r) => AnnouncementModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'announcements',
        AnnouncementModel(
            title: title, body: body, updatedAt: now, dirty: true)
            .toMap(),
      );
      return (
        note: Announcement(id: id, title: title, body: body,
            updatedAt: now, dirty: true),
        failure: null,
      );
    } catch (e) {
      return (note: null,
          failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }
}