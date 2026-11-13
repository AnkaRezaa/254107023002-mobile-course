import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Detail Pengumuman ID: $id',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Halo Mahasiswa! Jadwal kuliah dan pengumuman akademik terbaru telah diperbarui. Pastikan selalu memantau notifikasi kampus.',
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
