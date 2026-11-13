/// Kontrak abstraksi sumber data tugas (Clean Architecture / Dependency Inversion).
/// Memisahkan antarmuka logika bisnis dari implementasi jaringan atau database nyata.
abstract interface class TaskRepository {
  /// Mengambil seluruh daftar tugas secara asinkron.
  Future<List<String>> getTasks();

  /// Menambahkan tugas baru ke dalam repositori.
  Future<void> addTask(String title);
}

