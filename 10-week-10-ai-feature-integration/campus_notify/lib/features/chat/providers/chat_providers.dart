import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../ai/ai_service.dart';
import '../../../ai/local_knowledge_base.dart';
import '../models/chat_message.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasApiKey;
  final bool isOfflineMode;
  final int dailyQuotaRemaining;
  final int dailyQuotaTotal;
  final String? lastFailedQuery;
  final bool shouldShowFallbackDialog;
  final bool isRecording;
  final XFile? pendingAttachment;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
    this.hasApiKey = false,
    this.isOfflineMode = false,
    this.dailyQuotaRemaining = 20,
    this.dailyQuotaTotal = 20,
    this.lastFailedQuery,
    this.shouldShowFallbackDialog = false,
    this.isRecording = false,
    this.pendingAttachment,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? hasApiKey,
    bool? isOfflineMode,
    int? dailyQuotaRemaining,
    int? dailyQuotaTotal,
    String? lastFailedQuery,
    bool? shouldShowFallbackDialog,
    bool? isRecording,
    XFile? Function()? pendingAttachment,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      dailyQuotaRemaining: dailyQuotaRemaining ?? this.dailyQuotaRemaining,
      dailyQuotaTotal: dailyQuotaTotal ?? this.dailyQuotaTotal,
      lastFailedQuery: lastFailedQuery ?? this.lastFailedQuery,
      shouldShowFallbackDialog:
          shouldShowFallbackDialog ?? this.shouldShowFallbackDialog,
      isRecording: isRecording ?? this.isRecording,
      pendingAttachment: pendingAttachment != null
          ? pendingAttachment()
          : this.pendingAttachment,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late final AiService _aiService;
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  AudioRecorder? _recorder;
  final Map<String, String> _responseCache = {};

  @override
  ChatState build() {
    _aiService = ref.watch(aiServiceProvider);

    ref.onDispose(() {
      _recorder?.dispose();
    });

    final welcomeMessage = ChatMessage(
      id: 'welcome',
      text:
          'Halo! Saya Asisten AI Kampus terintegrasi. Anda dapat bertanya seputar jadwal kuliah & beasiswa, mengirim foto KTM/dokumen untuk OCR, atau berbicara via mikrofon.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    Future.microtask(() => checkApiKey());

    return ChatState(
      messages: [welcomeMessage],
      hasApiKey: false,
    );
  }

  AudioRecorder get recorder {
    _recorder ??= AudioRecorder();
    return _recorder!;
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

  void toggleOfflineMode() {
    state = state.copyWith(isOfflineMode: !state.isOfflineMode);
  }

  void dismissFallbackDialog() {
    state = state.copyWith(shouldShowFallbackDialog: false);
  }

  void setPendingAttachment(XFile? file) {
    state = state.copyWith(pendingAttachment: () => file);
  }

  // ===================== INTEGRASI MULTIMODAL: KAMERA & OCR =====================

  Future<void> attachAndSendImage(ImageSource source, {bool isOcr = true}) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        await processImageMessage(picked, isOcr: isOcr);
      }
    } catch (e) {
      final errMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Gagal memilih gambar: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errMsg]);
    }
  }

  Future<void> processImageMessage(XFile imageFile, {bool isOcr = true, String? prompt}) async {
    if (state.isLoading) return;

    final userMsgText = isOcr
        ? '📸 Memindai dokumen/KTM (OCR)...'
        : (prompt ?? '🖼️ Menganalisis gambar visual...');

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMsgText,
      isUser: true,
      timestamp: DateTime.now(),
      imagePath: imageFile.path,
    );

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
      final result = isOcr
          ? await _aiService.recognizeText(imageFile)
          : await _aiService.understandImage(imageFile, prompt: prompt);

      _updateBotMessage(
        botMessageId,
        result.isNotEmpty ? result : 'Tidak ada hasil yang terdeteksi.',
        isLoading: false,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError(botMessageId, e, query: userMsgText);
    }
  }

  // ===================== INTEGRASI MULTIMODAL: SUARA KE TEKS =====================

  Future<void> toggleVoiceRecording() async {
    if (state.isRecording) {
      await stopVoiceRecording();
    } else {
      await startVoiceRecording();
    }
  }

  Future<void> startVoiceRecording() async {
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        final permMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '⚠️ Izin mikrofon belum diberikan. Silakan aktifkan izin mikrofon.',
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(messages: [...state.messages, permMsg]);
        return;
      }

      final tempDir = Directory.systemTemp;
      final filePath =
          '${tempDir.path}/chat_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      state = state.copyWith(isRecording: true);
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Gagal merekam suara: $e',
      );
    }
  }

  Future<void> stopVoiceRecording() async {
    try {
      final path = await recorder.stop();
      state = state.copyWith(isRecording: false);

      if (path != null && path.isNotEmpty) {
        final audioFile = File(path);
        final transcribedText = await _aiService.speechToText(audioFile);

        if (transcribedText.isNotEmpty) {
          // Kirimkan teks hasil rekaman langsung ke chat
          await sendMessage(transcribedText);
        }
      }
    } catch (e) {
      state = state.copyWith(isRecording: false);
      final errMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '⚠️ Transkripsi suara gagal: ${e.toString().replaceAll("Exception: ", "")}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errMsg]);
    }
  }

  // ===================== INTEGRASI CHAT, PRIVASI, BIAYA & FALLBACK =====================

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isLoading) return;

    // 1. PRIVASI: Filter guardrail client-side untuk NIK, HP, Email, dan Password
    final nikRegex = RegExp(r'\b\d{16}\b');
    final phoneRegex = RegExp(r'\b(08\d{8,11}|(\+62)\d{9,12})\b');
    final emailRegex =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');
    final passwordRegex =
        RegExp(r'(password|kata sandi|pin atm)', caseSensitive: false);

    if (nikRegex.hasMatch(query) ||
        phoneRegex.hasMatch(query) ||
        emailRegex.hasMatch(query) ||
        passwordRegex.hasMatch(query)) {
      final warningMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '⚠️ Peringatan Keamanan: Pertanyaan Anda terdeteksi memuat data sensitif (NIK, Nomor Telepon, Email, atau Kata Sandi). '
            'Demi privasi pengguna, data pribadi tidak diizinkan untuk dikirim ke AI API.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, warningMsg]);
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 2. MODE OFFLINE: Langsung cari di basis pengetahuan lokal kampus
    if (state.isOfflineMode) {
      final offlineAnswer = CampusLocalKnowledgeBase.search(query) ??
          'Mode Offline Aktif: Informasi untuk pertanyaan tersebut belum tercantum dalam pangkalan data lokal kampus. Silakan beralih ke Mode Online saat jaringan tersedia.';
      final offlineMsg = ChatMessage(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        text: '🏢 [Pangkalan Data Offline Kampus]\n$offlineAnswer',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, userMessage, offlineMsg],
      );
      return;
    }

    // 3. KONTROL BIAYA: Cek cache lokal
    final cacheKey = query.toLowerCase();
    if (_responseCache.containsKey(cacheKey)) {
      final cachedResponse = _responseCache[cacheKey]!;
      final cachedMsg = ChatMessage(
        id: 'cache_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚡ [Dari Cache Lokal — 0 Token Digunakan]\n$cachedResponse',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, userMessage, cachedMsg],
      );
      return;
    }

    // 4. KONTROL BIAYA: Batasi kuota harian (Rate Limiting)
    if (state.dailyQuotaRemaining <= 0) {
      final quotaMsg = ChatMessage(
        id: 'quota_${DateTime.now().millisecondsSinceEpoch}',
        text:
            '⚠️ Batas Kuota Tercapai: Anda telah mencapai batas maksimal 20 permintaan/hari untuk mengontrol biaya operasional AI. '
            'Silakan gunakan Mode Offline untuk mengakses informasi kampus tanpa kuota.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, userMessage, quotaMsg],
      );
      return;
    }

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
      shouldShowFallbackDialog: false,
      lastFailedQuery: query,
    );

    try {
      final responseText = await _aiService.ask(query);

      // Simpan ke Cache Lokal
      _responseCache[cacheKey] = responseText;

      _updateBotMessage(
        botMessageId,
        responseText.isNotEmpty
            ? responseText
            : 'Tidak ada respon yang dihasilkan oleh AI.',
        isLoading: false,
      );

      state = state.copyWith(
        isLoading: false,
        dailyQuotaRemaining: state.dailyQuotaRemaining - 1,
        lastFailedQuery: null,
      );
    } catch (e) {
      _handleError(botMessageId, e, query: query);
    }
  }

  void _handleError(String botMessageId, Object error, {required String query}) {
    final fallbackAnswer = CampusLocalKnowledgeBase.search(query);

    if (fallbackAnswer != null) {
      _updateBotMessage(
        botMessageId,
        '⚠️ Layanan AI tidak merespon (${error.toString().replaceAll("Exception: ", "")}).\n\n'
        '🔄 Fallback Otomatis ke Data Lokal Kampus:\n$fallbackAnswer',
        isLoading: false,
      );
    } else {
      _updateBotMessage(
        botMessageId,
        '⚠️ Layanan AI Sibuk: Tidak dapat memproses permintaan ke AI API. '
        'Silakan coba lagi atau gunakan Mode Offline (data lokal kampus).',
        isLoading: false,
      );
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Layanan AI Sibuk',
      shouldShowFallbackDialog: true,
    );
  }

  void retryLastMessage() {
    final query = state.lastFailedQuery;
    if (query != null && query.isNotEmpty) {
      dismissFallbackDialog();
      sendMessage(query);
    }
  }

  void useOfflineFallback([String? customQuery]) {
    dismissFallbackDialog();
    final query = customQuery ?? state.lastFailedQuery ?? '';
    final answer = CampusLocalKnowledgeBase.search(query) ??
        'Berikut topik bantuan kampus offline yang tersedia:\n• Alur Pengisian KRS\n• Informasi Beasiswa\n• Pembayaran UKT\n• Layanan Perpustakaan';

    final offlineMessage = ChatMessage(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      text: '🏢 [Mode Offline — Data Lokal Kampus]:\n$answer',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isOfflineMode: true,
      messages: [...state.messages, offlineMessage],
    );
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
          'Halo! Saya Asisten AI Kampus terintegrasi. Anda dapat bertanya seputar jadwal kuliah & beasiswa, mengirim foto KTM/dokumen untuk OCR, atau berbicara via mikrofon.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [welcomeMessage],
      lastFailedQuery: null,
      shouldShowFallbackDialog: false,
    );
  }
}

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
