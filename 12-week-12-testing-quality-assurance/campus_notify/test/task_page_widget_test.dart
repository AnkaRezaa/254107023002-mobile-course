import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/tasks/presentation/pages/task_page.dart';

void main() {
  group('TaskPage Widget Tests', () {
    testWidgets('menampilkan judul halaman dan tampilan awal kosong (empty state)', (tester) async {
      // Arrange & Act: render widget
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(),
        ),
      );

      // Assert: periksa elemen UI awal
      expect(find.text('Daftar Tugas Kampus'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsOneWidget);
      expect(find.byKey(const Key('task-title-field')), findsOneWidget);
      expect(find.byKey(const Key('save-task-button')), findsOneWidget);
    });

    testWidgets('menampilkan pesan validasi saat tombol simpan ditekan dengan input kosong', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(),
        ),
      );

      // Act: tekan tombol simpan tanpa mengisi judul
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert: pesan error validasi muncul dan daftar tetap kosong
      expect(
        find.text('Judul tugas tidak boleh kosong atau hanya spasi'),
        findsOneWidget,
      );
      expect(find.text('Belum ada tugas'), findsOneWidget);
    });

    testWidgets('menolak judul yang kurang dari 3 karakter dan menampilkan pesan error', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(),
        ),
      );

      // Act: ketik hanya 2 karakter lalu tap simpan
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'AB',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert: pesan batas minimum muncul
      expect(
        find.text('Judul tugas minimal harus terdiri dari 3 karakter'),
        findsOneWidget,
      );
    });

    testWidgets('pengguna dapat memasukkan judul tugas dan melihatnya muncul di daftar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(),
        ),
      );

      // Act: masukkan teks pada form input dan tekan simpan
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi testing Flutter',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert: tugas baru tampil di layar, status kosong hilang
      expect(find.text('Baca materi testing Flutter'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsNothing);

      // Tambahkan tugas kedua untuk memastikan rendering list bertambah
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Praktikum Widget Testing',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Praktikum Widget Testing'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('menampilkan daftar tugas awal jika diberikan via parameter initialTasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(
            initialTasks: ['Tugas Review 1', 'Tugas Review 2'],
          ),
        ),
      );

      // Assert
      expect(find.text('Tugas Review 1'), findsOneWidget);
      expect(find.text('Tugas Review 2'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsNothing);
    });
  });
}
