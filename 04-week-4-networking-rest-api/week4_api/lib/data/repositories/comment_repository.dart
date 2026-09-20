import 'package:dio/dio.dart';
import '../models/comment.dart';

// Repository memisahkan akses HTTP dari provider dan UI.
class CommentRepository {
  // Dio disuntikkan agar repository mudah digunakan ulang dan dites.
  CommentRepository(this._dio);

  final Dio _dio;

  // Mengambil semua komentar untuk satu post dengan timeout 10 detik.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Respons null atau item dengan bentuk tidak sesuai diabaikan secara aman.
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
