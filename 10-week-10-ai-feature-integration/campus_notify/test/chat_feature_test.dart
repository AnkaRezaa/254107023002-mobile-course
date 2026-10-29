import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/features/chat/models/chat_message.dart';
import 'package:campus_notify/features/chat/providers/chat_providers.dart';

void main() {
  group('Chat Feature Unit Tests', () {
    test('ChatMessage model menginisialisasi properti dengan benar', () {
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Kapan jadwal ujian semester?',
        isUser: true,
        timestamp: DateTime(2026, 10, 29, 10, 0),
        isLoading: false,
      );

      expect(msg.id, 'msg_1');
      expect(msg.text, 'Kapan jadwal ujian semester?');
      expect(msg.isUser, isTrue);
      expect(msg.isLoading, isFalse);

      final updated = msg.copyWith(isLoading: true, text: 'Pertanyaan diubah');
      expect(updated.isLoading, isTrue);
      expect(updated.text, 'Pertanyaan diubah');
      expect(updated.id, 'msg_1');
    });

    test('ChatNotifier memiliki pesan sambutan awal saat pertama dibuka', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chatNotifierProvider);
      expect(state.messages, isNotEmpty);
      expect(state.messages.first.id, 'welcome');
      expect(state.messages.first.isUser, isFalse);
      expect(state.messages.first.text, contains('Asisten AI Kampus'));
    });

    test('Filter privasi mendeteksi dan menolak pengiriman NIK ke AI API', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);

      // Input pesan yang memuat 16 digit NIK
      const sensitiveText = 'Tolong cek data mahasiswa dengan NIK 3507112233440001';
      await notifier.sendMessage(sensitiveText);

      final state = container.read(chatNotifierProvider);
      // Harus ada pesan peringatan keamanan privasi
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Peringatan Keamanan'));
      expect(lastMsg.text, contains('NIK atau Nomor Telepon'));
      expect(lastMsg.isUser, isFalse);
    });

    test('Filter privasi mendeteksi dan menolak pengiriman nomor telepon ke AI API', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);

      // Input pesan yang memuat nomor telepon format 08xx
      const sensitivePhone = 'Hubungi saya di 081234567890 untuk info beasiswa';
      await notifier.sendMessage(sensitivePhone);

      final state = container.read(chatNotifierProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.text, contains('Peringatan Keamanan'));
      expect(lastMsg.isUser, isFalse);
    });
  });
}

