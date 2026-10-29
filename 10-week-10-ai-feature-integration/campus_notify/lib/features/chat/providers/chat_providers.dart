import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../ai/ai_service.dart';
import '../models/chat_message.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasApiKey;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
    this.hasApiKey = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? hasApiKey,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late final AiService _aiService;
  final _storage = const FlutterSecureStorage();

  @override
  ChatState build() {
    _aiService = ref.watch(aiServiceProvider);

    final welcomeMessage = ChatMessage(
      id: 'welcome',
      text:
          'Halo! Saya Asisten AI Kampus. Silakan tanyakan seputar jadwal kuliah, beasiswa, pengumuman akademik, atau informasi kampus lainnya.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    Future.microtask(() => checkApiKey());

    return ChatState(
      messages: [welcomeMessage],
      hasApiKey: false,
    );
  }

  Future<void> checkApiKey() async {
    final key = await _storage.read(key: 'ai_api_key');
    state = state.copyWith(hasApiKey: key != null && key.isNotEmpty);
  }

  Future<void> saveApiKey(String key) async {
    await _aiService.saveApiKey(key);
    await checkApiKey();
  }

  Future<void> removeApiKey() async {
    await _storage.delete(key: 'ai_api_key');
    await checkApiKey();
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isLoading) return;

    // Filter Privasi & Guardrails: Jangan kirim NIK atau Nomor HP pengguna ke Cloud AI
    final nikRegex = RegExp(r'\b\d{16}\b');
    final phoneRegex = RegExp(r'\b(08\d{8,11}|(\+62)\d{9,12})\b');

    if (nikRegex.hasMatch(query) || phoneRegex.hasMatch(query)) {
      final warningMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '⚠️ Peringatan Keamanan: Pertanyaan Anda terdeteksi memuat data sensitif (NIK atau Nomor Telepon). Demi privasi, data pribadi tidak diizinkan untuk dikirim ke AI API.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, warningMsg]);
      return;
    }

    // 1. Tambahkan pesan user ke daftar
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 2. Siapkan placeholder pesan bot dengan loading = true
    final botMessageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final initialBotMessage = ChatMessage(
      id: botMessageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, initialBotMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final responseText = await _aiService.ask(query);
      _updateBotMessage(
        botMessageId,
        responseText.isNotEmpty ? responseText : 'Tidak ada respon yang dihasilkan.',
        isLoading: false,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      final errorText = 'Terjadi kesalahan: ${e.toString().replaceAll("Exception: ", "")}';
      _updateBotMessage(botMessageId, errorText, isLoading: false);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorText,
      );
    }
  }

  void _updateBotMessage(String id, String text, {required bool isLoading}) {
    final updatedList = state.messages.map((msg) {
      if (msg.id == id) {
        return msg.copyWith(
          text: text,
          isLoading: isLoading,
        );
      }
      return msg;
    }).toList();

    state = state.copyWith(messages: updatedList);
  }

  void clearChat() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      text:
          'Halo! Saya Asisten AI Kampus. Silakan tanyakan seputar jadwal kuliah, beasiswa, pengumuman akademik, atau informasi kampus lainnya.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }
}

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
