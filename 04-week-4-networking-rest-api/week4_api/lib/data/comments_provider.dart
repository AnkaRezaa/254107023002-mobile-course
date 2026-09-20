import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

// Provider Dio memakai konfigurasi base URL dan interceptor yang sudah ada.
final commentsDioProvider = Provider<Dio>((ref) => createDio());

// Provider repository menyediakan satu instance CommentRepository untuk Riverpod.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(commentsDioProvider)),
);

// AsyncNotifier mengubah exception repository menjadi AsyncError otomatis.
// postId diterima melalui constructor family saat provider dibuat.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }
}

// Family membuat state komentar terpisah untuk setiap postId.
final commentsProvider = AsyncNotifierProvider.family<
    CommentsNotifier, List<Comment>, int>(
  CommentsNotifier.new,
  // Retry otomatis dimatikan agar AsyncError langsung dapat ditampilkan.
  retry: (retryCount, error) => null,
);

// Mengubah DioException menjadi pesan yang dapat dipahami pengguna.
String friendlyCommentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Komentar tidak ditemukan (404).';
        }
        if (statusCode == 500) {
          return 'Server sedang bermasalah (500). Coba lagi nanti.';
        }
        return 'Server mengembalikan error ($statusCode).';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
