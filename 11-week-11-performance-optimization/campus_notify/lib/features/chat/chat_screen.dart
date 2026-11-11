import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'models/chat_message.dart';
import 'providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _inputController.clear();
  }

  void _showApiKeyDialog(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final currentKey = await storage.read(key: 'ai_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Konfigurasi API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google AI Studio API Key Anda untuk mengaktifkan AI Gemini:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ref.read(chatNotifierProvider.notifier).removeApiKey();
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil dihapus.')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus Key'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await ref.read(chatNotifierProvider.notifier).saveApiKey(key);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil disimpan!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showFallbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Layanan AI Sibuk'),
        content: const Text('Coba lagi nanti atau gunakan mode offline.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatNotifierProvider.notifier).retryLastMessage();
            },
            child: const Text('Coba Lagi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatNotifierProvider.notifier).useOfflineFallback();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gunakan Mode Offline'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.auto_awesome, color: Colors.deepPurple),
                title: Text(
                  'Lampiran Multimodal AI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Pindai teks (OCR) atau pemahaman visual gambar'),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.document_scanner, color: Colors.white, size: 20),
                ),
                title: const Text('Pindai Dokumen / KTM (OCR) dari Kamera'),
                subtitle: const Text('Ekstrak teks KTM, kuitansi, atau pengumuman'),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .attachAndSendImage(ImageSource.camera, isOcr: true);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.photo_library, color: Colors.white, size: 20),
                ),
                title: const Text('Pilih Foto dari Galeri (OCR)'),
                subtitle: const Text('Ekstrak teks dari foto galeri yang sudah ada'),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .attachAndSendImage(ImageSource.gallery, isOcr: true);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.image_search, color: Colors.white, size: 20),
                ),
                title: const Text('Analisis Makna Gambar (Image Understanding)'),
                subtitle: const Text('Minta AI mendeskripsikan isi gambar & objek'),
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  ref
                      .read(chatNotifierProvider.notifier)
                      .attachAndSendImage(ImageSource.gallery, isOcr: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.messages;

    ref.listen(chatNotifierProvider, (previous, next) {
      _scrollToBottom();
      if (next.shouldShowFallbackDialog &&
          !(previous?.shouldShowFallbackDialog ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showFallbackDialog(context);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanya Asisten Kampus', style: TextStyle(fontSize: 18)),
            Text(
              chatState.isOfflineMode
                  ? 'Mode Offline Aktif (Data Lokal Kampus)'
                  : 'Didukung AI Gemini • Kuota: ${chatState.dailyQuotaRemaining}/${chatState.dailyQuotaTotal}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: chatState.isOfflineMode
                ? 'Beralih ke Mode Online'
                : 'Beralih ke Mode Offline (Hemat Biaya)',
            icon: Icon(
              chatState.isOfflineMode ? Icons.cloud_off : Icons.cloud_queue,
              color: chatState.isOfflineMode ? Colors.amberAccent : Colors.white,
            ),
            onPressed: () =>
                ref.read(chatNotifierProvider.notifier).toggleOfflineMode(),
          ),
          IconButton(
            tooltip: 'Hapus Riwayat Chat',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).clearChat();
            },
          ),
          IconButton(
            tooltip: 'Atur API Key',
            icon: Icon(
              Icons.vpn_key_rounded,
              color:
                  chatState.hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
            ),
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner peringatan bila API Key belum diatur
          if (!chatState.hasApiKey)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'API Key belum disetel. Klik tombol kunci di atas untuk menghubungkan AI.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showApiKeyDialog(context),
                    child: const Text('Atur Key'),
                  ),
                ],
              ),
            ),

          // Banner Status Mode Offline / Kuota & Privasi
          if (chatState.isOfflineMode)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mode Offline Aktif — Menjawab otomatis dari data lokal kampus tanpa kuota & bebas biaya.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(chatNotifierProvider.notifier).toggleOfflineMode(),
                    child: const Text('Mode Online'),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Privasi Terjaga: Sistem memproteksi NIK, HP, Email & Sandi.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sisa Kuota: ${chatState.dailyQuotaRemaining}/${chatState.dailyQuotaTotal}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: chatState.dailyQuotaRemaining > 5
                          ? Colors.deepPurple
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Pesan Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Indikator Loading Tambahan
          if (chatState.isLoading &&
              messages.isNotEmpty &&
              !messages.last.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Menghubungkan ke AI API...',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Area Input Teks Terintegrasi (Kamera OCR, Mic STT, Text Input)
          _buildInputArea(chatState),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isBotLoading = !isUser && message.isLoading && message.text.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.smart_toy_rounded,
                  size: 18, color: Colors.deepPurple),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Pratinjau Gambar jika pesan memiliki lampiran gambar
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: kIsWeb
                            ? Image.network(message.imagePath!, fit: BoxFit.cover)
                            : Image.file(File(message.imagePath!), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (isBotLoading)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mengetik...',
                          style: TextStyle(
                              color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  else
                    SelectableText(
                      message.text +
                          (!isUser && message.isLoading ? ' ▌' : ''),
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.black38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple.shade700,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    final isLoading = chatState.isLoading;
    final isRecording = chatState.isRecording;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Tombol Kamera / Lampiran Terintegrasi (OCR & Image Understanding)
            IconButton(
              tooltip: 'Pindai Gambar / Dokumen (OCR)',
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.deepPurple),
              onPressed: isLoading ? null : () => _showAttachmentOptions(context),
            ),

            // Kolom Input Teks Utama
            Expanded(
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: isRecording
                      ? 'Sedang mendengarkan suara...'
                      : 'Tanyakan informasi kampus...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 4),

            // Tombol Mikrofon Terintegrasi (Speech-to-Text)
            IconButton(
              tooltip: isRecording ? 'Hentikan & Transkrip' : 'Bicara (Speech to Text)',
              icon: Icon(
                isRecording ? Icons.stop_circle : Icons.mic_rounded,
                color: isRecording ? Colors.red : Colors.deepPurple,
                size: 26,
              ),
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(chatNotifierProvider.notifier)
                      .toggleVoiceRecording(),
            ),

            // Tombol Kirim Teks
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
