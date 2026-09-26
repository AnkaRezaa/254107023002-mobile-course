import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  PostRepository({
    Future<Database> Function()? openDb,
    Dio? dio,
  })  : _openDb = openDb ?? openNotesDb,
        _dio = dio ?? Dio();

  final Future<Database> Function() _openDb;
  final Dio _dio;

  // Baca data dari tabel cached_posts
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts');
    
    return rows.map((row) {
      final jsonMap = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(jsonMap);
    }).toList();
  }

  // Ambil data terbaru dari API dan simpan ke database lokal
  Future<void> refreshPostsInBackground({bool forceOffline = false}) async {
    if (forceOffline) {
      throw Exception('Aplikasi dalam mode Force Offline');
    }

    final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');
    if (response.statusCode == 200) {
      final List rawList = response.data as List;
      final posts = rawList.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();

      final db = await _openDb();
      final batch = db.batch();

      // Bersihkan cache lama dan masukkan data baru
      batch.delete('cached_posts');
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    }
  }

  // Menggabungkan alur Cache-First Read
  Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts(); // dari tabel cached_posts
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
  refreshPostsInBackground();
  return cached;
}
}