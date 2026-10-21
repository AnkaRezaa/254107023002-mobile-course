import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class AddAnnouncement {
  final AnnouncementRepository _repository;

  const AddAnnouncement(this._repository);

  Future<({Announcement? announcement, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return (
        announcement: null,
        failure: const LocalFailure('Judul pengumuman tidak boleh kosong'),
      );
    }
    return _repository.addAnnouncement(title: trimmed, body: body.trim());
  }
}
