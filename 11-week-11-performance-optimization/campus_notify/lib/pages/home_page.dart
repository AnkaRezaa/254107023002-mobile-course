import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _onLogout(WidgetRef ref) {
    ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify - Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _onLogout(ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          RepaintBoundary(child: AuthStatusCard()),
          SizedBox(height: 16),
          RepaintBoundary(child: FcmTokenCard()),
          SizedBox(height: 16),
          RepaintBoundary(child: AnnouncementNavCard()),
          SizedBox(height: 12),
          RepaintBoundary(child: AiAssistantNavCard()),
        ],
      ),
    );
  }
}

class AuthStatusCard extends StatelessWidget {
  const AuthStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Status Autentikasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Login Berhasil! Token tersimpan aman di FlutterSecureStorage.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class FcmTokenCard extends ConsumerWidget {
  const FcmTokenCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isolasi scoped rebuild: hanya rebuild widget ini saat nilai fcmToken berubah
    final fcmToken = ref.watch(fcmTokenProvider.select((token) => token));

    final maskedToken = (fcmToken != null && fcmToken.length > 12)
        ? '${fcmToken.substring(0, 12)}...'
        : (fcmToken ?? 'Mengambil token...');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Halaman Debug: FCM Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Token Perangkat (Sensor untuk Screenshot Laporan):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      maskedToken,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (fcmToken != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Salin Token Lengkap',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fcmToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token disalin ke clipboard!',
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementNavCard extends StatelessWidget {
  const AnnouncementNavCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF3E8FF),
          child: Icon(Icons.campaign, color: Colors.deepPurple),
        ),
        title: const Text(
          'Pengumuman Terkini',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Lihat detail pengumuman kampus #101'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push('/announcements'),
      ),
    );
  }
}

class AiAssistantNavCard extends StatelessWidget {
  const AiAssistantNavCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE9FE),
          child: Icon(Icons.smart_toy_rounded, color: Colors.deepPurple),
        ),
        title: const Text(
          'Tanya Asisten AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Chat cerdas seputar jadwal & info kampus'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push('/chat'),
      ),
    );
  }
}
