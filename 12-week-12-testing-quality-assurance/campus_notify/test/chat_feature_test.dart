import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_notify/features/chat/models/chat_message.dart';
import 'package:campus_notify/features/chat/providers/chat_providers.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/ai/local_knowledge_base.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test_key'});

  group('Chat Feature Integrated Unit Tests', () {
    test('ChatMessage model menginisialisasi properti teks dan gambar dengan benar', () {
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Kapan jadwal ujian semester?',
        isUser: true,
        timestamp: DateTime(2026, 10, 29, 10, 0),
        isLoading: false,
        imagePath: '/path/to/ktm.jpg',
      );

      expect(msg.id, 'msg_1');
      expect(msg.text, 'Kapan jadwal ujian semester?');
      expect(msg.isUser, isTrue);
      expect(msg.isLoading, isFalse);
      expect(msg.imagePath, '/path/to/ktm.jpg');

      final updated = msg.copyWith(isLoading: true, text: 'Pertanyaan diubah');
      expect(updated.isLoading, isTrue);
      expect(updated.text, 'Pertanyaan diubah');
      expect(updated.imagePath, '/path/to/ktm.jpg');
    });

    test('ChatNotifier memiliki pesan sambutan awal saat pertama dibuka', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chatNotifierProvider);
      expect(state.messages, isNotEmpty);
      expect(state.messages.first.id, 'welcome');
      expect(state.messages.first.isUser, isFalse);
      expect(state.messages.first.text, contains('Asisten AI Kampus terintegrasi'));
    });

    // ================= 1. PRIVASI: Filter Guardrails =================
    test('Filter privasi mendeteksi dan menolak pengiriman NIK ke AI API', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      const sensitiveText = 'Tolong cek data mahasiswa dengan NIK 3507112233440001';
      await notifier.sendMessage(sensitiveText);

      final state = container.read(chatNotifierProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Peringatan Keamanan'));
      expect(lastMsg.text, contains('data sensitif'));
      expect(lastMsg.isUser, isFalse);
    });

    test('Filter privasi mendeteksi dan menolak email dan password sensitif', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      await notifier.sendMessage('Email saya mahasiswa@polinema.ac.id dengan kata sandi rahasia123');

      final state = container.read(chatNotifierProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Peringatan Keamanan'));
      expect(lastMsg.text, contains('Kata Sandi'));
    });

    // ================= 2. BIAYA: Mode Offline & Data Lokal =================
    test('Mode Offline menjawab langsung dari basis pengetahuan lokal kampus', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      notifier.toggleOfflineMode();

      expect(container.read(chatNotifierProvider).isOfflineMode, isTrue);

      await notifier.sendMessage('Kapan batas akhir pengisian KRS?');

      final state = container.read(chatNotifierProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Pangkalan Data Offline Kampus'));
      expect(lastMsg.text, contains('Portal Akademik'));
    });

    // ================= 3. BIAYA: Batasan Kuota Harian =================
    test('Blokir permintaan saat batas kuota harian habis', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(dailyQuotaRemaining: 0);

      await notifier.sendMessage('Berapa biaya UKT?');

      final state = container.read(chatNotifierProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Batas Kuota Tercapai'));
      expect(lastMsg.text, contains('20 permintaan/hari'));
    });

    // ================= 4. ERROR HANDLING: Fallback ke Data Lokal =================
    test('useOfflineFallback menampilkan jawaban data lokal dan mengaktifkan mode offline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      notifier.useOfflineFallback('beasiswa');

      final state = container.read(chatNotifierProvider);
      expect(state.isOfflineMode, isTrue);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Mode Offline — Data Lokal Kampus'));
      expect(lastMsg.text, contains('Bagian Kemahasiswaan'));
    });

    // ================= 5. MULTIMODAL SERVICE: OCR & SPEECH-TO-TEXT =================
    test('AiService recognizeText mengekstrak teks gambar OCR via multimodal', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('models/gemini-3.8-flash:generateContent'));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'POLITEKNIK NEGERI MALANG\nNIM: 254107023002'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(client: mockClient);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await service.recognizeText(bytes);

      expect(result, contains('POLITEKNIK NEGERI MALANG'));
      expect(result, contains('254107023002'));
    });

    test('AiService speechToText mengonversi audio ke teks transkripsi', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Kapan batas pengisian KRS semester genap?'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(client: mockClient);
      final audioBytes = Uint8List.fromList([10, 20, 30]);
      final text = await service.speechToText(audioBytes);

      expect(text, 'Kapan batas pengisian KRS semester genap?');
    });

    test('CampusLocalKnowledgeBase mengembalikan null jika topik tidak ditemukan', () {
      final result = CampusLocalKnowledgeBase.search('resep masakan rendang padang');
      expect(result, isNull);
    });
  });
}
