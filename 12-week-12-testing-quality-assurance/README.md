# 12-week-12-testing-quality-assurance

Modul pembelajaran Minggu ke-12 ini berfokus pada **Testing & Quality Assurance** pada aplikasi mobile Flutter. Modul ini membahas strategi pengujian piramida (*Testing Pyramid*), penulisan *Unit Test* untuk logika dan kasus tepi (*edge cases*) dengan pola *Arrange, Act, Assert* (AAA), pengujian asinkron dan isolasi dependensi menggunakan *Fake Repository*, pengujian tampilan dan interaksi *Widget Test*, pengujian alur menyeluruh (*Integration Test*), serta evaluasi jaminan kualitas perangkat lunak menggunakan *Code Coverage*.

* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Program Studi**: D-IV Teknik Informatika
* **Jurusan**: Teknologi Informasi — Politeknik Negeri Malang

---

## 1. Selamat Datang & Tujuan Pembelajaran

Fitur yang berjalan lancar di satu perangkat belum tentu bebas dari masalah atau regresi saat basis kode berkembang. Codelab ini melatih penulisan pengujian terstruktur untuk memverifikasi perilaku aplikasi, mencegah regresi, dan menjaga kualitas kode secara berkelanjutan.

### Tujuan Pembelajaran:
1. **Menentukan Jenis Pengujian**: Mengidentifikasi bagian aplikasi yang perlu diuji dengan pengujian unit, widget, atau integrasi.
2. **Pengujian Unit & Kasus Tepi**: Menulis pengujian logika bisnis dan validasi masukan mencakup kasus normal, kasus batas, dan kasus kegagalan.
3. **Pengujian Widget**: Menguji antarmuka visual, rendering status reaktif, serta simulasi interaksi pengguna (teks, tap tombol).
4. **Isolasi Dependensi**: Memisahkan sumber data dengan kontrak abstraksi (*abstract interface class*) dan memanfaatkan *Fake Repository* agar pengujian deterministik dan bebas dari fluktuasi jaringan/API nyata.
5. **Pengujian Integrasi & Cakupan Kode**: Menjalankan alur *end-to-end* pada perangkat/emulator serta mengevaluasi cakupan pengujian (*code coverage*) secara kritis.

---

## 2. Strategi Pengujian Aplikasi Flutter

### A. Piramida Pengujian (Testing Pyramid)

```text
       /\
      /  \        Integration Tests (Alur End-to-End pada Perangkat / Emulator)
     /----\       - Menjalankan alur utuh lintas modul
    /      \      - Eksekusi lebih lambat, cakupan paling komprehensif
   / Widget \     Widget Tests (UI Rendering & Interaksi Pengguna)
  /  Tests   \    - Render visual tanpa emulator fisik, cepat
 /------------\   - Memverifikasi tampilan, state, dan event tap/input
/  Unit Tests  \  Unit Tests (Fungsi, Validasi, Aturan Bisnis & Repository)
----------------  - Sangat cepat, terisolasi, mudah diperbaiki & otomatis
```

### B. Karakteristik & Perbandingan Jenis Pengujian

| Jenis Pengujian | Yang Diperiksa | Target Pengujian | Kecepatan & Biaya | Contoh pada `campus_notify` |
|---|---|---|---|---|
| **Unit Test** | Satu fungsi atau objek logika murni tanpa render UI | Aturan validasi, transformasi data, state notifier, service | Sangat Cepat, Biaya Rendah | Validasi judul tugas/pengumuman (`isValidTaskTitle`), parsing entitas |
| **Widget Test** | Tampilan visual dan interaksi satu/beberapa widget | Layout widget, pesan error form, interaksi tap/scroll, empty state | Cepat, Berjalan di Test Environment (tanpa HP) | Form `TaskPage` menampilkan error saat tombol simpan ditekan dengan input kosong |
| **Integration Test** | Alur lengkap aplikasi dari awal hingga akhir (*End-to-End*) | Integrasi UI, navigasi, state, dan repository pada device/emulator | Lambat, Butuh Device/Emulator Aktif | Pengguna membuka aplikasi $\rightarrow$ navigasi ke halaman tugas $\rightarrow$ mengetik judul $\rightarrow$ simpan $\rightarrow$ memverifikasi item muncul di daftar |

### C. Merancang Kode yang Mudah Diuji (Testable Architecture)

