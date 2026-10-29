import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/features/chat/chat_screen.dart';

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('menampilkan komponen header, banner privasi, dan pesan sambutan', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Tunggu hingga frame selesai
      await tester.pump();

      // Memastikan judul AppBar tampil
      expect(find.text('Tanya Asisten Kampus'), findsOneWidget);
      expect(find.textContaining('Didukung AI Gemini'), findsOneWidget);

      // Memastikan catatan perlindungan privasi tampil
      expect(
        find.textContaining('Privasi Terjaga: Sistem memproteksi NIK'),
        findsOneWidget,
      );

      // Memastikan pesan sambutan dari asisten tampil
      expect(
        find.textContaining('Halo! Saya Asisten AI Kampus.'),
        findsOneWidget,
      );

      // Memastikan TextField input pencarian & tombol kirim ada
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}

