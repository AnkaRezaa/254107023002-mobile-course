import '../repositories/task_repository.dart';

/// Layanan bisnis tugas yang bergantung secara eksklusif pada abstraksi TaskRepository.
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  /// Memuat daftar tugas dari repositori.
  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  /// Menyimpan tugas baru setelah memvalidasi masukan.
  Future<void> saveTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Judul tugas tidak boleh kosong.');
    }
    await _repository.addTask(trimmed);
  }
}

