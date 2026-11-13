import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_notify/features/tasks/presentation/pages/task_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Integration Tests - Fitur Tugas Kampus', () {
    testWidgets('alur lengkap: pengguna memasukkan tugas baru dan memverifikasi keberadaannya di daftar', (tester) async {
      // 1. Bangun antarmuka aplikasi pada lingkungan integrasi
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Verifikasi state awal aplikasi
      expect(find.text('Daftar Tugas Kampus'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsOneWidget);

      // 3. Masukkan teks tugas melalui field ber-Key
      final titleField = find.byKey(const Key('task-title-field'));
      final saveButton = find.byKey(const Key('save-task-button'));

      await tester.enterText(titleField, 'Menyelesaikan Laporan Praktikum Week 12');
      await tester.pumpAndSettle();

      // 4. Tekan tombol simpan
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 5. Verifikasi bahwa data berhasil masuk ke daftar
      expect(find.text('Menyelesaikan Laporan Praktikum Week 12'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsNothing);

      // 6. Masukkan tugas kedua untuk memastikan rendering list dinamis berintegrasi utuh
      await tester.enterText(titleField, 'Persiapan Demo Pengujian Perangkat Bergerak');
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Persiapan Demo Pengujian Perangkat Bergerak'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });
  });
}