Logika bisnis yang bercampur langsung di dalam widget pohon render (*build method*) atau terikat erat ke panggilan HTTP nyata sangat sulit diuji secara terisolasi. Oleh karena itu, prinsip arsitektur yang diterapkan adalah:
1. **Pemisahan Tanggung Jawab (*Separation of Concerns*)**:
   * **Widget**: Hanya menangani presentasi visual dan menangkap interaksi pengguna.
   * **Service / Use Case**: Menangani logika orkestrasi dan validasi bisnis.
   * **Repository**: Menangani komunikasi sumber data (*local storage* atau *remote API*).
2. **Pembalikan Ketergantungan (*Dependency Inversion*)**:
   * Menggunakan kontrak antarmuka (`abstract interface class TaskRepository`).
   * Service dan Widget tidak bergantung pada implementasi konkret, melainkan pada kontrak abstraksi.
   * Pada tahap pengujian, repositori nyata dapat diganti dengan **`FakeTaskRepository`** terkendali yang dapat disimulasikan untuk menghasilkan data sukses maupun memicu pelemparan `Exception`.

---

## 3. Pengujian Unit dan Kasus Tepi

### A. Konsep Pengujian Berdasarkan Perilaku (*Behavior-Driven Testing*)
Pengujian unit memverifikasi bahwa satu fungsi atau unit logika murni berjalan sesuai spesifikasi tanpa bergantung pada rendering antarmuka pengguna (UI) maupun koneksi jaringan eksternal.

Aturan validasi yang diuji:
1. **Judul Tugas Valid**: Judul harus berisi teks setelah spasi di awal dan akhir diabaikan (`trim().isNotEmpty`).
2. **Batas Karakter Form**: Judul minimal 3 karakter dan maksimal 100 karakter.
3. **Deskripsi Tugas**: Deskripsi opsional dengan batas maksimal 500 karakter.

Kode fungsi logika bisnis diimplementasikan pada [`lib/core/validators/task_validator.dart`](campus_notify/lib/core/validators/task_validator.dart):
```dart
class TaskValidator {
  static bool isValidTaskTitle(String value) {
    return value.trim().isNotEmpty;
  }

  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tugas tidak boleh kosong atau hanya spasi';
    }
    if (value.trim().length < 3) {
      return 'Judul tugas minimal harus terdiri dari 3 karakter';
    }
    if (value.trim().length > 100) {
      return 'Judul tugas maksimal 100 karakter';
    }
    return null;
  }

  static bool isValidTaskDescription(String value, {int maxLength = 500}) {
    return value.trim().length <= maxLength;
  }
}

bool isValidTaskTitle(String value) => TaskValidator.isValidTaskTitle(value);
```

### B. Pola Arrange, Act, Assert (AAA)
Struktur pengujian unit disusun secara konsisten mengikuti pola standar industri:
* **Arrange**: Menyiapkan data masukan, konfigurasi batas, atau objek yang dibutuhkan.
* **Act**: Menjalankan fungsi atau memicu aksi yang diuji.
* **Assert**: Memverifikasi hasil keluaran dengan mencocokkan ekspektasi menggunakan `expect()`.

### C. Pengujian Kasus Tepi (*Edge Cases*) dan Nilai Batas (*Boundary Values*)
Pengujian tidak boleh hanya memeriksa kasus sukses yang diperkirakan berhasil (*happy path*), melainkan wajib menguji skenario batas di mana bug sering terjadi.

File pengujian diimplementasikan pada [`test/is_valid_task_title_test.dart`](campus_notify/test/is_valid_task_title_test.dart):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/validators/task_validator.dart';

