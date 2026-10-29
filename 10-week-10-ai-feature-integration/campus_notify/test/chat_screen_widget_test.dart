import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_notify/features/chat/chat_screen.dart';
import 'package:campus_notify/features/chat/providers/chat_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test_api_key'});

  group('ChatScreen Widget Tests', () {
    testWidgets('menampilkan header, kuota, banner privasi, tombol kamera OCR, dan mikrofon STT', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Judul AppBar
      expect(find.text('Tanya Asisten Kampus'), findsOneWidget);
      expect(find.textContaining('Didukung AI Gemini'), findsOneWidget);

      // Banner Kuota & Privasi Terintegrasi
      expect(find.textContaining('Sisa Kuota: 20/20'), findsOneWidget);
      expect(
        find.textContaining('Privasi Terjaga: Sistem memproteksi NIK'),
        findsOneWidget,
      );

      // Pesan Sambutan Terintegrasi
      expect(
        find.textContaining('Halo! Saya Asisten AI Kampus terintegrasi.'),
        findsOneWidget,
      );

      // Input Bar Terintegrasi: Kamera OCR, TextField, Mic STT, dan Kirim
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('dapat beralih ke Mode Offline dan menampilkan banner offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Klik tombol alih Mode Offline di AppBar
      await tester.tap(find.byIcon(Icons.cloud_queue));
      await tester.pumpAndSettle();

      // Banner mode offline harus tampil
      expect(find.textContaining('Mode Offline Aktif'), findsWidgets);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('menampilkan AlertDialog Layanan AI Sibuk dan tombol fallback offline', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Trigger state shouldShowFallbackDialog = true
      final notifier = container.read(chatNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        shouldShowFallbackDialog: true,
        errorMessage: 'Layanan AI Sibuk',
      );

      await tester.pumpAndSettle();

      // Dialog Fallback harus muncul di layar
      expect(find.text('Layanan AI Sibuk'), findsOneWidget);
      expect(
        find.text('Coba lagi nanti atau gunakan mode offline.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Gunakan Mode Offline'), findsOneWidget);

      // Tekan tombol Gunakan Mode Offline pada dialog
      await tester.tap(find.text('Gunakan Mode Offline'));
      await tester.pumpAndSettle();

      // Dialog tertutup dan pesan fallback lokal kampus ditambahkan
      expect(find.text('Layanan AI Sibuk'), findsNothing);
      expect(find.textContaining('Mode Offline — Data Lokal Kampus'), findsOneWidget);
    });
  });
}
