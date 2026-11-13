import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/tasks/domain/repositories/task_repository.dart';
import 'package:campus_notify/features/tasks/domain/services/task_service.dart';

/// Implementasi Fake Repository untuk kebutuhan pengujian terisolasi.
/// Memungkinkan pengujian mengendalikan kondisi data sukses maupun kegagalan
/// tanpa bergantung pada koneksi internet atau server eksternal.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<String>? tasks, this.error})
      : _tasks = tasks != null ? List.from(tasks) : [];

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    if (error != null) throw error!;
    _tasks.add(title);
  }
}

/// Exception kustom untuk simulasi kegagalan server
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

void main() {
  group('TaskService dengan FakeTaskRepository', () {
    test('meneruskan data dari repository saat sukses', () async {
      // Arrange: siapkan fake repository dengan data terkendali
      final fakeRepo = FakeTaskRepository(
        tasks: ['Baca materi Flutter Testing', 'Kerjakan Codelab Week 12'],
      );
      final service = TaskService(fakeRepo);

      // Act: panggil metode pemuatan data
      final result = await service.loadTasks();

      // Assert: verifikasi data yang diterima sesuai ekspektasi
      expect(result, equals(['Baca materi Flutter Testing', 'Kerjakan Codelab Week 12']));
    });

    test('melempar exception saat repository gagal (error tidak diam-diam menjadi daftar kosong)', () async {
      // Arrange: siapkan fake repository yang diatur melempar error
      final fakeRepo = FakeTaskRepository(
        error: const ServerException('500 Internal Server Error'),
      );
      final service = TaskService(fakeRepo);

      // Act & Assert: pastikan pemanggilan fungsi melempar exception dan tidak disamarkan
      expect(
        () => service.loadTasks(),
        throwsA(isA<ServerException>()),
      );
    });

    test('berhasil menyimpan tugas baru dan menambahkannya ke repository', () async {
      // Arrange: repositori awal kosong
      final fakeRepo = FakeTaskRepository(tasks: []);
      final service = TaskService(fakeRepo);

      // Act: simpan tugas baru
      await service.saveTask('Persiapan Presentasi Akhir');

      // Assert: pastikan tugas tersimpan di repositori
      final tasks = await service.loadTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first, equals('Persiapan Presentasi Akhir'));
    });

    test('menolak penyimpanan jika judul tugas hanya berupa spasi kosong', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository();
      final service = TaskService(fakeRepo);

      // Act & Assert: melempar ArgumentError sebelum memanggil repositori
      expect(
        () => service.saveTask('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(await fakeRepo.getTasks(), isEmpty);
    });
  });
}
