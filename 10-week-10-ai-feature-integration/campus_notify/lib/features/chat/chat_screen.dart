import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final currentKey = await storage.read(key: 'ai_api_key') ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Pengaturan API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci ini disimpan secara terenkripsi di local storage (flutter_secure_storage) dan tidak pernah di-hardcode.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ref.read(chatNotifierProvider.notifier).removeApiKey();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil dihapus.')),
                  );
                }
              },
              child: const Text('Hapus Key', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await ref.read(chatNotifierProvider.notifier).saveApiKey(newKey);
                if (ctx.mounted) Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.messages;

    ref.listen(chatNotifierProvider, (_, next) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanya Asisten Kampus', style: TextStyle(fontSize: 18)),
            Text(
              'Didukung AI Gemini • Streaming Response',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
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
              color: chatState.hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
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

          // Pesan perlindungan privasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.grey.shade50,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Privasi Terjaga: Sistem memproteksi NIK & nomor kontak.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
          if (chatState.isLoading && messages.isNotEmpty && !messages.last.isLoading)
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
                  Text('Menghubungkan ke AI API...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Area Input Teks
          _buildInputArea(chatState.isLoading),
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
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.deepPurple),
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
              child: isBotLoading
                  ? const Row(
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
                          style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
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
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Tanyakan informasi kampus...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            const SizedBox(width: 8),
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

