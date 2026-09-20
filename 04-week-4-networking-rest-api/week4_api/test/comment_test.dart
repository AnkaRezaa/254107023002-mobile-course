import 'package:flutter_test/flutter_test.dart';
import 'package:praktikum/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai nilai default saat field hilang', () {
    // JSON kosong mensimulasikan respons dengan field yang tidak lengkap.
    final comment = Comment.fromJson({});

    // Field angka menjadi 0 dan field teks menjadi string kosong.
    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