void main() {
  group('isValidTaskTitle', () {
    test('menerima judul yang berisi teks', () {
      // Arrange
      const title = 'Belajar Flutter Testing';

      // Act
      final result = isValidTaskTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      // Kasus Tepi: string kosong, spasi berulang, tab/newline
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
      expect(isValidTaskTitle('\t\n'), isFalse);
    });

    test('menerima judul dengan spasi di awal atau akhir', () {
      const titleWithPadding = '   Tugas Mobile Week 12   ';
      expect(isValidTaskTitle(titleWithPadding), isTrue);
    });
  });

  group('TaskValidator.validateTaskTitle - Kasus Tepi dan Nilai Batas', () {
    test('mengembalikan error jika input null', () {
      expect(
        TaskValidator.validateTaskTitle(null),
        equals('Judul tugas tidak boleh kosong atau hanya spasi'),
      );
    });

    test('mengembalikan error jika input kosong atau hanya spasi', () {
      expect(
        TaskValidator.validateTaskTitle(''),
        equals('Judul tugas tidak boleh kosong atau hanya spasi'),
      );
      expect(
        TaskValidator.validateTaskTitle('     '),
        equals('Judul tugas tidak boleh kosong atau hanya spasi'),
      );
    });

    test('menolak masukan di bawah batas minimum (< 3 karakter)', () {
      // Kasus Batas Bawah: 2 karakter ditolak
      expect(
        TaskValidator.validateTaskTitle('AB'),
        equals('Judul tugas minimal harus terdiri dari 3 karakter'),
      );
    });

    test('menolak masukan di atas batas maksimum (> 100 karakter)', () {
      // Kasus Batas Atas: 101 karakter ditolak
      final longTitle = 'A' * 101;
      expect(
        TaskValidator.validateTaskTitle(longTitle),
        equals('Judul tugas maksimal 100 karakter'),
      );
    });

    test('menerima masukan tepat pada batas minimum dan maksimum', () {
      // Tepat 3 karakter (diterima)
      expect(TaskValidator.validateTaskTitle('ABC'), isNull);

      // Tepat 100 karakter (diterima)
      expect(TaskValidator.validateTaskTitle('A' * 100), isNull);
    });
  });

  group('TaskValidator.isValidTaskDescription', () {
    test('menerima deskripsi normal dan kosong', () {
      expect(TaskValidator.isValidTaskDescription(''), isTrue);
      expect(
        TaskValidator.isValidTaskDescription('Deskripsi pengerjaan praktikum'),
        isTrue,
      );
    });

    test('menolak deskripsi yang melebihi batas 500 karakter', () {
      final oversizedDescription = 'D' * 501;
      expect(
        TaskValidator.isValidTaskDescription(oversizedDescription),
        isFalse,
      );
    });
  });
}
```

---

## 4. Menguji Kode Asinkron dan Dependensi

### A. Mengapa Menghindari API / Jaringan Sungguhan dalam Pengujian?
Mengandalkan endpoint server nyata atau koneksi internet pada pengujian unit memiliki kelemahan fatal:
1. **Fluktuasi Jaringan (*Flaky Tests*)**: Pengujian bisa mendadak gagal karena timeout atau koneksi lambat, bukan karena bug pada kode aplikasi.
2. **Ketergantungan Data Eksternal**: Data pada server dapat berubah sewaktu-waktu oleh pengguna lain.
3. **Eksekusi Lambat**: Melakukan handshake TCP dan latency HTTP membuat test suite memakan waktu lama.
4. **Biaya & Batasan Kuota**: Permintaan berulang dapat menghabiskan kuota rate limit API.

### B. Kontrak Sumber Data (*Interface*) & Layanan Bisnis
Sesuai prinsip *Dependency Inversion*, dibuat kontrak abstraksi pada [`lib/features/tasks/domain/repositories/task_repository.dart`](campus_notify/lib/features/tasks/domain/repositories/task_repository.dart):
```dart
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<void> addTask(String title);
}
```

Layanan bisnis [`lib/features/tasks/domain/services/task_service.dart`](campus_notify/lib/features/tasks/domain/services/task_service.dart) hanya bergantung pada kontrak di atas:
```dart
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  Future<void> saveTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Judul tugas tidak boleh kosong.');
    }
    await _repository.addTask(trimmed);
  }
}
```

### C. Implementasi Fake Repository
*Fake* adalah objek pengganti tiruan yang memiliki implementasi kerja yang disederhanakan dan perilakunya dapat dikendalikan penuh oleh berkas pengujian.

File pengujian diimplementasikan pada [`test/task_service_test.dart`](campus_notify/test/task_service_test.dart):
```dart
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
```

### D. Pengujian Kasus Sukses dan Penanganan Kegagalan (*Error Handling*)
1. **Pengujian Alur Sukses**:
   Memastikan `TaskService` dapat meneruskan daftar data secara utuh dari repositori.
2. **Pengujian Alur Error**:
   Memastikan bahwa ketika terjadi error (misalnya `ServerException`), exception tersebut dilempar secara transparan dan **tidak disamarkan secara diam-diam menjadi daftar kosong**. Penanganan kegagalan yang tepat adalah kunci ketahanan aplikasi.

```dart
void main() {
  group('TaskService dengan FakeTaskRepository', () {
    test('meneruskan data dari repository saat sukses', () async {
      final fakeRepo = FakeTaskRepository(
        tasks: ['Baca materi Flutter Testing', 'Kerjakan Codelab Week 12'],
      );
      final service = TaskService(fakeRepo);

      final result = await service.loadTasks();

      expect(result, equals(['Baca materi Flutter Testing', 'Kerjakan Codelab Week 12']));
    });

    test('melempar exception saat repository gagal (error tidak diam-diam menjadi daftar kosong)', () async {
      final fakeRepo = FakeTaskRepository(
        error: const ServerException('500 Internal Server Error'),
      );
      final service = TaskService(fakeRepo);

      expect(
        () => service.loadTasks(),
        throwsA(isA<ServerException>()),
      );
    });

    test('berhasil menyimpan tugas baru dan menambahkannya ke repository', () async {
      final fakeRepo = FakeTaskRepository(tasks: []);
      final service = TaskService(fakeRepo);

      await service.saveTask('Persiapan Presentasi Akhir');

      final tasks = await service.loadTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first, equals('Persiapan Presentasi Akhir'));
    });

    test('menolak penyimpanan jika judul tugas hanya berupa spasi kosong', () async {
      final fakeRepo = FakeTaskRepository();
      final service = TaskService(fakeRepo);

      expect(
        () => service.saveTask('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(await fakeRepo.getTasks(), isEmpty);
    });
  });
}
```

---

## 5. Pengujian Widget (Widget Testing)

### A. Konsep Pengujian Antarmuka Pengguna
Pengujian widget memverifikasi tampilan visual dan interaksi pengguna pada satu atau beberapa widget tanpa perlu menjalankan aplikasi pada emulator atau perangkat fisik Android yang lambat. Pengujian ini berjalan pada lingkungan *headless* yang sangat cepat menggunakan `WidgetTester`.

Metode utama yang digunakan:
1. **`tester.pumpWidget()`**: Merender pohon widget ke lingkungan pengujian.
2. **`find`**: Menemukan elemen berdasarkan teks (`find.text`), tipe (`find.byType`), atau kunci identitas (`find.byKey`).
3. **`tester.enterText()`**: Memasukkan nilai teks ke dalam field input (`TextFormField`).
4. **`tester.tap()`**: Meniru ketukan jari pengguna pada tombol (`ElevatedButton`).
5. **`tester.pumpAndSettle()`**: Memompa frame berulang hingga seluruh animasi, transisi, dan microtask selesai secara deterministik (menghindari penggunaan `Future.delayed` statis).

### B. Desain Widget Ramah Pengujian (*Test-Friendly Design*)
Halaman tugas diimplementasikan pada [`lib/features/tasks/presentation/pages/task_page.dart`](campus_notify/lib/features/tasks/presentation/pages/task_page.dart) dengan menyertakan atribut `Key` eksplisit:
* `Key('task-title-field')`: Input field judul tugas.
* `Key('save-task-button')`: Tombol simpan tugas.
* `Key('task-list-view')`: Kontainer ListView daftar tugas.

### C. Skenario Pengujian Widget
Berkas pengujian diimplementasikan pada [`test/task_page_widget_test.dart`](campus_notify/test/task_page_widget_test.dart) mencakup 5 skenario penting:
1. **Tampilan Awal (*Initial State*)**: Memverifikasi judul halaman `'Daftar Tugas Kampus'`, keberadaan input field dan tombol simpan, serta teks kondisi kosong (`'Belum ada tugas'`).
2. **Validasi Masukan Kosong (*Validation Error*)**: Menekan tombol simpan dengan field kosong memicu pesan validasi `'Judul tugas tidak boleh kosong atau hanya spasi'`.
3. **Validasi Batas Karakter**: Mengetik kurang dari 3 karakter (`'AB'`) memicu pesan error `'Judul tugas minimal harus terdiri dari 3 karakter'`.
4. **Interaksi Pengguna Sukses (*Happy Path Interaction*)**: Memasukkan teks `'Baca materi testing Flutter'`, menekan tombol simpan, memompa frame (`pumpAndSettle`), lalu memverifikasi bahwa item muncul di layar dan *empty state* menghilang.
5. **Daftar dengan Data Awal**: Memastikan parameter `initialTasks` dirender dengan benar.

```dart
void main() {
  group('TaskPage Widget Tests', () {
    testWidgets('menampilkan judul halaman dan tampilan awal kosong (empty state)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TaskPage()),
      );

      expect(find.text('Daftar Tugas Kampus'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsOneWidget);
      expect(find.byKey(const Key('task-title-field')), findsOneWidget);
      expect(find.byKey(const Key('save-task-button')), findsOneWidget);
    });

    testWidgets('menampilkan pesan validasi saat tombol simpan ditekan dengan input kosong', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TaskPage()),
      );

      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Judul tugas tidak boleh kosong atau hanya spasi'),
        findsOneWidget,
      );
      expect(find.text('Belum ada tugas'), findsOneWidget);
    });

    testWidgets('pengguna dapat memasukkan judul tugas dan melihatnya muncul di daftar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TaskPage()),
      );

      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi testing Flutter',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Baca materi testing Flutter'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsNothing);
    });
  });
}
```



